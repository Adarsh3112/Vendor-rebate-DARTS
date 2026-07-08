codeunit 50309 "BSB Posting Engine"
{
    procedure PreviewAccrual(AccrualEntry: Record "BSB Accrual Entry"): Text[250]
    var
        PreviewText: Text[250];
    begin
        OnBeforePreviewAccrual(AccrualEntry);
        PreviewText := CopyStr(StrSubstNo('Debit/credit preview for accrual %1 amount %2 %3.', AccrualEntry."Entry No.", AccrualEntry.Amount, AccrualEntry."Currency Code"), 1, 250);
        exit(PreviewText);
    end;

    procedure PostAccrual(var AccrualEntry: Record "BSB Accrual Entry")
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if AccrualEntry.Status = AccrualEntry.Status::Posted then
            Error('Accrual entry %1 is already posted.', AccrualEntry."Entry No.");
        OnBeforePostAccrual(AccrualEntry);
        AccrualEntry.Status := AccrualEntry.Status::Posted;
        AccrualEntry."Posting Ref." := CopyStr(StrSubstNo('POST-%1', AccrualEntry."Entry No."), 1, MaxStrLen(AccrualEntry."Posting Ref."));
        AccrualEntry.Modify(true);
        AuditMgt.Log('Accrual Posted', Format(AccrualEntry."Entry No."), '', AccrualEntry."Posting Ref.", '', AccrualEntry."Agreement No.", '');
        OnAfterPostAccrual(AccrualEntry);
    end;

    procedure ReverseAccrual(var AccrualEntry: Record "BSB Accrual Entry"; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if AccrualEntry.Status <> AccrualEntry.Status::Posted then
            Error('Only posted accrual entries can be reversed.');
        AccrualEntry.Status := AccrualEntry.Status::Reversed;
        AccrualEntry."Reversal Ref." := CopyStr(StrSubstNo('REV-%1', AccrualEntry."Entry No."), 1, MaxStrLen(AccrualEntry."Reversal Ref."));
        AccrualEntry."Open Amount" := 0;
        AccrualEntry.Modify(true);
        AuditMgt.Log('Accrual Reversed', Format(AccrualEntry."Entry No."), AccrualEntry."Posting Ref.", AccrualEntry."Reversal Ref.", ReasonCode, AccrualEntry."Agreement No.", '');
    end;

    procedure PostRecalcDelta(var RecalcResult: Record "BSB Recalc Result")
    begin
        if RecalcResult."Delta Amount" = 0 then
            exit;
        RecalcResult."Adjustment Status" := RecalcResult."Adjustment Status"::Posted;
        RecalcResult."Posting Ref." := CopyStr(StrSubstNo('DELTA-%1', RecalcResult."Result No."), 1, MaxStrLen(RecalcResult."Posting Ref."));
        RecalcResult.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreviewAccrual(AccrualEntry: Record "BSB Accrual Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAccrual(var AccrualEntry: Record "BSB Accrual Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAccrual(var AccrualEntry: Record "BSB Accrual Entry")
    begin
    end;
}
