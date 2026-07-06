page 50106 "RBT Rebate Tier Sub"
{
    PageType = ListPart;
    SourceTable = "RBT Rebate Tier";
    Caption = 'Tiers';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Minimum Amount"; Rec."Minimum Amount") { ApplicationArea = All; }
                field("Rebate %"; Rec."Rebate %") { ApplicationArea = All; }
            }
        }
    }
}
