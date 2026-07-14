codeunit 50103 "RBT Recalc Engine"
{
    // Retroactive Recalculation Engine for Vendor Rebates.
    //
    // Public API:
    //   RecalcPeriod(AgreementNo, PeriodStart, PeriodEnd, PostingDate, var ResultingCalcRequest): Integer
    //     Re-evaluates every 'Original' RBT Calculation Ledger Entry for the Agreement
    //     within the given period using the CURRENT agreement version's Rule terms,
    //     computes DeltaAmount = NewAmount - OldAmount, and inserts a new immutable
    //     'Adjustment' ledger entry linked to the original via Corrects Entry No.
    //     If at least one delta is inserted, auto-creates an RBT Calc Request scoped
    //     to the delta batch and returns it via the var parameter. The caller is
    //     responsible for feeding the returned Calc Request into the existing
    //     RBT Posting Engine (single G/L posting path) so only the net delta posts.
    //     Return value is the count of delta entries inserted.
    //
    // Idempotency:
    //   Before inserting an adjustment, the engine checks the CorrectsIdx secondary
    //   key on RBT Calculation Ledger Entry filtered by (Corrects Entry No.,
    //   Agreement Version No.). If a matching adjustment already exists under the
    //   current version, the engine skips - so a re-run under the same current
    //   version produces zero additional entries.
    //
    // Immutability:
    //   The engine only inserts new rows via the existing SetAllowInternalEdit
    //   escape hatch. Pre-existing rows are never modified or deleted.

    var
        AgreementNotFoundErr: Label 'Rebate Agreement %1 does not exist. Create the agreement on the RBT Rebate Agreement Card first.', Comment = '%1 = Agreement No.';
        AgreementNotActiveErr: Label 'Rebate Agreement %1 must be Active to run retroactive recalculation. Activate the agreement first on the RBT Rebate Agreement Card.', Comment = '%1 = Agreement No.';
        NoCurrentVersionErr: Label 'Rebate Agreement %1 has no current version. Activate the agreement to create the first version before running retroactive recalculation.', Comment = '%1 = Agreement No.';
        NothingToRecalcErr: Label 'Retroactive recalculation for Rebate Agreement %1 over %2..%3 produced no non-zero deltas. Either no source-line amounts changed under the current agreement terms, or all deltas have already been booked in an earlier recalculation.', Comment = '%1 = Agreement No., %2 = Period Start, %3 = Period End.';
        MissingPostingGroupErr: Label 'Rebate Agreement %1 has no Posting Group. Set the Posting Group on the RBT Rebate Agreement Card before running a retroactive recalculation.', Comment = '%1 = Agreement No.';

    /// <summary>
    /// Retroactive recalculation entry point. Produces immutable Adjustment ledger entries
    /// for the given Agreement + Period whose Calculated Amount = New - Old under the
    /// agreement's current version terms. Auto-creates a scoped Calc Request the caller
    /// can hand to the Posting Engine so the net delta posts as a balanced 2-line journal.
    /// </summary>
    /// <param name="AgreementNo">Primary key of the RBT Rebate Agreement to recalculate.</param>
    /// <param name="PeriodStart">Start of the historical period to re-evaluate.</param>
    /// <param name="PeriodEnd">End of the historical period to re-evaluate.</param>
    /// <param name="PostingDate">Posting date to stamp on the resulting Calc Request.</param>
    /// <param name="ResultingCalcRequest">On return, the new Calc Request scoped to the delta batch.</param>
    /// <returns>Number of Adjustment ledger entries inserted.</returns>
    procedure RecalcPeriod(AgreementNo: Code[20]; PeriodStart: Date; PeriodEnd: Date; PostingDate: Date; var ResultingCalcRequest: Record "RBT Calc Request"): Integer
    var
        Agreement: Record "RBT Rebate Agreement";
        CurrentVersion: Record "RBT Rebate Version";
        PostingSetup: Record "RBT Posting Setup";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        OldEntry: Record "RBT Calculation Ledger Entry";
        Rule: Record "RBT Rebate Rule";
        DeltaCount: Integer;
        NewAmount: Decimal;
        DeltaAmount: Decimal;
    begin
        // (1) Validate Agreement exists and is Active.
        if not Agreement.Get(AgreementNo) then
            Error(AgreementNotFoundErr, AgreementNo);
        if Agreement.Status <> Agreement.Status::Active then
            Error(AgreementNotActiveErr, AgreementNo);

        // (2) Resolve current version - required to stamp new adjustments and to key idempotency.
        if not VersionMgt.GetCurrentVersion(AgreementNo, CurrentVersion) then
            Error(NoCurrentVersionErr, AgreementNo);

        // (3) Resolve Posting Setup with fallback + verify the mapped G/L accounts. This runs
        //     early so a misconfigured agreement fails with a clear error BEFORE any delta
        //     entries are inserted. The Posting Engine will re-check at post time.
        if Agreement."Posting Group" = '' then
            Error(MissingPostingGroupErr, AgreementNo);
        PostingSetup.GetPostingSetup(Agreement."Posting Group", Agreement."Currency Code");
        PostingSetup.TestAccounts();

        // (4) Iterate the historical 'Original' ledger entries in scope.
        OldEntry.Reset();
        OldEntry.SetRange("Agreement No.", AgreementNo);
        OldEntry.SetRange("Posting Date", PeriodStart, PeriodEnd);
        OldEntry.SetRange("Entry Type", OldEntry."Entry Type"::Original);

        DeltaCount := 0;
        if OldEntry.FindSet() then
            repeat
                if FindCurrentRuleForEntry(AgreementNo, OldEntry, Rule) then begin
                    NewAmount := ComputeCalculatedAmount(Rule, OldEntry."Base Amount");
                    DeltaAmount := NewAmount - OldEntry."Calculated Amount";
                    if DeltaAmount <> 0 then
                        if not AdjustmentAlreadyExists(OldEntry."Entry No.", CurrentVersion."Version No.") then begin
                            InsertAdjustmentEntry(OldEntry, Agreement, CurrentVersion, Rule, NewAmount, DeltaAmount);
                            DeltaCount += 1;
                        end;
                end;
            until OldEntry.Next() = 0;

        // (5) If nothing to book, error clearly so the caller does not proceed to post an empty batch.
        if DeltaCount = 0 then
            Error(NothingToRecalcErr, AgreementNo, PeriodStart, PeriodEnd);

        // (6) Auto-create a Calc Request scoped to the delta batch. OnInsert auto-assigns No.
        //     from the 'Calculation Request Nos.' series in RBT Rebate Setup.
        ResultingCalcRequest.Init();
        ResultingCalcRequest."No." := '';
        ResultingCalcRequest.Insert(true);
        ResultingCalcRequest.Description := CopyStr(StrSubstNo('Retroactive recalc %1..%2', PeriodStart, PeriodEnd), 1, MaxStrLen(ResultingCalcRequest.Description));
        ResultingCalcRequest.Validate("Agreement No.", AgreementNo);
        ResultingCalcRequest."Period Start" := PeriodStart;
        ResultingCalcRequest."Period End" := PeriodEnd;
        if PostingDate <> 0D then
            ResultingCalcRequest."Posting Date" := PostingDate
        else
            ResultingCalcRequest."Posting Date" := WorkDate();
        ResultingCalcRequest."Currency Code" := Agreement."Currency Code";
        ResultingCalcRequest.Modify();

        exit(DeltaCount);
    end;

    local procedure FindCurrentRuleForEntry(AgreementNo: Code[20]; var OldEntry: Record "RBT Calculation Ledger Entry"; var MatchedRule: Record "RBT Rebate Rule"): Boolean
    var
        Rule: Record "RBT Rebate Rule";
    begin
        // Prefer the exact rule line that produced the original entry - by (Agreement No., Line No.).
        // If it still exists on the current version, use it. Otherwise, fall back to any current-version
        // rule whose filter coordinates cover this entry (Item No. / Item Category / Location Code).
        if Rule.Get(AgreementNo, OldEntry."Rule Line No.") then begin
            MatchedRule := Rule;
            exit(true);
        end;

        Rule.Reset();
        Rule.SetCurrentKey("Agreement No.", "Line No.");
        Rule.SetRange("Agreement No.", AgreementNo);
        if Rule.FindSet() then
            repeat
                if RuleMatchesEntry(Rule, OldEntry) then begin
                    MatchedRule := Rule;
                    exit(true);
                end;
            until Rule.Next() = 0;

        exit(false);
    end;

    local procedure RuleMatchesEntry(var Rule: Record "RBT Rebate Rule"; var OldEntry: Record "RBT Calculation Ledger Entry"): Boolean
    begin
        // Only Percentage and Fixed are supported here - mirrors Rule Engine scope.
        if not (Rule."Calculation Method" in [Rule."Calculation Method"::Percentage, Rule."Calculation Method"::Fixed]) then
            exit(false);
        if (Rule."Item No." <> '') and (Rule."Item No." <> OldEntry."Item No.") then
            exit(false);
        if (Rule."Item Category" <> '') and (Rule."Item Category" <> OldEntry."Item Category") then
            exit(false);
        if (Rule."Location Code" <> '') and (Rule."Location Code" <> OldEntry."Location Code") then
            exit(false);
        exit(true);
    end;

    local procedure ComputeCalculatedAmount(var Rule: Record "RBT Rebate Rule"; BaseAmount: Decimal): Decimal
    begin
        // Formula must match RBTRuleEngine.ComputeCalculatedAmount exactly.
        case Rule."Calculation Method" of
            Rule."Calculation Method"::Percentage:
                exit(BaseAmount * Rule.Percentage / 100);
            Rule."Calculation Method"::Fixed:
                exit(Rule."Fixed Amount");
        end;
        exit(0);
    end;

    local procedure AdjustmentAlreadyExists(OriginalEntryNo: Integer; CurrentVersionNo: Integer): Boolean
    var
        Existing: Record "RBT Calculation Ledger Entry";
    begin
        // Index-backed idempotency lookup - keyed on the new CorrectsIdx secondary key.
        Existing.SetCurrentKey("Corrects Entry No.", "Agreement Version No.");
        Existing.SetRange("Corrects Entry No.", OriginalEntryNo);
        Existing.SetRange("Agreement Version No.", CurrentVersionNo);
        exit(not Existing.IsEmpty());
    end;

    local procedure InsertAdjustmentEntry(var OldEntry: Record "RBT Calculation Ledger Entry"; var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule"; NewAmount: Decimal; DeltaAmount: Decimal)
    var
        NewEntry: Record "RBT Calculation Ledger Entry";
    begin
        // NewAmount is passed for documentation and future extension (e.g. carrying the
        // absolute new amount in an additional column). We currently store only the delta,
        // so a database CalcSums over the period naturally yields the corrected net total.
        if NewAmount = 0 then; // suppress unused-warning without altering behaviour

        NewEntry.Init();
        // Copy source-line coordinates verbatim from the original so the audit trail links back cleanly.
        NewEntry."Source Type" := OldEntry."Source Type";
        NewEntry."Source Document No." := OldEntry."Source Document No.";
        NewEntry."Source Document Line No." := OldEntry."Source Document Line No.";
        NewEntry."Posting Date" := OldEntry."Posting Date";
        NewEntry."Agreement No." := Agreement."No.";
        NewEntry."Agreement Version No." := CurrentVersion."Version No.";
        NewEntry."Rule Line No." := Rule."Line No.";
        NewEntry."Item No." := OldEntry."Item No.";
        NewEntry."Item Category" := OldEntry."Item Category";
        NewEntry."Location Code" := OldEntry."Location Code";
        NewEntry."Calculation Method" := Rule."Calculation Method";
        NewEntry."Base Amount" := OldEntry."Base Amount";
        NewEntry.Percentage := Rule.Percentage;
        NewEntry."Fixed Amount" := Rule."Fixed Amount";
        // Store the DELTA so that CalcSums("Calculated Amount") on the period naturally
        // yields (sum of originals) + (sum of deltas) = sum of current-version amounts,
        // and posting the delta batch produces a net-only balanced 2-line journal.
        NewEntry."Calculated Amount" := DeltaAmount;
        NewEntry."Currency Code" := Agreement."Currency Code";
        NewEntry."Entry Type" := NewEntry."Entry Type"::Adjustment;
        NewEntry."Corrects Entry No." := OldEntry."Entry No.";
        NewEntry.SetAllowInternalEdit(true);
        NewEntry.Insert(true);
        NewEntry.SetAllowInternalEdit(false);
    end;
}
