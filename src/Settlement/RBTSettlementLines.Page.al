page 50113 "RBT Settlement Lines"
{
    PageType = ListPart;
    SourceTable = "RBT Settlement Line";
    Caption = 'Settlement Lines';
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Accrual Entry No."; Rec."Accrual Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
