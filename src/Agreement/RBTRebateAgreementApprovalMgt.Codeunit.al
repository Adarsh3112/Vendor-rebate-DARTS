codeunit 50110 "RBT Rebate Agreement Approval"
{
    // Standard BC Approval Workflow integration for RBT Rebate Agreement.
    //
    // Public API:
    //   SendForApproval(var Agreement)          - Draft -> Pending Approval via ApprovalsMgmt + WorkflowManagement.
    //   CancelApprovalRequest(var Agreement)    - Pending Approval -> Draft, cancels open approval entries.
    //   Approve(var Agreement)                  - direct-approval fallback (Pending Approval -> Approved).
    //   RBTAgreementSendForApprovalCode()       - workflow event code for subscribers.
    //   PrePostApprovalCheck(var Agreement)     - guard used by activation flow to block posting when pending.

    TableNo = "RBT Rebate Agreement";

    trigger OnRun()
    begin
        SendForApproval(Rec);
    end;

    var
        InvalidStatusForSendErr: Label 'Rebate Agreement %1 has Status = %2. Only Draft agreements can be sent for approval.', Comment = '%1 = Agreement No., %2 = current Status.';
        InvalidStatusForCancelErr: Label 'Rebate Agreement %1 has Status = %2. Only Pending Approval agreements can have their approval cancelled.', Comment = '%1 = Agreement No., %2 = current Status.';
        InvalidStatusForApproveErr: Label 'Rebate Agreement %1 has Status = %2. Only Pending Approval agreements can be approved.', Comment = '%1 = Agreement No., %2 = current Status.';
        SignatoryMissingErr: Label 'Signatory Code is missing on agreement %1. Fill in the Signatory Code (User Setup) on the RBT Rebate Agreement Card before sending for approval.', Comment = '%1 = Agreement No.';
        SignedDateMissingErr: Label 'Signed Date is missing on agreement %1. Fill in the Signed Date on the RBT Rebate Agreement Card before sending for approval.', Comment = '%1 = Agreement No.';
        SignedDateFutureErr: Label 'Signed Date on agreement %1 is a future date (%2). Approval submission is blocked because the agreement is not considered signed.', Comment = '%1 = Agreement No., %2 = Signed Date.';
        AlreadyOpenErr: Label 'Rebate Agreement %1 already has an open approval request. Cancel it before submitting again.', Comment = '%1 = Agreement No.';
        PendingApprovalErr: Label 'Rebate Agreement %1 has an open approval request pending. Wait for the approval to complete or cancel it.', Comment = '%1 = Agreement No.';

    /// <summary>
    /// Workflow event code raised by SendForApproval. Custom BC workflows subscribe
    /// to this code to route the agreement through their approver chain.
    /// </summary>
    procedure RBTAgreementSendForApprovalCode(): Code[128]
    begin
        exit('RBTRebateAgreementSendForApproval');
    end;

    /// <summary>
    /// Submits a Draft rebate agreement into the standard BC approval workflow.
    /// Delegates to ApprovalsMgmt.OnSendDocumentForApproval and raises the custom
    /// workflow event via WorkflowManagement.HandleEvent so any subscribed workflow
    /// picks it up. On success flips Status to Pending Approval and stamps the
    /// Sent For Approval Date/By fields via the internal-edit escape hatch.
    /// Signatory Code and Signed Date are enforced BEFORE any workflow call.
    /// </summary>
    procedure SendForApproval(var Agreement: Record "RBT Rebate Agreement")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowManagement: Codeunit "Workflow Management";
        AuditMgt: Codeunit "RBT Audit Mgt.";
        OpenApprovalEntry: Record "Approval Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        RecRef: RecordRef;
        OldStatus: Text;
    begin
        Agreement.Find();

        // Signatory enforcement - blocks submission of unsigned agreements.
        if Agreement."Signatory Code" = '' then
            Error(SignatoryMissingErr, Agreement."No.");
        if Agreement."Signed Date" = 0D then
            Error(SignedDateMissingErr, Agreement."No.");
        if Agreement."Signed Date" > WorkDate() then
            Error(SignedDateFutureErr, Agreement."No.", Format(Agreement."Signed Date"));

        if Agreement.Status <> Agreement.Status::Draft then
            Error(InvalidStatusForSendErr, Agreement."No.", Format(Agreement.Status));

        // Capture the current status label BEFORE the transition so the audit trail
        // records the true prior state (not the post-modify value).
        OldStatus := Format(Agreement.Status);

        // Guard against duplicate open approval requests.
        OpenApprovalEntry.SetRange("Table ID", Database::"RBT Rebate Agreement");
        OpenApprovalEntry.SetRange("Record ID to Approve", Agreement.RecordId());
        OpenApprovalEntry.SetFilter(Status, '%1|%2', OpenApprovalEntry.Status::Open, OpenApprovalEntry.Status::Created);
        if not OpenApprovalEntry.IsEmpty() then
            Error(AlreadyOpenErr, Agreement."No.");

        RecRef.GetTable(Agreement);

        // Raise the custom workflow event so any workflow subscribed to the RBT event
        // code picks up this specific agreement. The workflow response creates
        // approval entries; SendApprovalRequestFromRecord transitions them to Open.
        WorkflowManagement.HandleEvent(RBTAgreementSendForApprovalCode(), Agreement);

        // Standard BC approval submission - transitions any Created approval entries
        // for this record to Open status. If no workflow response created entries this
        // is a safe no-op and the direct-approval fallback (Approve()) can be used.
        ApprovalsMgmt.SendApprovalRequestFromRecord(RecRef, WorkflowStepInstance);

        // Stamp workflow tracking fields through the internal-edit escape hatch to
        // avoid triggering the versioning OnModify guard.
        Agreement.SetAllowInternalEdit(true);
        Agreement.Status := Agreement.Status::"Pending Approval";
        Agreement."Sent For Approval Date" := CurrentDateTime();
        Agreement."Sent For Approval By" := CopyStr(UserId(), 1, MaxStrLen(Agreement."Sent For Approval By"));
        Agreement.Modify(false);
        Agreement.SetAllowInternalEdit(false);

        // Audit trail: business-critical Status change on the Rebate Agreement.
        AuditMgt.LogSentForApproval(Agreement."No.", Database::"RBT Rebate Agreement", OldStatus, Format(Agreement.Status));
    end;

    /// <summary>
    /// Recalls a pending approval request via ApprovalsMgmt.OnCancelDocumentApprovalRequest
    /// and returns the agreement to Draft. Safe no-op if no approval entry exists.
    /// </summary>
    procedure CancelApprovalRequest(var Agreement: Record "RBT Rebate Agreement")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        AuditMgt: Codeunit "RBT Audit Mgt.";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        RecRef: RecordRef;
        OldStatus: Text;
    begin
        Agreement.Find();

        if Agreement.Status <> Agreement.Status::"Pending Approval" then
            Error(InvalidStatusForCancelErr, Agreement."No.", Format(Agreement.Status));

        OldStatus := Format(Agreement.Status);

        RecRef.GetTable(Agreement);

        // Standard BC cancel entry point - cancels any active approval entries for the record.
        ApprovalsMgmt.CancelApprovalRequestsForRecord(RecRef, WorkflowStepInstance);

        // Also explicitly cancel any dangling approval entries in Open/Created.
        ApprovalEntry.SetRange("Table ID", Database::"RBT Rebate Agreement");
        ApprovalEntry.SetRange("Record ID to Approve", Agreement.RecordId());
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        if not ApprovalEntry.IsEmpty() then
            ApprovalsMgmt.CancelApprovalRequestsForRecord(RecRef, WorkflowStepInstance);

        Agreement.SetAllowInternalEdit(true);
        Agreement.Status := Agreement.Status::Draft;
        Clear(Agreement."Sent For Approval Date");
        Agreement."Sent For Approval By" := '';
        Agreement.Modify(false);
        Agreement.SetAllowInternalEdit(false);

        // Audit trail: business-critical Status change on the Rebate Agreement.
        AuditMgt.LogApprovalCancelled(Agreement."No.", Database::"RBT Rebate Agreement", OldStatus, Format(Agreement.Status));
    end;

    /// <summary>
    /// Direct-approval fallback used when no workflow is configured (per the platform
    /// Approval Workflow rule). Flips Pending Approval -> Approved and stamps
    /// Approved Date/By.
    /// </summary>
    procedure Approve(var Agreement: Record "RBT Rebate Agreement")
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        OldStatus: Text;
    begin
        Agreement.Find();

        if Agreement.Status <> Agreement.Status::"Pending Approval" then
            Error(InvalidStatusForApproveErr, Agreement."No.", Format(Agreement.Status));

        OldStatus := Format(Agreement.Status);

        Agreement.SetAllowInternalEdit(true);
        Agreement.Status := Agreement.Status::Approved;
        Agreement."Approved Date" := CurrentDateTime();
        Agreement."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Agreement."Approved By"));
        Agreement.Modify(false);
        Agreement.SetAllowInternalEdit(false);

        // Audit trail: business-critical Status change on the Rebate Agreement.
        AuditMgt.LogApproved(Agreement."No.", Database::"RBT Rebate Agreement", OldStatus, Format(Agreement.Status));
    end;

    /// <summary>
    /// Guard used by the activation flow / posting flow. Errors if an open approval
    /// entry exists so the caller cannot bypass the workflow.
    /// </summary>
    procedure PrePostApprovalCheck(var Agreement: Record "RBT Rebate Agreement")
    var
        OpenApprovalEntry: Record "Approval Entry";
    begin
        OpenApprovalEntry.SetRange("Table ID", Database::"RBT Rebate Agreement");
        OpenApprovalEntry.SetRange("Record ID to Approve", Agreement.RecordId());
        OpenApprovalEntry.SetFilter(Status, '%1|%2', OpenApprovalEntry.Status::Open, OpenApprovalEntry.Status::Created);
        if not OpenApprovalEntry.IsEmpty() then
            Error(PendingApprovalErr, Agreement."No.");
        if Agreement.Status = Agreement.Status::"Pending Approval" then
            Error(PendingApprovalErr, Agreement."No.");
    end;
}
