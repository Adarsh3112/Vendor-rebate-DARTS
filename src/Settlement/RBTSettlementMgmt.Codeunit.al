codeunit 50107 "RBT Settlement Mgmt."
{
    var
        AlreadyPostedErr: Label 'Settlement %1 has already been posted.';
        NoOpenAccrualsErr: Label 'Settlement %1 cannot be posted: there are no open accrual entries for agreement %2.';
        LinesEmptyErr: Label 'Settlement %1 has no lines. Add at least one line before submitting.';
        LineAmountMismatchErr: Label 'Settlement %1 line total %2 does not match header Amount %3. Adjust lines or header before submitting.';
        AgreementMustBeActiveErr: Label 'Settlement %1 cannot be submitted because agreement %2 is not Active.';

    /// <summary>
    /// Transitions a Draft settlement to Pending after validating that lines
    /// exist, that the sum of line amounts equals the header Amount, and that
    /// the linked agreement is Active.
    /// </summary>
    procedure SubmitForApproval(var Settlement: Record "RBT Settlement Header")
    var
        SettlementLine: Record "RBT Settlement Line";
        AgreementHeader: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        LineTotal: Decimal;
    begin
        Settlement.TestField(Status, Settlement.Status::Draft);
        Settlement.TestField("Agreement No.");

        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        if SettlementLine.IsEmpty() then
            Error(LinesEmptyErr, Settlement."No.");

        SettlementLine.CalcSums(Amount);
        LineTotal := SettlementLine.Amount;
        if LineTotal <> Settlement.Amount then
            Error(LineAmountMismatchErr, Settlement."No.", LineTotal, Settlement.Amount);

        AgreementHeader.Get(Settlement."Agreement No.");
        if AgreementHeader.Status <> AgreementHeader.Status::Active then
            Error(AgreementMustBeActiveErr, Settlement."No.", Settlement."Agreement No.");

        Settlement.Status := Settlement.Status::Pending;
        Settlement.Modify();

        RebateMgmt.LogAudit(
            Settlement."No.",
            'Submit',
            CopyStr(StrSubstNo('Settlement %1 submitted for approval', Settlement."No."), 1, 250));
    end;

    /// <summary>
    /// Posts a Pending settlement: validates no-duplicate, open-accrual existence,
    /// blocked-party guards, looks up posting setup keyed by the agreement header's
    /// Posting Group, generates the appropriate credit memo via Purch.-Post or
    /// Sales-Post, closes every grouped accrual ledger entry via Modify(false),
    /// and stamps the settlement as Posted with the work-date Posting Date.
    /// </summary>
    procedure PostSettlement(var Settlement: Record "RBT Settlement Header")
    var
        AgreementHeader: Record "RBT Agreement Header";
        PostingSetup: Record "RBT Rebate Post Set";
        LedgerEntry: Record "RBT Rebate Ledg Ent";
        SettlementLine: Record "RBT Settlement Line";
        Vendor: Record Vendor;
        Customer: Record Customer;
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        // Duplicate-post guard.
        if Settlement.Status = Settlement.Status::Posted then
            Error(AlreadyPostedErr, Settlement."No.");

        Settlement.TestField(Status, Settlement.Status::Pending);
        Settlement.TestField("Agreement No.");
        Settlement.TestField("Vendor/Customer No.");

        AgreementHeader.Get(Settlement."Agreement No.");

        // Pre-post open-accrual check (Technical Hint).
        LedgerEntry.SetRange("Agreement No.", Settlement."Agreement No.");
        LedgerEntry.SetRange("Entry Type", LedgerEntry."Entry Type"::Accrual);
        LedgerEntry.SetRange(Status, LedgerEntry.Status::Open);
        if LedgerEntry.IsEmpty() then
            Error(NoOpenAccrualsErr, Settlement."No.", Settlement."Agreement No.");

        // Blocked-party check.
        case AgreementHeader."Type" of
            AgreementHeader."Type"::Vendor:
                begin
                    Vendor.Get(Settlement."Vendor/Customer No.");
                    Vendor.TestField(Blocked, Vendor.Blocked::" ");
                end;
            AgreementHeader."Type"::Customer:
                begin
                    Customer.Get(Settlement."Vendor/Customer No.");
                    Customer.TestField(Blocked, Customer.Blocked::" ");
                end;
        end;

        // Posting setup lookup via agreement header posting group.
        AgreementHeader.TestField("Posting Group");
        PostingSetup.GetPostingSetup(AgreementHeader."Posting Group");
        PostingSetup.TestField("Accrual Account No.");

        // Generate credit memo (Purchase for Vendor, Sales for Customer).
        GenerateCreditMemo(Settlement, AgreementHeader, PostingSetup);

        // Close grouped accrual entries via Modify(false) skip-trigger.
        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        if SettlementLine.FindSet() then
            repeat
                if LedgerEntry.Get(SettlementLine."Accrual Entry No.") then begin
                    LedgerEntry.Status := LedgerEntry.Status::Closed;
                    LedgerEntry."Closed by Settlement No." := Settlement."No.";
                    LedgerEntry.Modify(false);
                end;
            until SettlementLine.Next() = 0;

        // Finalise settlement header.
        Settlement.Status := Settlement.Status::Posted;
        Settlement."Posting Date" := WorkDate();
        Settlement.Modify();

        RebateMgmt.LogAudit(
            Settlement."No.",
            'Post',
            CopyStr(StrSubstNo('Settlement %1 posted; credit memo %2', Settlement."No.", Settlement."Posted Credit Memo No."), 1, 250));
    end;

    /// <summary>
    /// Builds and posts the standard BC credit memo that reverses the rebate
    /// accrual. Dispatches on AgreementHeader.Type — Vendor agreements emit a
    /// Purchase Credit Memo via Purch.-Post, Customer agreements emit a Sales
    /// Credit Memo via Sales-Post. The G/L account is sourced from the rebate
    /// posting setup keyed by the agreement header's Posting Group.
    /// </summary>
    procedure GenerateCreditMemo(var Settlement: Record "RBT Settlement Header"; AgreementHeader: Record "RBT Agreement Header"; PostingSetup: Record "RBT Rebate Post Set")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        DescTxt: Text[100];
    begin
        DescTxt := CopyStr(StrSubstNo('Rebate Settlement for Agreement %1', Settlement."Agreement No."), 1, 100);

        case AgreementHeader."Type" of
            AgreementHeader."Type"::Vendor:
                begin
                    PurchaseHeader.Init();
                    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
                    PurchaseHeader."No." := '';
                    PurchaseHeader.Insert(true);
                    PurchaseHeader.Validate("Buy-from Vendor No.", Settlement."Vendor/Customer No.");
                    PurchaseHeader.Validate("Posting Date", WorkDate());
                    if Settlement."Currency Code" <> '' then
                        PurchaseHeader.Validate("Currency Code", Settlement."Currency Code");
                    PurchaseHeader.Modify(true);

                    PurchaseLine.Init();
                    PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                    PurchaseLine."Document No." := PurchaseHeader."No.";
                    PurchaseLine."Line No." := 10000;
                    PurchaseLine.Validate("Type", PurchaseLine."Type"::"G/L Account");
                    PurchaseLine.Validate("No.", PostingSetup."Accrual Account No.");
                    PurchaseLine.Validate(Quantity, 1);
                    PurchaseLine.Validate("Direct Unit Cost", Settlement.Amount);
                    PurchaseLine.Description := DescTxt;
                    PurchaseLine.Insert(true);

                    Settlement."Credit Memo Type" := Settlement."Credit Memo Type"::Purchase;
                    Settlement."Credit Memo No." := PurchaseHeader."No.";
                    Settlement.Modify();

                    PurchPost.Run(PurchaseHeader);

                    Settlement."Posted Credit Memo No." := PurchaseHeader."Last Posting No.";
                    Settlement.Modify();

                    RebateMgmt.LogAudit(
                        Settlement."No.",
                        'Credit Memo',
                        CopyStr(StrSubstNo('Purchase Credit Memo %1 generated', Settlement."Posted Credit Memo No."), 1, 250));
                end;
            AgreementHeader."Type"::Customer:
                begin
                    SalesHeader.Init();
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    SalesHeader."No." := '';
                    SalesHeader.Insert(true);
                    SalesHeader.Validate("Sell-to Customer No.", Settlement."Vendor/Customer No.");
                    SalesHeader.Validate("Posting Date", WorkDate());
                    if Settlement."Currency Code" <> '' then
                        SalesHeader.Validate("Currency Code", Settlement."Currency Code");
                    SalesHeader.Modify(true);

                    SalesLine.Init();
                    SalesLine."Document Type" := SalesHeader."Document Type";
                    SalesLine."Document No." := SalesHeader."No.";
                    SalesLine."Line No." := 10000;
                    SalesLine.Validate("Type", SalesLine."Type"::"G/L Account");
                    SalesLine.Validate("No.", PostingSetup."Accrual Account No.");
                    SalesLine.Validate(Quantity, 1);
                    SalesLine.Validate("Unit Price", Settlement.Amount);
                    SalesLine.Description := DescTxt;
                    SalesLine.Insert(true);

                    Settlement."Credit Memo Type" := Settlement."Credit Memo Type"::Sales;
                    Settlement."Credit Memo No." := SalesHeader."No.";
                    Settlement.Modify();

                    SalesPost.Run(SalesHeader);

                    Settlement."Posted Credit Memo No." := SalesHeader."Last Posting No.";
                    Settlement.Modify();

                    RebateMgmt.LogAudit(
                        Settlement."No.",
                        'Credit Memo',
                        CopyStr(StrSubstNo('Sales Credit Memo %1 generated', Settlement."Posted Credit Memo No."), 1, 250));
                end;
        end;
    end;

    /// <summary>
    /// Card-page helper: enumerates all open Accrual ledger entries for the
    /// settlement's agreement and inserts one Settlement Line per row, then
    /// recomputes the header Amount as the sum of inserted line amounts.
    /// </summary>
    procedure SuggestAccruals(var Settlement: Record "RBT Settlement Header")
    var
        LedgerEntry: Record "RBT Rebate Ledg Ent";
        SettlementLine: Record "RBT Settlement Line";
        NextLineNo: Integer;
        Total: Decimal;
    begin
        Settlement.TestField(Status, Settlement.Status::Draft);
        Settlement.TestField("Agreement No.");

        // Determine next line number.
        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        if SettlementLine.FindLast() then
            NextLineNo := SettlementLine."Line No." + 10000
        else
            NextLineNo := 10000;

        // Pre-load existing lines so we can sum them at the end.
        SettlementLine.Reset();
        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        if SettlementLine.FindSet() then
            repeat
                Total += SettlementLine.Amount;
            until SettlementLine.Next() = 0;

        LedgerEntry.SetRange("Agreement No.", Settlement."Agreement No.");
        LedgerEntry.SetRange("Entry Type", LedgerEntry."Entry Type"::Accrual);
        LedgerEntry.SetRange(Status, LedgerEntry.Status::Open);
        if LedgerEntry.FindSet() then
            repeat
                SettlementLine.Init();
                SettlementLine."Settlement No." := Settlement."No.";
                SettlementLine."Line No." := NextLineNo;
                SettlementLine."Accrual Entry No." := LedgerEntry."Entry No.";
                SettlementLine.Amount := LedgerEntry.Amount;
                SettlementLine."Currency Code" := LedgerEntry."Currency Code";
                SettlementLine.Description := CopyStr(LedgerEntry."Document No.", 1, MaxStrLen(SettlementLine.Description));
                SettlementLine.Insert();
                Total += LedgerEntry.Amount;
                NextLineNo += 10000;
            until LedgerEntry.Next() = 0;

        Settlement.Amount := Total;
        Settlement.Modify();
    end;
}
