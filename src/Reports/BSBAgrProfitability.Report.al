report 50404 "BSB Agr Profitability"
{
    Caption = 'Rebate Agreement Profitability';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(CalcEntry; "BSB Calc Entry")
        {
            column(AgreementNo; "Agreement No.") { }
            column(VersionNo; "Version No.") { }
            column(RuleNo; "Rule No.") { }
            column(BasisAmount; "Basis Amount") { }
            column(CalculatedAmount; "Calculated Amount") { }
            column(CurrencyCode; "Currency Code") { }
        }
    }
}
