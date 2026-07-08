codeunit 50306 "BSB Rule Engine"
{
    procedure Calculate(Rule: Record "BSB Rebate Rule"; BasisAmount: Decimal; Quantity: Decimal): Decimal
    var
        Threshold: Record "BSB Threshold";
        Result: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCalculate(Rule, BasisAmount, Quantity, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Threshold.SetRange("Agreement No.", Rule."Agreement No.");
        Threshold.SetRange("Rule No.", Rule."Rule No.");
        if Threshold.FindFirst() then
            case Rule."Calc Method" of
                Rule."Calc Method"::"Fixed Amount",
                Rule."Calc Method"::"Slab Amount":
                    Result := Threshold.Amount;
                Rule."Calc Method"::Percentage,
                Rule."Calc Method"::"Tiered Percentage",
                Rule."Calc Method"::Growth:
                    Result := BasisAmount * Threshold.Rate / 100;
                else
                    Result := 0;
            end
        else
            Result := 0;

        OnAfterCalculate(Rule, BasisAmount, Quantity, Result);
        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(Rule: Record "BSB Rebate Rule"; BasisAmount: Decimal; Quantity: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(Rule: Record "BSB Rebate Rule"; BasisAmount: Decimal; Quantity: Decimal; Result: Decimal)
    begin
    end;
}
