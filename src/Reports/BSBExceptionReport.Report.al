report 50403 "BSB Exception Report"
{
    Caption = 'Rebate Exception Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(ErrorEntry; "BSB Error Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(Category; Category) { }
            column(UserMessage; "User Message") { }
            column(RelatedRecord; "Related Record") { }
            column(RetryEligible; "Retry Eligible") { }
            column(Status; Status) { }
        }
    }
}
