page 50209 "BSB Calc Entries"
{
    PageType = List;
    SourceTable = "BSB Calc Entry";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    Caption = 'Rebate Calculation Entries';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Version No."; Rec."Version No.") { ApplicationArea = All; }
                field("Rule No."; Rec."Rule No.") { ApplicationArea = All; }
                field("Eligibility Status"; Rec."Eligibility Status") { ApplicationArea = All; }
                field(Reason; Rec.Reason) { ApplicationArea = All; }
                field("Calculated Amount"; Rec."Calculated Amount") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Exchange Rate"; Rec."Exchange Rate") { ApplicationArea = All; }
            }
        }
    }
}
