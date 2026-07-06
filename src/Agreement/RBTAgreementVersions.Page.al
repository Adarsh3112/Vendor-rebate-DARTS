page 50107 "RBT Agmt Versions"
{
    PageType = List;
    SourceTable = "RBT Agmt Version";
    Caption = 'Agreement Versions';
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
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
            }
        }
    }
}
