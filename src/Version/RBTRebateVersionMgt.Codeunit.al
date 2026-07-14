codeunit 50119 "RBT Rebate Version Mgt."
{
    var
        AlreadyActiveErr: Label 'Rebate Agreement %1 is already Active. Activation can only be performed once from Draft or Approved.';
        CannotActivateFromStatusErr: Label 'Rebate Agreement %1 cannot be activated from status %2. Set the agreement to Draft or Approved first on the RBT Rebate Agreement Card.';
        NoCurrentVersionErr: Label 'Rebate Agreement %1 has no current version. Activate the agreement to create the first version.';
        ActivatedMsg: Label 'Rebate Agreement %1 has been activated. Version 1 has been created.';
        NewVersionCreatedMsg: Label 'A new version (%1) has been created for Rebate Agreement %2 because the Active agreement was modified.';
        SignatoryMissingErr: Label 'Signatory Code is missing on agreement %1. Fill in the Signatory Code (User Setup) on the RBT Rebate Agreement Card before activation.', Comment = '%1 = Agreement No.';
        SignedDateMissingErr: Label 'Signed Date is missing on agreement %1. Fill in the Signed Date on the RBT Rebate Agreement Card before activation.', Comment = '%1 = Agreement No.';
        SignedDateFutureErr: Label 'Signed Date on agreement %1 is a future date (%2). Activation is blocked because the agreement is not considered signed. Correct the Signed Date on the RBT Rebate Agreement Card.', Comment = '%1 = Agreement No., %2 = Signed Date';
        PendingApprovalErr: Label 'Rebate Agreement %1 has an open approval request. Wait for the approval to complete or cancel it before activation.', Comment = '%1 = Agreement No.';

    /// <summary>
    /// Activates a rebate agreement and creates Version 1 as the initial version.
    /// Must be called from the Rebate Agreement Card action, never bypassed by direct Status = Active writes.
    ///
    /// Enforces signatory rules as the ABSOLUTE FIRST operations:
    ///  1. Signatory Code must be non-blank.
    ///  2. Signed Date must be non-blank.
    ///  3. Signed Date must not be in the future.
    /// Any of these failing aborts activation with an actionable error before any
    /// status change, side-effect, or version insert.
    /// </summary>
    procedure ActivateAgreement(var RebateAgreement: Record "RBT Rebate Agreement")
    var
        ExistingVersion: Record "RBT Rebate Version";
        OpenApprovalEntry: Record "Approval Entry";
        AuditMgt: Codeunit "RBT Audit Mgt.";
        InitialVersionNo: Integer;
        OldStatus: Text;
    begin
        RebateAgreement.Find();

        // (A) Signatory enforcement - FIRST operations, before any status or side-effect.
        if RebateAgreement."Signatory Code" = '' then
            Error(SignatoryMissingErr, RebateAgreement."No.");
        if RebateAgreement."Signed Date" = 0D then
            Error(SignedDateMissingErr, RebateAgreement."No.");
        if RebateAgreement."Signed Date" > WorkDate() then
            Error(SignedDateFutureErr, RebateAgreement."No.", Format(RebateAgreement."Signed Date"));

        // (B) Status guards.
        if RebateAgreement.Status = RebateAgreement.Status::Active then
            Error(AlreadyActiveErr, RebateAgreement."No.");

        if not (RebateAgreement.Status in
            [RebateAgreement.Status::Draft, RebateAgreement.Status::Approved])
        then
            Error(CannotActivateFromStatusErr, RebateAgreement."No.", Format(RebateAgreement.Status));

        // (C) Approval workflow guard - if an open Approval Entry exists, the agreement
        //     must be routed through the approval workflow before it can be activated.
        OpenApprovalEntry.SetRange("Table ID", Database::"RBT Rebate Agreement");
        OpenApprovalEntry.SetRange("Record ID to Approve", RebateAgreement.RecordId());
        OpenApprovalEntry.SetFilter(Status, '%1|%2', OpenApprovalEntry.Status::Open, OpenApprovalEntry.Status::Created);
        if not OpenApprovalEntry.IsEmpty() then
            Error(PendingApprovalErr, RebateAgreement."No.");

        // Capture the current status label BEFORE the transition so the audit trail
        // records the true prior state (Draft or Approved).
        OldStatus := Format(RebateAgreement.Status);

        // Set status first so the version snapshot captures the Active state.
        RebateAgreement.SetAllowInternalEdit(true);
        RebateAgreement.Status := RebateAgreement.Status::Active;
        RebateAgreement.Modify(false);
        RebateAgreement.SetAllowInternalEdit(false);

        // If a previous version somehow exists (re-activation flow), calculate next; otherwise create Version 1.
        ExistingVersion.SetRange("Agreement No.", RebateAgreement."No.");
        if ExistingVersion.FindLast() then
            InitialVersionNo := ExistingVersion."Version No." + 1
        else
            InitialVersionNo := 1;

        MarkCurrentVersionsInactive(RebateAgreement."No.");
        InsertVersion(RebateAgreement, InitialVersionNo, 'Initial activation');

        // Audit trail: business-critical Status change (Draft/Approved -> Active).
        AuditMgt.LogActivated(RebateAgreement."No.", Database::"RBT Rebate Agreement", OldStatus, Format(RebateAgreement.Status));

        Message(ActivatedMsg, RebateAgreement."No.");
    end;

    /// <summary>
    /// Called from the Rebate Agreement table OnModify trigger.
    /// When an Active agreement is edited, snapshots the new state as a new version.
    /// </summary>
    procedure HandleAgreementModify(var NewRec: Record "RBT Rebate Agreement"; var OldRec: Record "RBT Rebate Agreement")
    var
        NewVersionNo: Integer;
    begin
        // Only enforce versioning for Active agreements.
        if NewRec.Status <> NewRec.Status::Active then
            exit;

        // If the record itself was flipped from something else to Active, ActivateAgreement handled it.
        // Skip creating an extra version for the same activation transition.
        if OldRec.Status <> OldRec.Status::Active then
            exit;

        if not HasFieldsChanged(NewRec, OldRec) then
            exit;

        NewVersionNo := GetNextVersionNo(NewRec."No.");
        MarkCurrentVersionsInactive(NewRec."No.");
        InsertVersion(NewRec, NewVersionNo, BuildChangeDescription(NewRec, OldRec));

        Message(NewVersionCreatedMsg, NewVersionNo, NewRec."No.");
    end;

    /// <summary>
    /// Public helper to create an explicit new version (used by other flows such as rule edits).
    /// </summary>
    procedure CreateNextVersion(var RebateAgreement: Record "RBT Rebate Agreement"; ChangeDescription: Text[250]): Integer
    var
        NextVersionNo: Integer;
    begin
        if RebateAgreement.Status <> RebateAgreement.Status::Active then
            exit(0);
        NextVersionNo := GetNextVersionNo(RebateAgreement."No.");
        MarkCurrentVersionsInactive(RebateAgreement."No.");
        InsertVersion(RebateAgreement, NextVersionNo, ChangeDescription);
        exit(NextVersionNo);
    end;

    procedure GetCurrentVersion(AgreementNo: Code[20]; var CurrentVersion: Record "RBT Rebate Version"): Boolean
    begin
        CurrentVersion.Reset();
        CurrentVersion.SetRange("Agreement No.", AgreementNo);
        CurrentVersion.SetRange("Is Current", true);
        exit(CurrentVersion.FindFirst());
    end;

    local procedure GetNextVersionNo(AgreementNo: Code[20]): Integer
    var
        Version: Record "RBT Rebate Version";
    begin
        Version.SetRange("Agreement No.", AgreementNo);
        if Version.FindLast() then
            exit(Version."Version No." + 1);
        exit(1);
    end;

    local procedure MarkCurrentVersionsInactive(AgreementNo: Code[20])
    var
        Version: Record "RBT Rebate Version";
    begin
        Version.SetRange("Agreement No.", AgreementNo);
        Version.SetRange("Is Current", true);
        if Version.FindSet() then
            repeat
                Version.SetAllowInternalEdit(true);
                Version."Is Current" := false;
                Version.Modify(false);
                Version.SetAllowInternalEdit(false);
            until Version.Next() = 0;
    end;

    local procedure InsertVersion(var RebateAgreement: Record "RBT Rebate Agreement"; VersionNo: Integer; ChangeDescription: Text[250])
    var
        Version: Record "RBT Rebate Version";
        EffectiveDate: Date;
    begin
        EffectiveDate := WorkDate();
        if RebateAgreement."Start Date" > EffectiveDate then
            EffectiveDate := RebateAgreement."Start Date";

        Version.Init();
        Version."Agreement No." := RebateAgreement."No.";
        Version."Version No." := VersionNo;
        Version."Is Current" := true;
        Version."Effective From" := EffectiveDate;
        Version."Created At" := CurrentDateTime();
        Version."Created By" := CopyStr(UserId(), 1, MaxStrLen(Version."Created By"));
        Version."Change Description" := ChangeDescription;
        Version."Agreement Status Snapshot" := RebateAgreement.Status;
        Version."Start Date Snapshot" := RebateAgreement."Start Date";
        Version."End Date Snapshot" := RebateAgreement."End Date";
        Version."Description Snapshot" := RebateAgreement.Description;
        Version.Insert();
    end;

    local procedure HasFieldsChanged(NewRec: Record "RBT Rebate Agreement"; OldRec: Record "RBT Rebate Agreement"): Boolean
    begin
        if NewRec.Description <> OldRec.Description then exit(true);
        if NewRec."Vendor No." <> OldRec."Vendor No." then exit(true);
        if NewRec."Customer No." <> OldRec."Customer No." then exit(true);
        if NewRec."Start Date" <> OldRec."Start Date" then exit(true);
        if NewRec."End Date" <> OldRec."End Date" then exit(true);
        if NewRec."Currency Code" <> OldRec."Currency Code" then exit(true);
        if NewRec."Posting Group" <> OldRec."Posting Group" then exit(true);
        if NewRec."Type" <> OldRec."Type" then exit(true);
        exit(false);
    end;

    local procedure BuildChangeDescription(NewRec: Record "RBT Rebate Agreement"; OldRec: Record "RBT Rebate Agreement"): Text[250]
    var
        Buf: Text;
    begin
        if NewRec.Description <> OldRec.Description then
            Buf += 'Description; ';
        if NewRec."Vendor No." <> OldRec."Vendor No." then
            Buf += 'Vendor No.; ';
        if NewRec."Customer No." <> OldRec."Customer No." then
            Buf += 'Customer No.; ';
        if NewRec."Start Date" <> OldRec."Start Date" then
            Buf += 'Start Date; ';
        if NewRec."End Date" <> OldRec."End Date" then
            Buf += 'End Date; ';
        if NewRec."Currency Code" <> OldRec."Currency Code" then
            Buf += 'Currency Code; ';
        if NewRec."Posting Group" <> OldRec."Posting Group" then
            Buf += 'Posting Group; ';
        if NewRec."Type" <> OldRec."Type" then
            Buf += 'Type; ';
        if Buf = '' then
            Buf := 'Modification while Active';
        exit(CopyStr('Modified: ' + Buf, 1, 250));
    end;
}
