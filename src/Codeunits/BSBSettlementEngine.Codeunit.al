codeunit 50310 "BSB Settlement Engine"
{
    procedure CreateProposal(SettlementNo: Code[20]; AgreementNo: Code[20])
    var
        Header: Record "BSB Settlement Hdr";
        Line: Record "BSB Settlement Line";
        Accrual: Record "BSB Accrual Entry";
        LineNo: Integer;
        TotalAmount: Decimal;
    begin
        if Header.Get(SettlementNo) then
            Error('Settlement proposal %1 already exists.', SettlementNo);
        Header.Init();
        Header."Settlement No." := SettlementNo;
        Header.Status := Header.Status::Open;
        Header."Agreement No." := AgreementNo;
        Header."Approval Status" := Header."Approval Status"::Open;
        Header.Insert(true);

        Accrual.SetRange("Agreement No.", AgreementNo);
        Accrual.SetRange(Status, Accrual.Status::Posted);
        if Accrual.FindSet() then
            repeat
                LineNo += 10000;
                Line.Init();
                Line."Settlement No." := SettlementNo;
                Line."Line No." := LineNo;
                Line."Accrual Entry No." := Accrual."Entry No.";
                Line.Amount := Accrual."Open Amount";
                Line.Insert(true);
                TotalAmount += Line.Amount;
            until Accrual.Next() = 0;

        Header."Total Amount" := TotalAmount;
        Header.Modify(true);
        OnAfterCreateProposal(Header);
    end;

    procedure PostSettlement(var Header: Record "BSB Settlement Hdr")
    var
        Line: Record "BSB Settlement Line";
        Accrual: Record "BSB Accrual Entry";
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if Header."Approval Status" <> Header."Approval Status"::Approved then
            Error('Settlement %1 must be approved before posting.', Header."Settlement No.");
        if Header.Posted then
            Error('Settlement %1 is already posted.', Header."Settlement No.");

        OnBeforePostSettlement(Header);
        Line.SetRange("Settlement No.", Header."Settlement No.");
        if Line.FindSet() then
            repeat
                if Accrual.Get(Line."Accrual Entry No.") then begin
                    Accrual.Status := Accrual.Status::Settled;
                    Accrual."Open Amount" := 0;
                    Accrual.Modify(true);
                    Line.Closed := true;
                    Line.Modify(true);
                end;
            until Line.Next() = 0;

        Header.Posted := true;
        Header.Status := Header.Status::Completed;
        Header.Modify(true);
        AuditMgt.Log('Settlement Posted', Header."Settlement No.", '', Format(Header."Total Amount"), '', Header."Agreement No.", '');
        OnAfterPostSettlement(Header);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateProposal(var Header: Record "BSB Settlement Hdr")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSettlement(var Header: Record "BSB Settlement Hdr")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSettlement(var Header: Record "BSB Settlement Hdr")
    begin
    end;
}
