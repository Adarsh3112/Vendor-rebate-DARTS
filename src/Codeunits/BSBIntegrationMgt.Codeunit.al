codeunit 50312 "BSB Integration Mgt"
{
    procedure RegisterMessage(Direction: Enum "BSB Msg Direction"; MessageType: Code[30]; ExternalRefID: Code[80]): Integer
    var
        Message: Record "BSB Integration Msg";
    begin
        Message.SetRange(Direction, Direction);
        Message.SetRange("Message Type", MessageType);
        Message.SetRange("External Ref. ID", ExternalRefID);
        if Message.FindFirst() then
            exit(Message."Message No.");

        Message.Init();
        Message.Direction := Direction;
        Message."Message Type" := MessageType;
        Message."External Ref. ID" := ExternalRefID;
        Message.Status := Message.Status::Open;
        Message."Created At" := CurrentDateTime();
        Message.Insert(true);
        OnAfterRegisterMessage(Message);
        exit(Message."Message No.");
    end;

    procedure ImportAgreement(ExternalRefID: Code[80]; AgreementNo: Code[20])
    var
        Agreement: Record "BSB Agreement";
        MessageNo: Integer;
    begin
        MessageNo := RegisterMessage(Enum::"BSB Msg Direction"::Inbound, 'AGREEMENT', ExternalRefID);
        if not Agreement.Get(AgreementNo) then begin
            Agreement.Init();
            Agreement."No." := AgreementNo;
            Agreement.Status := Agreement.Status::Draft;
            Agreement.Insert(true);
        end;
        CompleteMessage(MessageNo, AgreementNo);
    end;

    procedure CompleteMessage(MessageNo: Integer; RelatedRecord: Text[100])
    var
        Message: Record "BSB Integration Msg";
    begin
        if not Message.Get(MessageNo) then
            Error('Integration message %1 does not exist.', MessageNo);
        Message.Status := Message.Status::Completed;
        Message."Completed At" := CurrentDateTime();
        Message."Related Record" := RelatedRecord;
        Message.Modify(true);
    end;

    procedure FailMessage(MessageNo: Integer; ErrorText: Text[250]; RetryEligible: Boolean)
    var
        Message: Record "BSB Integration Msg";
    begin
        if Message.Get(MessageNo) then begin
            Message.Status := Message.Status::Failed;
            Message."Last Error" := ErrorText;
            if RetryEligible then
                Message."Retry Count" += 1;
            Message.Modify(true);
        end;
    end;

    procedure ExportCalculationStatus(RequestNo: Code[20]): Text[250]
    var
        Request: Record "BSB Calc Request";
    begin
        if Request.Get(RequestNo) then
            exit(CopyStr(StrSubstNo('%1|%2|%3', Request."Request No.", Request.Status, Request."Completed At"), 1, 250));
        exit('Not found');
    end;

    procedure ExportSettlement(SettlementNo: Code[20]): Text[250]
    var
        Settlement: Record "BSB Settlement Hdr";
    begin
        if Settlement.Get(SettlementNo) then
            exit(CopyStr(StrSubstNo('%1|%2|%3', Settlement."Settlement No.", Settlement."Total Amount", Settlement.Posted), 1, 250));
        exit('Not found');
    end;

    procedure ExportAudit(): Text[250]
    var
        AuditEntry: Record "BSB Audit Entry";
    begin
        exit(CopyStr(StrSubstNo('Audit entries: %1', AuditEntry.Count()), 1, 250));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterMessage(var Message: Record "BSB Integration Msg")
    begin
    end;
}
