report 50401 "BSB Recon Report"
{
    Caption = 'Rebate Reconciliation Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Accrual; "BSB Accrual Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(CalcEntryNo; "Calc Entry No.") { }
            column(AgreementNo; "Agreement No.") { }
            column(Amount; Amount) { }
            column(OpenAmount; "Open Amount") { }
            column(PostingRef; "Posting Ref.") { }
            column(Status; Status) { }
        }
    }
}
