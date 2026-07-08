codeunit 50303 "BSB Agreement Mgt"
{
    procedure ValidateAgreement(var Agreement: Record "BSB Agreement")
    var
        PostingSetup: Record "BSB Posting Setup";
        RuleValidator: Codeunit "BSB Rule Validator";
        IsHandled: Boolean;
    begin
        OnBeforeValidateAgreement(Agreement, IsHandled);
        if IsHandled then
            exit;

        if Agreement."No." = '' then
            Error('Agreement number is required.');
        if Agreement."Valid From" = 0D then
            Error('Valid From is required for agreement %1.', Agreement."No.");
        if Agreement."Valid To" = 0D then
            Error('Valid To is required for agreement %1.', Agreement."No.");
        if Agreement."Valid From" > Agreement."Valid To" then
            Error('Validity dates are invalid for agreement %1.', Agreement."No.");
        if Agreement."Posting Group" = '' then
            Error('Posting group is required for agreement %1.', Agreement."No.");
        if not PostingSetup.Get(Agreement."Posting Group", Agreement."Agreement Type") then
            Error('Posting setup is missing for posting group %1 and agreement type %2.', Agreement."Posting Group", Agreement."Agreement Type");
        if (Agreement."Vendor No." = '') and (Agreement."Customer No." = '') and (Agreement."Customer Group" = '') then
            Error('At least one party scope is required for agreement %1.', Agreement."No.");

        RuleValidator.ValidateRules(Agreement."No.");
        OnAfterValidateAgreement(Agreement);
    end;

    procedure SubmitForApproval(var Agreement: Record "BSB Agreement")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if Agreement.Status <> Agreement.Status::Draft then
            Error('Only draft agreements can be submitted.');
        Agreement.Status := Agreement.Status::"Pending Approval";
        Agreement."Approval Status" := Agreement."Approval Status"::"Pending Approval";
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Submitted', Agreement."No.", '', Format(Agreement.Status), Agreement."Reason Code", Agreement."No.", '');
    end;

    procedure Approve(var Agreement: Record "BSB Agreement")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Agreement.Status := Agreement.Status::Approved;
        Agreement."Approval Status" := Agreement."Approval Status"::Approved;
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Approved', Agreement."No.", '', Format(Agreement.Status), Agreement."Reason Code", Agreement."No.", '');
    end;

    procedure Activate(var Agreement: Record "BSB Agreement")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if Agreement."Approval Status" <> Agreement."Approval Status"::Approved then
            Error('Agreement %1 must be approved before activation.', Agreement."No.");
        ValidateAgreement(Agreement);
        CreateVersion(Agreement);
        Agreement.Status := Agreement.Status::Active;
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Activated', Agreement."No.", '', Format(Agreement.Status), Agreement."Reason Code", Agreement."No.", '');
    end;

    procedure CreateVersion(var Agreement: Record "BSB Agreement")
    var
        Version: Record "BSB Agr Version";
        AuditMgt: Codeunit "BSB Audit Mgt";
        NextVersion: Integer;
    begin
        OnBeforeCreateVersion(Agreement);
        Version.SetRange("Agreement No.", Agreement."No.");
        if Version.FindLast() then
            NextVersion := Version."Version No." + 1
        else
            NextVersion := 1;

        Version.Init();
        Version."Agreement No." := Agreement."No.";
        Version."Version No." := NextVersion;
        Version."Effective Date" := Agreement."Valid From";
        Version."Created At" := CurrentDateTime();
        Version."Created By" := CopyStr(UserId(), 1, MaxStrLen(Version."Created By"));
        Version."Change Reason" := Agreement."Reason Code";
        Version."Term Summary" := CopyStr(StrSubstNo('%1 %2 %3..%4', Agreement."Agreement Type", Agreement."Posting Group", Agreement."Valid From", Agreement."Valid To"), 1, MaxStrLen(Version."Term Summary"));
        Version.Status := Agreement.Status;
        Version.Insert(true);

        Agreement."Current Version" := NextVersion;
        Agreement."Last Version At" := CurrentDateTime();
        AuditMgt.Log('Agreement Versioned', Agreement."No.", '', Format(NextVersion), Agreement."Reason Code", Agreement."No.", '');
    end;

    procedure Suspend(var Agreement: Record "BSB Agreement"; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Agreement.Status := Agreement.Status::Suspended;
        Agreement."Reason Code" := ReasonCode;
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Suspended', Agreement."No.", '', Format(Agreement.Status), ReasonCode, Agreement."No.", '');
    end;

    procedure Expire(var Agreement: Record "BSB Agreement"; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Agreement.Status := Agreement.Status::Expired;
        Agreement."Reason Code" := ReasonCode;
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Expired', Agreement."No.", '', Format(Agreement.Status), ReasonCode, Agreement."No.", '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAgreement(var Agreement: Record "BSB Agreement"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAgreement(var Agreement: Record "BSB Agreement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVersion(var Agreement: Record "BSB Agreement")
    begin
    end;
}
