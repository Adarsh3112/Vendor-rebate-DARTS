codeunit 50305 "BSB Eligibility Engine"
{
    procedure Evaluate(var CalcEntry: Record "BSB Calc Entry")
    var
        IsHandled: Boolean;
    begin
        OnBeforeEvaluate(CalcEntry, IsHandled);
        if IsHandled then
            exit;

        if (CalcEntry."Agreement No." = '') or (CalcEntry."Rule No." = '') then begin
            CalcEntry."Eligibility Status" := CalcEntry."Eligibility Status"::Rejected;
            CalcEntry.Reason := 'Missing agreement or rule';
        end else begin
            CalcEntry."Eligibility Status" := CalcEntry."Eligibility Status"::Eligible;
            CalcEntry.Reason := 'Matched active agreement rule';
        end;

        OnAfterEvaluate(CalcEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluate(var CalcEntry: Record "BSB Calc Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluate(var CalcEntry: Record "BSB Calc Entry")
    begin
    end;
}
