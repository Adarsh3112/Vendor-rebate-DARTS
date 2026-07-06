page 50110 "RBT Rebate Rule Sub"
{
    PageType = ListPart;
    SourceTable = "RBT Rebate Rule";
    Caption = 'Rules';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Rule No."; Rec."Rule No.") { ApplicationArea = All; }
                field("Calculation Method"; Rec."Calculation Method") { ApplicationArea = All; }
                field(Basis; Rec.Basis) { ApplicationArea = All; }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }
}
