report 50402 "BSB Recalc Audit"
{
    Caption = 'Rebate Recalculation Audit';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Recalc; "BSB Recalc Result")
        {
            column(ResultNo; "Result No.") { }
            column(RequestNo; "Request No.") { }
            column(OriginalEntryNo; "Original Entry No.") { }
            column(AgreementNo; "Agreement No.") { }
            column(OldAmount; "Old Amount") { }
            column(NewAmount; "New Amount") { }
            column(DeltaAmount; "Delta Amount") { }
            column(AdjustmentStatus; "Adjustment Status") { }
        }
    }
}
