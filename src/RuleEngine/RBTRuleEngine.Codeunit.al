codeunit 50100 "RBT Rule Engine"
{
    // Core Rebate Rule Evaluation Engine.
    //
    // Public API:
    //   RunAll()                          - iterates all Active agreements.
    //   Run(AgreementNo: Code[20])        - processes a single agreement.
    //
    // Note: The parameterless entry point is named RunAll() (not Run()) because a
    // codeunit inherits a built-in Run() method from its OnRun trigger, and defining
    // a custom parameterless Run() collides with that built-in signature in BC 27.
    //
    // For each Active agreement the engine:
    //   1. Resolves the current version via "RBT Rebate Version Mgt.".GetCurrentVersion.
    //   2. Iterates each RBT Rebate Rule child line.
    //   3. Branches on Agreement.Type to select the source-line table
    //      (Vendor Rebate -> Purchase Invoice Line, Customer Incentive -> Sales Invoice Line).
    //   4. Applies the agreement's date window and any rule-level filters
    //      (Item No., Item Category, Location Code) ONLY when the rule field is non-blank.
    //      IMPORTANT: The engine never unconditionally forces SetRange(Type, ...::Item)
    //      on the source-line query - this is a documented BC Vendor Rebate rule.
    //   5. Computes Base Amount from the source line and calculates the rebate:
    //        Percentage -> Base * Percentage / 100
    //        Fixed      -> Fixed Amount
    //      Tiered / Slab / Growth methods are intentionally out of scope in this task
    //      and are skipped without producing a ledger row. Future tasks will extend
    //      the engine to cover them.
    //   6. Performs an idempotency check on RBT Calculation Ledger Entry using
    //      (Agreement No., Agreement Version No., Source Type, Source Document No., Source Document Line No.)
    //      and skips insert if a matching entry already exists.

    var
        NoCurrentVersionErr: Label 'Rebate Agreement %1 is Active but has no current version. Re-activate the agreement from the Rebate Agreement Card to create Version 1.', Comment = '%1 = Agreement No.';
        AgreementNotFoundErr: Label 'Rebate Agreement %1 does not exist. Create the agreement on the RBT Rebate Agreement Card first.', Comment = '%1 = Agreement No.';

    /// <summary>
    /// Evaluates every Active rebate agreement and emits Calculation Ledger Entries for each matched source line.
    /// Idempotent: a subsequent run against the same agreements/source data produces no additional entries.
    /// </summary>
    procedure RunAll()
    var
        Agreement: Record "RBT Rebate Agreement";
    begin
        Agreement.SetRange(Status, Agreement.Status::Active);
        if Agreement.FindSet() then
            repeat
                ProcessAgreement(Agreement);
            until Agreement.Next() = 0;
    end;

    /// <summary>
    /// Evaluates a single rebate agreement by primary key. The agreement must be Active for entries to be produced.
    /// </summary>
    /// <param name="AgreementNo">Primary key of the RBT Rebate Agreement.</param>
    procedure Run(AgreementNo: Code[20])
    var
        Agreement: Record "RBT Rebate Agreement";
    begin
        if not Agreement.Get(AgreementNo) then
            Error(AgreementNotFoundErr, AgreementNo);
        if Agreement.Status <> Agreement.Status::Active then
            exit;
        ProcessAgreement(Agreement);
    end;

    local procedure ProcessAgreement(var Agreement: Record "RBT Rebate Agreement")
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        CurrentVersion: Record "RBT Rebate Version";
        Rule: Record "RBT Rebate Rule";
    begin
        if not VersionMgt.GetCurrentVersion(Agreement."No.", CurrentVersion) then
            Error(NoCurrentVersionErr, Agreement."No.");

        Rule.SetRange("Agreement No.", Agreement."No.");
        if Rule.FindSet() then
            repeat
                ProcessRule(Agreement, CurrentVersion, Rule);
            until Rule.Next() = 0;
    end;

    local procedure ProcessRule(var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule")
    begin
        // Only Percentage and Fixed are supported in this initial engine.
        // Tiered / Slab / Growth are intentionally skipped here - they will be handled by future tasks.
        if not (Rule."Calculation Method" in [Rule."Calculation Method"::Percentage, Rule."Calculation Method"::Fixed]) then
            exit;

        case Agreement."Type" of
            Agreement."Type"::"Vendor Rebate":
                ProcessVendorRebateRule(Agreement, CurrentVersion, Rule);
            Agreement."Type"::"Customer Incentive":
                ProcessCustomerIncentiveRule(Agreement, CurrentVersion, Rule);
        end;
    end;

    local procedure ProcessVendorRebateRule(var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
    begin
        PurchInvLine.Reset();
        // Date window always applies.
        PurchInvLine.SetRange("Posting Date", Agreement."Start Date", Agreement."End Date");

        // Rule-level filters are applied ONLY when the rule field is non-blank.
        // The engine deliberately does NOT force SetRange(Type, ...::Item) when both
        // Item No. and Item Category are blank - G/L Account and Charge (Item) lines
        // must remain in scope in that case (BC Vendor Rebate Calculation Engine rule).
        if Rule."Item No." <> '' then begin
            PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
            PurchInvLine.SetRange("No.", Rule."Item No.");
        end else
            if Rule."Item Category" <> '' then begin
                PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
                ApplyItemCategoryFilter(PurchInvLine.FieldNo("No."), Rule."Item Category", PurchInvLine);
            end;

        if Rule."Location Code" <> '' then
            PurchInvLine.SetRange("Location Code", Rule."Location Code");

        if PurchInvLine.FindSet() then
            repeat
                if not EntryAlreadyExists(Agreement."No.", CurrentVersion."Version No.",
                    LedgerEntry."Source Type"::"Purchase Invoice",
                    PurchInvLine."Document No.", PurchInvLine."Line No.")
                then
                    InsertLedgerEntryFromPurchLine(Agreement, CurrentVersion, Rule, PurchInvLine);
            until PurchInvLine.Next() = 0;
    end;

    local procedure ProcessCustomerIncentiveRule(var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule")
    var
        SalesInvLine: Record "Sales Invoice Line";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Posting Date", Agreement."Start Date", Agreement."End Date");

        if Rule."Item No." <> '' then begin
            SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
            SalesInvLine.SetRange("No.", Rule."Item No.");
        end else
            if Rule."Item Category" <> '' then begin
                SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
                ApplySalesItemCategoryFilter(Rule."Item Category", SalesInvLine);
            end;

        if Rule."Location Code" <> '' then
            SalesInvLine.SetRange("Location Code", Rule."Location Code");

        if SalesInvLine.FindSet() then
            repeat
                if not EntryAlreadyExists(Agreement."No.", CurrentVersion."Version No.",
                    LedgerEntry."Source Type"::"Sales Invoice",
                    SalesInvLine."Document No.", SalesInvLine."Line No.")
                then
                    InsertLedgerEntryFromSalesLine(Agreement, CurrentVersion, Rule, SalesInvLine);
            until SalesInvLine.Next() = 0;
    end;

    local procedure ApplyItemCategoryFilter(NoFieldNo: Integer; ItemCategoryCode: Code[20]; var PurchInvLine: Record "Purch. Inv. Line")
    var
        Item: Record Item;
        ItemFilter: Text;
    begin
        NoFieldNo := NoFieldNo; // avoid unused-parameter warnings; kept for readability of the join intent
        Item.SetRange("Item Category Code", ItemCategoryCode);
        ItemFilter := BuildItemFilterFromCategory(Item);
        if ItemFilter = '' then begin
            // No items belong to this category - guarantee zero matches on the source query.
            PurchInvLine.SetRange("No.", '<<no-match>>');
            exit;
        end;
        PurchInvLine.SetFilter("No.", ItemFilter);
    end;

    local procedure ApplySalesItemCategoryFilter(ItemCategoryCode: Code[20]; var SalesInvLine: Record "Sales Invoice Line")
    var
        Item: Record Item;
        ItemFilter: Text;
    begin
        Item.SetRange("Item Category Code", ItemCategoryCode);
        ItemFilter := BuildItemFilterFromCategory(Item);
        if ItemFilter = '' then begin
            SalesInvLine.SetRange("No.", '<<no-match>>');
            exit;
        end;
        SalesInvLine.SetFilter("No.", ItemFilter);
    end;

    local procedure BuildItemFilterFromCategory(var Item: Record Item) FilterExpr: Text
    begin
        // Build an OR filter of item numbers belonging to the requested category.
        // If no items match, returns an empty string; callers translate that to a no-match filter.
        FilterExpr := '';
        if Item.FindSet() then
            repeat
                if FilterExpr = '' then
                    FilterExpr := Item."No."
                else
                    FilterExpr := FilterExpr + '|' + Item."No.";
            until Item.Next() = 0;
    end;

    local procedure EntryAlreadyExists(AgreementNo: Code[20]; VersionNo: Integer; SourceType: Option; SourceDocNo: Code[20]; SourceLineNo: Integer): Boolean
    var
        LedgerEntry: Record "RBT Calculation Ledger Entry";
    begin
        LedgerEntry.SetCurrentKey("Source Type", "Source Document No.", "Source Document Line No.");
        LedgerEntry.SetRange("Source Type", SourceType);
        LedgerEntry.SetRange("Source Document No.", SourceDocNo);
        LedgerEntry.SetRange("Source Document Line No.", SourceLineNo);
        LedgerEntry.SetRange("Agreement No.", AgreementNo);
        LedgerEntry.SetRange("Agreement Version No.", VersionNo);
        exit(not LedgerEntry.IsEmpty());
    end;

    local procedure InsertLedgerEntryFromPurchLine(var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule"; var PurchInvLine: Record "Purch. Inv. Line")
    var
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        BaseAmount: Decimal;
    begin
        BaseAmount := PurchInvLine.Amount;

        LedgerEntry.Init();
        LedgerEntry."Source Type" := LedgerEntry."Source Type"::"Purchase Invoice";
        LedgerEntry."Source Document No." := PurchInvLine."Document No.";
        LedgerEntry."Source Document Line No." := PurchInvLine."Line No.";
        LedgerEntry."Posting Date" := PurchInvLine."Posting Date";
        LedgerEntry."Agreement No." := Agreement."No.";
        LedgerEntry."Agreement Version No." := CurrentVersion."Version No.";
        LedgerEntry."Rule Line No." := Rule."Line No.";
        // Item No. and Location Code are copied from the actual source line so the audit trail
        // reflects what was matched, not just what the rule filtered on.
        if PurchInvLine.Type = PurchInvLine.Type::Item then
            LedgerEntry."Item No." := PurchInvLine."No."
        else
            LedgerEntry."Item No." := '';
        LedgerEntry."Item Category" := Rule."Item Category";
        LedgerEntry."Location Code" := PurchInvLine."Location Code";
        LedgerEntry."Calculation Method" := Rule."Calculation Method";
        LedgerEntry."Base Amount" := BaseAmount;
        LedgerEntry.Percentage := Rule.Percentage;
        LedgerEntry."Fixed Amount" := Rule."Fixed Amount";
        LedgerEntry."Calculated Amount" := ComputeCalculatedAmount(Rule, BaseAmount);
        LedgerEntry."Currency Code" := Agreement."Currency Code";
        LedgerEntry.SetAllowInternalEdit(true);
        LedgerEntry.Insert(true);
        LedgerEntry.SetAllowInternalEdit(false);
    end;

    local procedure InsertLedgerEntryFromSalesLine(var Agreement: Record "RBT Rebate Agreement"; var CurrentVersion: Record "RBT Rebate Version"; var Rule: Record "RBT Rebate Rule"; var SalesInvLine: Record "Sales Invoice Line")
    var
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        BaseAmount: Decimal;
    begin
        BaseAmount := SalesInvLine.Amount;

        LedgerEntry.Init();
        LedgerEntry."Source Type" := LedgerEntry."Source Type"::"Sales Invoice";
        LedgerEntry."Source Document No." := SalesInvLine."Document No.";
        LedgerEntry."Source Document Line No." := SalesInvLine."Line No.";
        LedgerEntry."Posting Date" := SalesInvLine."Posting Date";
        LedgerEntry."Agreement No." := Agreement."No.";
        LedgerEntry."Agreement Version No." := CurrentVersion."Version No.";
        LedgerEntry."Rule Line No." := Rule."Line No.";
        if SalesInvLine.Type = SalesInvLine.Type::Item then
            LedgerEntry."Item No." := SalesInvLine."No."
        else
            LedgerEntry."Item No." := '';
        LedgerEntry."Item Category" := Rule."Item Category";
        LedgerEntry."Location Code" := SalesInvLine."Location Code";
        LedgerEntry."Calculation Method" := Rule."Calculation Method";
        LedgerEntry."Base Amount" := BaseAmount;
        LedgerEntry.Percentage := Rule.Percentage;
        LedgerEntry."Fixed Amount" := Rule."Fixed Amount";
        LedgerEntry."Calculated Amount" := ComputeCalculatedAmount(Rule, BaseAmount);
        LedgerEntry."Currency Code" := Agreement."Currency Code";
        LedgerEntry.SetAllowInternalEdit(true);
        LedgerEntry.Insert(true);
        LedgerEntry.SetAllowInternalEdit(false);
    end;

    local procedure ComputeCalculatedAmount(var Rule: Record "RBT Rebate Rule"; BaseAmount: Decimal): Decimal
    begin
        case Rule."Calculation Method" of
            Rule."Calculation Method"::Percentage:
                exit(BaseAmount * Rule.Percentage / 100);
            Rule."Calculation Method"::Fixed:
                exit(Rule."Fixed Amount");
        end;
        exit(0);
    end;
}
