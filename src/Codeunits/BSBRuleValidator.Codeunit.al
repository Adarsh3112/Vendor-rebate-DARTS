codeunit 50302 "BSB Rule Validator"
{
    procedure ValidateRules(AgreementNo: Code[20])
    var
        Rule: Record "BSB Rebate Rule";
        Threshold: Record "BSB Threshold";
        FoundRule: Boolean;
    begin
        Rule.SetRange("Agreement No.", AgreementNo);
        if Rule.FindSet() then
            repeat
                FoundRule := true;
                if Rule."Rule No." = '' then
                    Error('Rule number is required for agreement %1.', AgreementNo);
                if Rule."Effective To" <> 0D then
                    if Rule."Effective From" > Rule."Effective To" then
                        Error('Rule %1 has invalid effective dates.', Rule."Rule No.");

                Threshold.SetRange("Agreement No.", Rule."Agreement No.");
                Threshold.SetRange("Rule No.", Rule."Rule No.");
                if Threshold.FindSet() then
                    repeat
                        if Threshold."To Value" <> 0 then
                            if Threshold."From Value" > Threshold."To Value" then
                                Error('Threshold %1 for rule %2 has invalid range.', Threshold."Threshold No.", Rule."Rule No.");
                    until Threshold.Next() = 0;
            until Rule.Next() = 0;

        if not FoundRule then
            Error('At least one rebate rule is required for agreement %1.', AgreementNo);
    end;
}
