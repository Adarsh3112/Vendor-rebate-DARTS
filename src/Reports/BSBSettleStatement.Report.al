report 50405 "BSB Settle Statement"
{
    Caption = 'Rebate Settlement Statement';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Settlement; "BSB Settlement Hdr")
        {
            column(SettlementNo; "Settlement No.") { }
            column(AgreementNo; "Agreement No.") { }
            column(PartyNo; "Party No.") { }
            column(Period; Period) { }
            column(TotalAmount; "Total Amount") { }
            column(AdjustmentAmount; "Adjustment Amount") { }
            column(Posted; Posted) { }
        }
    }
}
