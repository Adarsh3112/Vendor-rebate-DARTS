page 50213 "BSB Recalc Results"
{
    PageType = List;
    SourceTable = "BSB Recalc Result";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Recalculation Results';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Result No."; Rec."Result No.") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Original Entry No."; Rec."Original Entry No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Old Amount"; Rec."Old Amount") { ApplicationArea = All; }
                field("New Amount"; Rec."New Amount") { ApplicationArea = All; }
                field("Delta Amount"; Rec."Delta Amount") { ApplicationArea = All; }
                field("Adjustment Status"; Rec."Adjustment Status") { ApplicationArea = All; }
                field("Posting Ref."; Rec."Posting Ref.") { ApplicationArea = All; }
            }
        }
    }
}
