report 50400 "BSB Accrual Summary"
{
    Caption = 'Rebate Accrual Summary';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Accrual; "BSB Accrual Entry")
        {
            column(AgreementNo; "Agreement No.") { }
            column(PartyNo; "Party No.") { }
            column(Period; Period) { }
            column(Amount; Amount) { }
            column(OpenAmount; "Open Amount") { }
            column(CurrencyCode; "Currency Code") { }
            column(Status; Status) { }
        }
    }
}
