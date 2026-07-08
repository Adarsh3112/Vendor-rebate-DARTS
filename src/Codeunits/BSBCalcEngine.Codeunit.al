codeunit 50307 "BSB Calc Engine"
{
    procedure RunCalculation(var Request: Record "BSB Calc Request")
    var
        Agreement: Record "BSB Agreement";
        Rule: Record "BSB Rebate Rule";
        CalcEntry: Record "BSB Calc Entry";
        AccrualEntry: Record "BSB Accrual Entry";
        RuleEngine: Codeunit "BSB Rule Engine";
        EligibilityEngine: Codeunit "BSB Eligibility Engine";
        AuditMgt: Codeunit "BSB Audit Mgt";
        KeyValue: Code[100];
    begin
        if Request."Request No." = '' then
            Error('Calculation request number is required.');
        if Request.Status = Request.Status::Completed then
            exit;

        Request.Status := Request.Status::Running;
        Request."Started At" := CurrentDateTime();
        Request.Modify(true);

        Agreement.SetRange(Status, Agreement.Status::Active);
        if Request."Agreement No." <> '' then
            Agreement.SetRange("No.", Request."Agreement No.");
        if Agreement.FindSet() then
            repeat
                Rule.SetRange("Agreement No.", Agreement."No.");
                Rule.SetRange(Active, true);
                if Rule.FindSet() then
                    repeat
                        KeyValue := CopyStr(StrSubstNo('%1|%2|%3|%4', Request."Request No.", Agreement."No.", Agreement."Current Version", Rule."Rule No."), 1, 100);
                        CalcEntry.SetRange("Idempotency Key", KeyValue);
                        if not CalcEntry.FindFirst() then begin
                            CalcEntry.Init();
                            CalcEntry."Request No." := Request."Request No.";
                            CalcEntry."Source Company" := CopyStr(CompanyName(), 1, MaxStrLen(CalcEntry."Source Company"));
                            CalcEntry."Source Doc. Type" := 'SYNTHETIC';
                            CalcEntry."Source Doc. No." := Agreement."No.";
                            CalcEntry."Source Line No." := Rule.Priority;
                            CalcEntry."Agreement No." := Agreement."No.";
                            CalcEntry."Version No." := Agreement."Current Version";
                            CalcEntry."Rule No." := Rule."Rule No.";
                            CalcEntry."Basis Amount" := 1000;
                            CalcEntry.Quantity := 1;
                            CalcEntry."Currency Code" := Rule."Currency Code";
                            CalcEntry."Exchange Rate" := 1;
                            CalcEntry."Idempotency Key" := KeyValue;
                            EligibilityEngine.Evaluate(CalcEntry);
                            if CalcEntry."Eligibility Status" = CalcEntry."Eligibility Status"::Eligible then
                                CalcEntry."Calculated Amount" := RuleEngine.Calculate(Rule, CalcEntry."Basis Amount", CalcEntry.Quantity);
                            CalcEntry.Insert(true);

                            if CalcEntry."Eligibility Status" = CalcEntry."Eligibility Status"::Eligible then begin
                                AccrualEntry.Init();
                                AccrualEntry."Calc Entry No." := CalcEntry."Entry No.";
                                AccrualEntry."Agreement No." := Agreement."No.";
                                AccrualEntry."Version No." := Agreement."Current Version";
                                AccrualEntry.Company := CalcEntry."Source Company";
                                AccrualEntry."Party Type" := Agreement."Agreement Type";
                                AccrualEntry."Party No." := Agreement."Vendor No.";
                                if AccrualEntry."Party No." = '' then
                                    AccrualEntry."Party No." := Agreement."Customer No.";
                                AccrualEntry.Period := CopyStr(Format(Request."Date From", 0, 9), 1, MaxStrLen(AccrualEntry.Period));
                                AccrualEntry.Amount := CalcEntry."Calculated Amount";
                                AccrualEntry."Open Amount" := AccrualEntry.Amount;
                                AccrualEntry."Currency Code" := CalcEntry."Currency Code";
                                AccrualEntry."Exchange Rate" := CalcEntry."Exchange Rate";
                                AccrualEntry.Status := AccrualEntry.Status::Open;
                                AccrualEntry."Idempotency Key" := KeyValue;
                                AccrualEntry.Insert(true);
                            end;
                        end;
                    until Rule.Next() = 0;
            until Agreement.Next() = 0;

        Request.Status := Request.Status::Completed;
        Request."Completed At" := CurrentDateTime();
        Request.Modify(true);
        AuditMgt.Log('Calculation Completed', Request."Request No.", '', Format(Request.Status), '', Request."Request No.", '');
    end;
}
