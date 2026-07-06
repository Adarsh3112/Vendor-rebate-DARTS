page 50102 "RBT Rebate Agmt Vers"
{
    PageType = List;
    SourceTable = "RBT Rebate Agmt Ver";
    Caption = 'Rebate Agreement Versions';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Version No."; Rec."Version No.") { ApplicationArea = All; }
                field("Is Current Version"; Rec."Is Current Version") { ApplicationArea = All; }
                field("Effective From"; Rec."Effective From") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Rebate %"; Rec."Rebate %") { ApplicationArea = All; }
            }
        }
    }
}
