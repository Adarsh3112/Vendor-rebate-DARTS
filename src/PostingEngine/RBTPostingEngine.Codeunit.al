codeunit 50101 "RBT Posting Engine"
{
    // Accrual Posting Engine for Vendor Rebates.
    //
    // Public API:
    //   PostAccrual(var CalcRequest)     - writes a balanced 2-line G/L journal
    //                                       (Debit Accrual Expense / Credit Accrual Liability)
    //                                       via Codeunit "Gen. Jnl.-Post Line".
    //   PreviewAccrual(var CalcRequest)  - invokes Codeunit "Gen. Jnl.-Post Preview" (19)
    //                                       so the G/L entries can be inspected without persistence.
    //   OnRun(var CalcRequest)           - required by the Preview infrastructure;
    //                                       delegates straight to PostAccrual.

    TableNo = "RBT Calc Request";

    trigger OnRun()
    begin
        PostAccrual(Rec);
    end;

    var
        AlreadyPostedErr: Label 'Calc Request %1 has already been posted (No. of G/L Entries = %2). A Calc Request cannot be posted twice - create a new Calc Request for further accruals.', Comment = '%1 = Calc Request No., %2 = No. of G/L Entries already posted.';
        NothingToPostErr: Label 'Calc Request %1 has no Calculation Ledger Entries whose Posting Date falls inside the period, so there is nothing to post. Widen the period on the Calc Request or run the Rule Engine first.', Comment = '%1 = Calc Request No.';
        MissingAccrualSeriesErr: Label 'Accrual Nos. is not set up. Open the RBT Rebate Setup page and specify a No. Series for Accruals.';
        MissingPostingGroupErr: Label 'Rebate Agreement %1 has no Posting Group. Set the Posting Group on the RBT Rebate Agreement Card before posting an accrual.', Comment = '%1 = Agreement No.';
        PostedMsg: Label 'Rebate Accrual %1 posted successfully. %2 G/L Entries were created.', Comment = '%1 = Document No., %2 = number of G/L entries.';

    /// <summary>
    /// Posts a balanced Accrual Expense / Accrual Liability G/L journal for the
    /// given Calc Request. Uses Codeunit "Gen. Jnl.-Post Line" - the mandatory
    /// BC posting path that produces real G/L Entry rows.
    /// Rejects re-posting with an explicit error naming the Calc Request No.
    /// </summary>
    procedure PostAccrual(var CalcRequest: Record "RBT Calc Request")
    var
        Agreement: Record "RBT Rebate Agreement";
        PostingSetup: Record "RBT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        AuditMgt: Codeunit "RBT Audit Mgt.";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // (a) Duplicate-post guard - explicit error, not a silent no-op.
        if CalcRequest."Posting Status" = CalcRequest."Posting Status"::Posted then
            Error(AlreadyPostedErr, CalcRequest."No.", CalcRequest."No. of G/L Entries");

        // (b) Resolve the agreement and confirm it carries a Posting Group.
        Agreement.Get(CalcRequest."Agreement No.");
        if Agreement."Posting Group" = '' then
            Error(MissingPostingGroupErr, Agreement."No.");

        // (c) Look up the Posting Setup with the standard fallback and validate accounts.
        PostingSetup.GetPostingSetup(Agreement."Posting Group", Agreement."Currency Code");
        PostingSetup.TestAccounts();

        // (d) Aggregate Calculated Amount for the period via a database sum.
        TotalAmount := AggregateAmount(CalcRequest);
        if TotalAmount = 0 then
            Error(NothingToPostErr, CalcRequest."No.");

        // (e) Reserve a Document No. from the Accrual Nos. series.
        DocumentNo := AcquireAccrualDocumentNo(CalcRequest);

        // (f) Build and post the debit line.
        BuildAccrualLine(GenJnlLine, CalcRequest, DocumentNo, 10000,
            PostingSetup."Accrual Expense Acc.", TotalAmount);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // (g) Build and post the credit line - same Document No., opposite sign.
        BuildAccrualLine(GenJnlLine, CalcRequest, DocumentNo, 20000,
            PostingSetup."Accrual Liab. Acc.", -TotalAmount);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // (h) Stamp the Calc Request as posted via the internal-edit escape hatch.
        CalcRequest.SetAllowInternalEdit(true);
        CalcRequest."Posting Status" := CalcRequest."Posting Status"::Posted;
        CalcRequest."No. of G/L Entries" := 2;
        CalcRequest."Document No." := DocumentNo;
        CalcRequest.Modify(true);
        CalcRequest.SetAllowInternalEdit(false);

        // Audit trail: financial posting event. Document No. is the accrual document number
        // just reserved from the Accrual Nos. series; the Calc Request No. is passed for
        // cross-reference in the human-readable description.
        AuditMgt.LogAccrualPosted(CalcRequest."No.", DocumentNo, Database::"RBT Calc Request", TotalAmount, 2);

        Message(PostedMsg, DocumentNo, 2);
    end;

    /// <summary>
    /// Preview the accrual G/L entries without persisting to the Calc Request or the G/L.
    /// Invokes the standard BC "Gen. Jnl.-Post Preview" codeunit, which runs the
    /// posting inside a rollback transaction and displays the entries that would
    /// be produced. The Calc Request's Posting Status remains Open.
    /// </summary>
    procedure PreviewAccrual(var CalcRequest: Record "RBT Calc Request")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // Preview infrastructure re-runs the OnRun trigger inside a rollback transaction,
        // so posting to G/L is captured for display then rolled back. No side-effect on
        // the Calc Request. The duplicate-post guard is preserved by OnRun -> PostAccrual.
        // Signature: Preview(SubscriberCodeunitID: Integer; ParameterVariant: Variant).
        GenJnlPostPreview.Preview(Codeunit::"RBT Posting Engine", CalcRequest);
    end;

    local procedure AggregateAmount(var CalcRequest: Record "RBT Calc Request"): Decimal
    var
        LedgerEntry: Record "RBT Calculation Ledger Entry";
    begin
        LedgerEntry.Reset();
        LedgerEntry.SetRange("Agreement No.", CalcRequest."Agreement No.");
        if (CalcRequest."Period Start" <> 0D) or (CalcRequest."Period End" <> 0D) then
            LedgerEntry.SetRange("Posting Date", CalcRequest."Period Start", CalcRequest."Period End");
        LedgerEntry.CalcSums("Calculated Amount");
        exit(LedgerEntry."Calculated Amount");
    end;

    local procedure AcquireAccrualDocumentNo(var CalcRequest: Record "RBT Calc Request"): Code[20]
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        RebateSetup.GetSetup();
        if RebateSetup."Accrual Nos." = '' then
            Error(MissingAccrualSeriesErr);
        exit(NoSeries.GetNextNo(RebateSetup."Accrual Nos.", CalcRequest."Posting Date", true));
    end;

    local procedure BuildAccrualLine(var GenJnlLine: Record "Gen. Journal Line"; var CalcRequest: Record "RBT Calc Request"; DocumentNo: Code[20]; LineNo: Integer; AccountNo: Code[20]; Amount: Decimal)
    var
        PostingDate: Date;
        DescriptionLbl: Label 'Rebate Accrual %1', Comment = '%1 = Calc Request No.';
    begin
        PostingDate := CalcRequest."Posting Date";
        if PostingDate = 0D then
            PostingDate := WorkDate();

        Clear(GenJnlLine);
        GenJnlLine.Init();
        // Template-less / batch-less invocation is supported when calling Gen. Jnl.-Post Line directly.
        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := '';
        GenJnlLine."Line No." := LineNo;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Currency Code", CalcRequest."Currency Code");
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Description := StrSubstNo(DescriptionLbl, CalcRequest."No.");
        GenJnlLine."Source Code" := '';
        GenJnlLine."System-Created Entry" := true;
    end;
}
