page 50207 "BSB Agr Versions"
{
    PageType = List;
    SourceTable = "BSB Agr Version";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    Caption = 'Rebate Agreement Versions';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Version No."; Rec."Version No.") { ApplicationArea = All; }
                field("Effective Date"; Rec."Effective Date") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Change Reason"; Rec."Change Reason") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Used In Calc."; Rec."Used In Calc.") { ApplicationArea = All; }
            }
        }
    }
}
