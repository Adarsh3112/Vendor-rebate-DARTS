codeunit 50102 "RBT Settlement Engine"
{
    // Settlement Engine for Vendor Rebates and Customer Incentives.
    //
    // Public API:
    //   GenerateProposalsAll()                          - bulk generation across all eligible Calc Requests.
    //   GenerateProposals(var HeaderFilter)             - generation filtered by an existing Draft header, or by
    //                                                     a range of headers pre-set by the caller.
    //   SendForApproval(var Header)                     - Draft -> Pending, wraps Approvals Mgmt.
    //   CancelApproval(var Header)                      - Pending -> Draft, wraps Approvals Mgmt.
    //   Approve(var Header)                             - Pending -> Approved (direct approval fallback).
    //   PreviewSettlement(var Header)                   - preview credit memo posting without persistence.
    //   PostSettlement(var Header)                      - Approved -> Posted, produces the credit memo, links Calc Requests.
    //   OnRun(var Header)                               - delegates to PostSettlement (required by preview infra).

    TableNo = "RBT Settlement Header";

    trigger OnRun()
    begin
        PostSettlement(Rec);
    end;

    var
        AlreadyPostedErr: Label 'Settlement %1 has already been posted. Create a new Settlement.', Comment = '%1 = Settlement No.';
        NotApprovedErr: Label 'Settlement %1 has Status = %2 and cannot be posted. Only Approved settlements can be posted.', Comment = '%1 = Settlement No., %2 = current Status.';
        MissingPostingGroupErr: Label 'Agreement %1 has no Posting Group. Set the Posting Group before posting a settlement.', Comment = '%1 = Agreement No.';
        NothingToSettleErr: Label 'Settlement %1 has no Lines. Generate a proposal or add lines before posting.', Comment = '%1 = Settlement No.';
        InvalidStatusForSendErr: Label 'Settlement %1 has Status = %2. Only Draft settlements can be sent for approval.', Comment = '%1 = Settlement No., %2 = current Status.';
        InvalidStatusForCancelErr: Label 'Settlement %1 has Status = %2. Only Pending settlements can have their approval cancelled.', Comment = '%1 = Settlement No., %2 = current Status.';
        InvalidStatusForApproveErr: Label 'Settlement %1 has Status = %2. Only Pending settlements can be approved.', Comment = '%1 = Settlement No., %2 = current Status.';
        PostedMsg: Label 'Settlement %1 posted successfully. Credit Memo %2 has been created.', Comment = '%1 = Settlement No., %2 = Posted Credit Memo No.';

    /// <summary>
    /// Bulk proposal generation. Iterates every eligible posted Calc Request whose
    /// Settlement No. is still blank and groups them into new Draft settlements.
    /// </summary>
    procedure GenerateProposalsAll()
    var
        EmptyFilter: Record "RBT Settlement Header";
    begin
        // Empty filter -> generate for the entire eligible universe (no header pre-existing).
        GenerateProposals(EmptyFilter);
    end;

    /// <summary>
    /// Proposal generation. Groups eligible posted Calc Requests (Posting Status = Posted,
    /// Settlement No. blank) by (Agreement No., Vendor/Customer, Currency Code, Posting Group)
    /// and creates one Draft Settlement Header per group plus one Line per source Calc Request.
    /// Settlement No. on the source Calc Request is populated only at post time - a Draft
    /// proposal can be re-generated or discarded without side effects on the accruals.
    /// </summary>
    procedure GenerateProposals(var HeaderFilter: Record "RBT Settlement Header")
    var
        CalcRequest: Record "RBT Calc Request";
        Agreement: Record "RBT Rebate Agreement";
        NewLine: Record "RBT Settlement Line";
        AgreementNoFilter: Code[20];
    begin
        // If the caller pre-filtered a specific Draft header we regenerate its lines only.
        // Otherwise we iterate the full universe of eligible Calc Requests.
        if HeaderFilter.FindSet() then
            repeat
                if HeaderFilter.Status = HeaderFilter.Status::Draft then begin
                    AgreementNoFilter := HeaderFilter."Agreement No.";
                    // Clear existing lines under this Draft header first.
                    NewLine.Reset();
                    NewLine.SetRange("Settlement No.", HeaderFilter."No.");
                    if not NewLine.IsEmpty() then
                        NewLine.DeleteAll();
                    // Re-attach eligible Calc Requests matching this header's agreement.
                    CalcRequest.Reset();
                    CalcRequest.SetRange("Posting Status", CalcRequest."Posting Status"::Posted);
                    CalcRequest.SetRange("Settlement No.", '');
                    if AgreementNoFilter <> '' then
                        CalcRequest.SetRange("Agreement No.", AgreementNoFilter);
                    if CalcRequest.FindSet() then
                        repeat
                            if Agreement.Get(CalcRequest."Agreement No.") then
                                if IsSameGroup(HeaderFilter, Agreement, CalcRequest) then
                                    InsertProposalLine(HeaderFilter, Agreement, CalcRequest);
                        until CalcRequest.Next() = 0;
                end;
            until HeaderFilter.Next() = 0
        else
            GenerateProposalsBulk();
    end;

    local procedure GenerateProposalsBulk()
    var
        CalcRequest: Record "RBT Calc Request";
        Agreement: Record "RBT Rebate Agreement";
        NewHeader: Record "RBT Settlement Header";
    begin
        CalcRequest.Reset();
        CalcRequest.SetRange("Posting Status", CalcRequest."Posting Status"::Posted);
        CalcRequest.SetRange("Settlement No.", '');
        if not CalcRequest.FindSet() then
            exit;

        repeat
            if Agreement.Get(CalcRequest."Agreement No.") then begin
                FindOrCreateHeader(NewHeader, Agreement, CalcRequest);
                InsertProposalLine(NewHeader, Agreement, CalcRequest);
            end;
        until CalcRequest.Next() = 0;
    end;

    local procedure IsSameGroup(Header: Record "RBT Settlement Header"; Agreement: Record "RBT Rebate Agreement"; CalcRequest: Record "RBT Calc Request"): Boolean
    begin
        if Header."Agreement No." <> Agreement."No." then
            exit(false);
        if Header."Currency Code" <> CalcRequest."Currency Code" then
            exit(false);
        if Header."Posting Group" <> Agreement."Posting Group" then
            exit(false);
        if Agreement."Type" = Agreement."Type"::"Vendor Rebate" then
            exit(Header."Vendor No." = Agreement."Vendor No.");
        exit(Header."Customer No." = Agreement."Customer No.");
    end;

    local procedure FindOrCreateHeader(var Header: Record "RBT Settlement Header"; Agreement: Record "RBT Rebate Agreement"; CalcRequest: Record "RBT Calc Request")
    var
        Existing: Record "RBT Settlement Header";
    begin
        // Look for an existing Draft header for this exact group.
        Existing.Reset();
        Existing.SetRange(Status, Existing.Status::Draft);
        Existing.SetRange("Agreement No.", Agreement."No.");
        Existing.SetRange("Currency Code", CalcRequest."Currency Code");
        Existing.SetRange("Posting Group", Agreement."Posting Group");
        if Agreement."Type" = Agreement."Type"::"Vendor Rebate" then
            Existing.SetRange("Vendor No.", Agreement."Vendor No.")
        else
            Existing.SetRange("Customer No.", Agreement."Customer No.");
        if Existing.FindFirst() then begin
            Header := Existing;
            exit;
        end;

        // Create a new Draft header for this group.
        Header.Init();
        Header."No." := '';
        Header.Insert(true);
        Header.Description := CopyStr('Settlement for ' + Agreement."No.", 1, MaxStrLen(Header.Description));
        Header."Agreement No." := Agreement."No.";
        Header."Vendor No." := Agreement."Vendor No.";
        Header."Customer No." := Agreement."Customer No.";
        Header."Currency Code" := CalcRequest."Currency Code";
        Header."Posting Group" := Agreement."Posting Group";
        Header."Settlement Date" := WorkDate();
        Header."Posting Date" := WorkDate();
        Header.Status := Header.Status::Draft;
        Header.Modify();
    end;

    local procedure InsertProposalLine(Header: Record "RBT Settlement Header"; Agreement: Record "RBT Rebate Agreement"; var CalcRequest: Record "RBT Calc Request")
    var
        Line: Record "RBT Settlement Line";
        LineAmount: Decimal;
    begin
        // Compute amount from the source Calc Request's FlowField.
        CalcRequest.CalcFields("Total Accrual Amount");
        LineAmount := CalcRequest."Total Accrual Amount";

        Line.Init();
        Line."Settlement No." := Header."No.";
        Line."Line No." := 0; // Assigned by the Line's OnInsert trigger.
        Line."Calc Request No." := CalcRequest."No.";
        Line."Agreement No." := Agreement."No.";
        Line."Vendor No." := Agreement."Vendor No.";
        Line."Customer No." := Agreement."Customer No.";
        Line.Amount := LineAmount;
        Line."Currency Code" := CalcRequest."Currency Code";
        Line."Posting Date" := CalcRequest."Posting Date";
        Line.Description := CopyStr('From Calc Request ' + CalcRequest."No.", 1, MaxStrLen(Line.Description));
        Line.Insert(true);
    end;

    /// <summary>
    /// Sends the settlement into the standard BC approval workflow. Raises the
    /// custom workflow event 'RBTSettlementSendForApprovalCode' via WorkflowManagement.HandleEvent
    /// so any workflow subscribed to the RBT Settlement Header record type is triggered.
    /// On success, Status is flipped to Pending and Sent For Approval Date/By are stamped.
    /// </summary>
    procedure SendForApproval(var Header: Record "RBT Settlement Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if Header.Status <> Header.Status::Draft then
            Error(InvalidStatusForSendErr, Header."No.", Format(Header.Status));

        // Raise the custom workflow event for this settlement record so any subscribed
        // BC workflow is triggered. When no workflow is configured, the call is a no-op
        // and the direct-approval fallback (see Approve()) can be used.
        WorkflowManagement.HandleEvent(RBTSettlementSendForApprovalCode(), Header);

        Header.SetAllowInternalEdit(true);
        Header.Status := Header.Status::Pending;
        Header."Sent For Approval Date" := CurrentDateTime();
        Header."Sent For Approval By" := CopyStr(UserId(), 1, MaxStrLen(Header."Sent For Approval By"));
        Header.Modify();
        Header.SetAllowInternalEdit(false);
    end;

    /// <summary>
    /// Recalls a pending approval request. Cancels any open approval entries against
    /// this settlement via Approvals Mgmt. and returns the settlement to Draft.
    /// </summary>
    procedure CancelApproval(var Header: Record "RBT Settlement Header")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowStepInstance: Record "Workflow Step Instance";
        RecRef: RecordRef;
    begin
        if Header.Status <> Header.Status::Pending then
            Error(InvalidStatusForCancelErr, Header."No.", Format(Header.Status));

        RecRef.GetTable(Header);

        // Cancel any open approval requests linked to this record. When no approval
        // entry exists (e.g. no workflow was configured), the call is a safe no-op.
        ApprovalEntry.SetRange("Table ID", Database::"RBT Settlement Header");
        ApprovalEntry.SetRange("Record ID to Approve", Header.RecordId());
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        if not ApprovalEntry.IsEmpty() then
            ApprovalsMgmt.CancelApprovalRequestsForRecord(RecRef, WorkflowStepInstance);

        Header.SetAllowInternalEdit(true);
        Header.Status := Header.Status::Draft;
        Clear(Header."Sent For Approval Date");
        Header."Sent For Approval By" := '';
        Header.Modify();
        Header.SetAllowInternalEdit(false);
    end;

    /// <summary>
    /// Returns the workflow event code for RBT Settlement 'send for approval'.
    /// Custom workflow subscribers listen for this event to route the settlement.
    /// </summary>
    procedure RBTSettlementSendForApprovalCode(): Code[128]
    begin
        exit('RBTSettlementSendForApproval');
    end;


    /// <summary>
    /// Direct-approval fallback used when no workflow is configured (per the platform
    /// Approval Workflow rule). Flips Pending -> Approved and stamps Approved Date/By.
    /// </summary>
    procedure Approve(var Header: Record "RBT Settlement Header")
    begin
        if Header.Status <> Header.Status::Pending then
            Error(InvalidStatusForApproveErr, Header."No.", Format(Header.Status));

        Header.SetAllowInternalEdit(true);
        Header.Status := Header.Status::Approved;
        Header."Approved Date" := CurrentDateTime();
        Header."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Header."Approved By"));
        Header.Modify();
        Header.SetAllowInternalEdit(false);
    end;

    /// <summary>
    /// Preview credit memo posting via BC's standard "Gen. Jnl.-Post Preview" infrastructure.
    /// Runs the posting inside a rollback transaction so the entries can be inspected.
    /// </summary>
    procedure PreviewSettlement(var Header: Record "RBT Settlement Header")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        GenJnlPostPreview.Preview(Codeunit::"RBT Settlement Engine", Header);
    end;

    /// <summary>
    /// Post an Approved settlement. Produces either a Purchase Credit Memo (Vendor Rebate)
    /// or a Sales Credit Memo (Customer Incentive) using the standard BC posting codeunits,
    /// then back-links each source Calc Request via its Settlement No. field.
    /// </summary>
    procedure PostSettlement(var Header: Record "RBT Settlement Header")
    var
        Agreement: Record "RBT Rebate Agreement";
        PostingSetup: Record "RBT Posting Setup";
        SettlementLine: Record "RBT Settlement Line";
        AuditMgt: Codeunit "RBT Audit Mgt.";
        PostedDocNo: Code[20];
        DocumentType: Option " ",Purchase,Sales;
        TotalAmount: Decimal;
    begin
        // (a) Duplicate-post guard - explicit error, not a silent no-op.
        if Header.Status = Header.Status::Posted then
            Error(AlreadyPostedErr, Header."No.");

        // (b) Pre-post approval check - only Approved settlements can be posted.
        if Header.Status <> Header.Status::Approved then
            Error(NotApprovedErr, Header."No.", Format(Header.Status));

        // (c) Confirm at least one line exists.
        SettlementLine.Reset();
        SettlementLine.SetRange("Settlement No.", Header."No.");
        if SettlementLine.IsEmpty() then
            Error(NothingToSettleErr, Header."No.");

        // (d) Resolve the Agreement and confirm it carries a Posting Group.
        Agreement.Get(Header."Agreement No.");
        if Agreement."Posting Group" = '' then
            Error(MissingPostingGroupErr, Agreement."No.");

        // (e) Look up the Posting Setup with the standard fallback and validate accounts.
        //     Settlement Acc. is mandatory (see PostingSetup.TestAccounts).
        PostingSetup.GetPostingSetup(Agreement."Posting Group", Header."Currency Code");
        PostingSetup.TestField("Settlement Acc.");

        // (f) Branch on Agreement Type and build the appropriate credit memo.
        if Agreement."Type" = Agreement."Type"::"Vendor Rebate" then begin
            PostedDocNo := PostVendorCreditMemo(Header, Agreement, PostingSetup);
            DocumentType := DocumentType::Purchase;
        end else begin
            PostedDocNo := PostCustomerCreditMemo(Header, Agreement, PostingSetup);
            DocumentType := DocumentType::Sales;
        end;

        // (g) Back-link each source Calc Request through the internal-edit escape hatch.
        LinkSourceCalcRequests(Header);

        // (h) Stamp the header as Posted through the internal-edit escape hatch. The header
        //     OnModify guard would otherwise reject the transition once Status = Posted.
        Header.SetAllowInternalEdit(true);
        Header.Status := Header.Status::Posted;
        Header."Posted Date" := CurrentDateTime();
        Header."Posted By" := CopyStr(UserId(), 1, MaxStrLen(Header."Posted By"));
        Header."Credit Memo Document Type" := DocumentType;
        Header."Posted Credit Memo No." := PostedDocNo;
        Header.Modify();
        Header.SetAllowInternalEdit(false);

        // Audit trail: financial posting event on the immutable RBT Audit Entry table.
        // Document No. is the posted credit memo document; the Settlement No. is passed
        // for cross-reference in the human-readable description.
        SettlementLine.Reset();
        SettlementLine.SetRange("Settlement No.", Header."No.");
        SettlementLine.CalcSums(Amount);
        TotalAmount := SettlementLine.Amount;
        AuditMgt.LogSettlementPosted(Header."No.", PostedDocNo, Database::"RBT Settlement Header", TotalAmount);

        Message(PostedMsg, Header."No.", PostedDocNo);
    end;

    local procedure PostVendorCreditMemo(var Header: Record "RBT Settlement Header"; Agreement: Record "RBT Rebate Agreement"; PostingSetup: Record "RBT Posting Setup"): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SettlementLine: Record "RBT Settlement Line";
        PostedCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchPost: Codeunit "Purch.-Post";
        NextLineNo: Integer;
        DescriptionLbl: Label 'Rebate Settlement %1', Comment = '%1 = Settlement No.';
    begin
        Agreement.TestField("Vendor No.");

        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::"Credit Memo";
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", Agreement."Vendor No.");
        PurchHeader.Validate("Posting Date", Header."Posting Date");
        if Header."Currency Code" <> '' then
            PurchHeader.Validate("Currency Code", Header."Currency Code");
        PurchHeader."Vendor Cr. Memo No." := Header."No.";
        PurchHeader.Modify(true);

        NextLineNo := 10000;
        SettlementLine.Reset();
        SettlementLine.SetRange("Settlement No.", Header."No.");
        if SettlementLine.FindSet() then
            repeat
                PurchLine.Init();
                PurchLine."Document Type" := PurchHeader."Document Type";
                PurchLine."Document No." := PurchHeader."No.";
                PurchLine."Line No." := NextLineNo;
                PurchLine.Insert(true);
                PurchLine.Validate("Type", PurchLine."Type"::"G/L Account");
                PurchLine.Validate("No.", PostingSetup."Settlement Acc.");
                PurchLine.Validate(Quantity, 1);
                PurchLine.Validate("Direct Unit Cost", SettlementLine.Amount);
                PurchLine.Description := CopyStr(StrSubstNo(DescriptionLbl, Header."No."), 1, MaxStrLen(PurchLine.Description));
                PurchLine.Modify(true);
                NextLineNo += 10000;
            until SettlementLine.Next() = 0;

        // Run standard BC Purchase posting. Returns after producing the posted Cr. Memo.
        PurchPost.Run(PurchHeader);

        // Locate the posted credit memo produced from this pre-posting header no.
        PostedCrMemoHdr.Reset();
        PostedCrMemoHdr.SetRange("Vendor Cr. Memo No.", Header."No.");
        if PostedCrMemoHdr.FindLast() then
            exit(PostedCrMemoHdr."No.");
        // Fallback: BC may leave the source doc no. on the pre-assigned No. when a posting series is used.
        PostedCrMemoHdr.Reset();
        PostedCrMemoHdr.SetRange("Pre-Assigned No.", PurchHeader."No.");
        if PostedCrMemoHdr.FindLast() then
            exit(PostedCrMemoHdr."No.");
        exit(PurchHeader."No.");
    end;

    local procedure PostCustomerCreditMemo(var Header: Record "RBT Settlement Header"; Agreement: Record "RBT Rebate Agreement"; PostingSetup: Record "RBT Posting Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SettlementLine: Record "RBT Settlement Line";
        PostedCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesPost: Codeunit "Sales-Post";
        NextLineNo: Integer;
        DescriptionLbl: Label 'Customer Incentive %1', Comment = '%1 = Settlement No.';
    begin
        Agreement.TestField("Customer No.");

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Agreement."Customer No.");
        SalesHeader.Validate("Posting Date", Header."Posting Date");
        if Header."Currency Code" <> '' then
            SalesHeader.Validate("Currency Code", Header."Currency Code");
        SalesHeader."External Document No." := Header."No.";
        SalesHeader.Modify(true);

        NextLineNo := 10000;
        SettlementLine.Reset();
        SettlementLine.SetRange("Settlement No.", Header."No.");
        if SettlementLine.FindSet() then
            repeat
                SalesLine.Init();
                SalesLine."Document Type" := SalesHeader."Document Type";
                SalesLine."Document No." := SalesHeader."No.";
                SalesLine."Line No." := NextLineNo;
                SalesLine.Insert(true);
                SalesLine.Validate("Type", SalesLine."Type"::"G/L Account");
                SalesLine.Validate("No.", PostingSetup."Settlement Acc.");
                SalesLine.Validate(Quantity, 1);
                SalesLine.Validate("Unit Price", SettlementLine.Amount);
                SalesLine.Description := CopyStr(StrSubstNo(DescriptionLbl, Header."No."), 1, MaxStrLen(SalesLine.Description));
                SalesLine.Modify(true);
                NextLineNo += 10000;
            until SettlementLine.Next() = 0;

        SalesPost.Run(SalesHeader);

        PostedCrMemoHeader.Reset();
        PostedCrMemoHeader.SetRange("External Document No.", Header."No.");
        if PostedCrMemoHeader.FindLast() then
            exit(PostedCrMemoHeader."No.");
        PostedCrMemoHeader.Reset();
        PostedCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        if PostedCrMemoHeader.FindLast() then
            exit(PostedCrMemoHeader."No.");
        exit(SalesHeader."No.");
    end;

    local procedure LinkSourceCalcRequests(var Header: Record "RBT Settlement Header")
    var
        Line: Record "RBT Settlement Line";
        CalcRequest: Record "RBT Calc Request";
    begin
        Line.Reset();
        Line.SetRange("Settlement No.", Header."No.");
        if Line.FindSet() then
            repeat
                if CalcRequest.Get(Line."Calc Request No.") then begin
                    CalcRequest.SetAllowInternalEdit(true);
                    CalcRequest."Settlement No." := Header."No.";
                    CalcRequest.Modify(true);
                    CalcRequest.SetAllowInternalEdit(false);
                end;
            until Line.Next() = 0;
    end;
}
