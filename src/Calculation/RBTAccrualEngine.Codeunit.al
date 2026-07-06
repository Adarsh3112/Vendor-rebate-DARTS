codeunit 50103 "RBT Accrual Engine"
{
    TableNo = "RBT Rebate Calc Hdr";

    trigger OnRun()
    begin
        PostAccruals(Rec);
    end;

    /// <summary>
    /// F-04 accrual posting engine. For each unposted RBT Calc Ledg Entry row
    /// linked to the supplied calculation request header, posts a balanced
    /// debit-Expense / credit-Accrual pair via GenJnlPostLine.RunWithCheck,
    /// sourcing G/L accounts from RBT Rebate Post Set keyed by the agreement
    /// header's Posting Group (NOT the vendor's Vendor Posting Group), and
    /// propagating Dimension Set ID + Shortcut Dimensions from the source
    /// Sales Invoice Header or Purch. Inv. Header. Marks each posted row as
    /// Posted via Modify(false) skip-trigger to bypass the table's strict
    /// immutability guard.
    /// </summary>
    procedure PostAccruals(var CalcHeader: Record "RBT Rebate Calc Hdr")
    var
        Header: Record "RBT Agreement Header";
        PostingSetup: Record "RBT Rebate Post Set";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        AggregateLedger: Record "RBT Rebate Ledg Ent";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        GLEntryCount: Integer;
        RunAmountLCY: Decimal;
        RunAmountFCY: Decimal;
        RunCurrencyCode: Code[10];
    begin
        // (1) Outer duplicate guard - preserves prior behaviour.
        if CalcHeader."Posting Status" = CalcHeader."Posting Status"::Posted then
            Error('Calculation Request %1 has already been posted.', CalcHeader."No.");

        // (2) Resolve agreement once per run.
        Header.Get(CalcHeader."Agreement No.");
        Header.TestField(Status, Header.Status::Active);
        Header.TestField("Posting Group");

        // (3) Resolve posting setup once per run, keyed by the AGREEMENT HEADER's
        // Posting Group (the correction the spec requires - the old engine was
        // wrongly keying off Vendor."Vendor Posting Group").
        PostingSetup.GetPostingSetup(Header."Posting Group");
        PostingSetup.TestField("Expense Account No.");
        PostingSetup.TestField("Accrual Account No.");

        RunCurrencyCode := Header."Currency Code";

        // (4) Iterate Calc Ledger Entries for this calc request.
        CalcLedgEntry.Reset();
        CalcLedgEntry.SetRange("Calculation Req. No.", CalcHeader."No.");
        if CalcLedgEntry.FindSet() then
            repeat
                if not CalcLedgEntry.Posted then begin
                    PostOneRow(CalcHeader, Header, PostingSetup, CalcLedgEntry);
                    GLEntryCount += 2;
                    RunAmountLCY += CalcLedgEntry."Amount LCY";
                    RunAmountFCY += CalcLedgEntry."Amount FCY";
                    if CalcLedgEntry."Currency Code" <> '' then
                        RunCurrencyCode := CalcLedgEntry."Currency Code";
                end;
            until CalcLedgEntry.Next() = 0;

        // (9) Aggregate ledger row - preserves today's pattern.
        AggregateLedger.Init();
        AggregateLedger."Agreement No." := CalcHeader."Agreement No.";
        AggregateLedger."Vendor No." := Header."Vendor No.";
        AggregateLedger."Posting Date" := CalcHeader."Calc. To Date";
        AggregateLedger."Document No." := CalcHeader."No.";
        AggregateLedger.Amount := RunAmountFCY;
        AggregateLedger."Amount (LCY)" := RunAmountLCY;
        if AggregateLedger."Amount (LCY)" < 0 then
            AggregateLedger."Amount (LCY)" := -AggregateLedger."Amount (LCY)";
        AggregateLedger."Currency Code" := RunCurrencyCode;
        AggregateLedger."Entry Type" := 0; // 0 = Accrual
        AggregateLedger.Insert();

        // Finalise calc header.
        CalcHeader."Posting Status" := CalcHeader."Posting Status"::Posted;
        CalcHeader."No. of G/L Entries" := GLEntryCount;
        CalcHeader.Modify();

        // Audit trail via shared LogAudit on RBT Rebate Mgmt.
        RebateMgmt.LogAudit(
            CalcHeader."Agreement No.",
            'Post Accrual',
            StrSubstNo('Posted %1 G/L entries for request %2.', GLEntryCount, CalcHeader."No."));
    end;

    local procedure PostOneRow(var CalcHeader: Record "RBT Rebate Calc Hdr"; var Header: Record "RBT Agreement Header"; var PostingSetup: Record "RBT Rebate Post Set"; var CalcLedgEntry: Record "RBT Calc Ledg Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimensionSetID: Integer;
        ShortcutDim1: Code[20];
        ShortcutDim2: Code[20];
        PostingDate: Date;
        CurrencyCode: Code[10];
        DocDescription: Text[100];
    begin
        ResolveSourceDimensions(CalcLedgEntry, DimensionSetID, ShortcutDim1, ShortcutDim2);

        PostingDate := CalcLedgEntry."Posting Date";
        if PostingDate = 0D then
            PostingDate := CalcHeader."Calc. To Date";

        CurrencyCode := CalcLedgEntry."Currency Code";

        DocDescription := CopyStr(
            StrSubstNo('Rebate Accrual %1 Entry %2', CalcHeader."Agreement No.", CalcLedgEntry."Entry No."),
            1, MaxStrLen(DocDescription));

        // (6) Debit-Expense leg.
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document No." := CalcHeader."No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", PostingSetup."Expense Account No.");
        GenJnlLine.Description := DocDescription;
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, CalcLedgEntry."Amount FCY");
        GenJnlLine."Dimension Set ID" := DimensionSetID;
        GenJnlLine."Shortcut Dimension 1 Code" := ShortcutDim1;
        GenJnlLine."Shortcut Dimension 2 Code" := ShortcutDim2;
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // (7) Credit-Accrual leg.
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document No." := CalcHeader."No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", PostingSetup."Accrual Account No.");
        GenJnlLine.Description := DocDescription;
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, -CalcLedgEntry."Amount FCY");
        GenJnlLine."Dimension Set ID" := DimensionSetID;
        GenJnlLine."Shortcut Dimension 1 Code" := ShortcutDim1;
        GenJnlLine."Shortcut Dimension 2 Code" := ShortcutDim2;
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // (8) Mark Calc Ledger Entry as Posted via skip-trigger pattern (same
        // technique DemoteCurrentVersions uses on the immutable Version table).
        CalcLedgEntry.Posted := true;
        CalcLedgEntry."Posted At" := CurrentDateTime();
        CalcLedgEntry.Modify(false);
    end;

    local procedure ResolveSourceDimensions(CalcLedgEntry: Record "RBT Calc Ledg Entry"; var DimensionSetID: Integer; var ShortcutDim1: Code[20]; var ShortcutDim2: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        DimensionSetID := 0;
        ShortcutDim1 := '';
        ShortcutDim2 := '';

        if CalcLedgEntry."Source Trans. No." = '' then
            exit;

        case CalcLedgEntry."Source Type" of
            CalcLedgEntry."Source Type"::Purchase:
                if PurchInvHeader.Get(CalcLedgEntry."Source Trans. No.") then begin
                    DimensionSetID := PurchInvHeader."Dimension Set ID";
                    ShortcutDim1 := PurchInvHeader."Shortcut Dimension 1 Code";
                    ShortcutDim2 := PurchInvHeader."Shortcut Dimension 2 Code";
                end;
            CalcLedgEntry."Source Type"::Sales:
                if SalesInvHeader.Get(CalcLedgEntry."Source Trans. No.") then begin
                    DimensionSetID := SalesInvHeader."Dimension Set ID";
                    ShortcutDim1 := SalesInvHeader."Shortcut Dimension 1 Code";
                    ShortcutDim2 := SalesInvHeader."Shortcut Dimension 2 Code";
                end;
        end;
    end;
}
