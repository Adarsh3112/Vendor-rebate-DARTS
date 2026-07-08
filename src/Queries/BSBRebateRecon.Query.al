query 50450 "BSB Rebate Recon"
{
    Caption = 'Rebate Reconciliation';
    QueryType = Normal;

    elements
    {
        dataitem(Accrual; "BSB Accrual Entry")
        {
            column(Agreement_No_; "Agreement No.") { }
            column(Period; Period) { }
            column(Currency_Code; "Currency Code") { }
            column(Status; Status) { }
            column(Amount; Amount) { Method = Sum; }
            column(Open_Amount; "Open Amount") { Method = Sum; }
        }
    }
}
