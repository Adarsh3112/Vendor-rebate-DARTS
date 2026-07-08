codeunit 50304 "BSB Approval Mgt"
{
    procedure RejectAgreement(var Agreement: Record "BSB Agreement"; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Agreement.Status := Agreement.Status::Rejected;
        Agreement."Approval Status" := Agreement."Approval Status"::Rejected;
        Agreement."Reason Code" := ReasonCode;
        Agreement.Modify(true);
        AuditMgt.Log('Agreement Rejected', Agreement."No.", '', Format(Agreement.Status), ReasonCode, Agreement."No.", '');
    end;

    procedure SubmitSettlement(var Settlement: Record "BSB Settlement Hdr")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Settlement.Status := Settlement.Status::Open;
        Settlement."Approval Status" := Settlement."Approval Status"::"Pending Approval";
        Settlement.Modify(true);
        AuditMgt.Log('Settlement Submitted', Settlement."Settlement No.", '', Format(Settlement."Approval Status"), '', Settlement."Settlement No.", '');
    end;

    procedure ApproveSettlement(var Settlement: Record "BSB Settlement Hdr")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Settlement."Approval Status" := Settlement."Approval Status"::Approved;
        Settlement.Modify(true);
        AuditMgt.Log('Settlement Approved', Settlement."Settlement No.", '', Format(Settlement."Approval Status"), '', Settlement."Settlement No.", '');
    end;

    procedure RejectSettlement(var Settlement: Record "BSB Settlement Hdr"; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        Settlement."Approval Status" := Settlement."Approval Status"::Rejected;
        Settlement.Modify(true);
        AuditMgt.Log('Settlement Rejected', Settlement."Settlement No.", '', Format(Settlement."Approval Status"), ReasonCode, Settlement."Settlement No.", '');
    end;

    procedure DelegateSettlement(var Settlement: Record "BSB Settlement Hdr")
    begin
        Settlement."Approval Status" := Settlement."Approval Status"::Delegated;
        Settlement.Modify(true);
    end;

    procedure RequestSettlementChanges(var Settlement: Record "BSB Settlement Hdr")
    begin
        Settlement."Approval Status" := Settlement."Approval Status"::"Changes Requested";
        Settlement.Modify(true);
    end;
}
