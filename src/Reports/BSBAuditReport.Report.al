report 50406 "BSB Audit Report"
{
    Caption = 'Rebate Audit Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(AuditEntry; "BSB Audit Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(DateTime; "Date Time") { }
            column(UserID; "User ID") { }
            column(Action; Action) { }
            column(RecordIDText; "Record ID Text") { }
            column(OldValue; "Old Value") { }
            column(NewValue; "New Value") { }
            column(ReasonCode; "Reason Code") { }
        }
    }
}
