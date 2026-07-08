page 50201 "BSB Posting Setup"
{
    PageType = List;
    SourceTable = "BSB Posting Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Rebate Posting Setup';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field("Accrual Account"; Rec."Accrual Account") { ApplicationArea = All; }
                field("Offset Account"; Rec."Offset Account") { ApplicationArea = All; }
                field("Settlement Account"; Rec."Settlement Account") { ApplicationArea = All; }
                field("Dimension Policy"; Rec."Dimension Policy") { ApplicationArea = All; }
                field("Currency Policy"; Rec."Currency Policy") { ApplicationArea = All; }
                field("Allow Reversal"; Rec."Allow Reversal") { ApplicationArea = All; }
            }
        }
    }
}
