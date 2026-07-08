page 50200 "BSB Rebate Setup"
{
    PageType = Card;
    SourceTable = "BSB Rebate Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Rebate Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Primary Key"; Rec."Primary Key") { ApplicationArea = All; }
                field("Agreement Nos."; Rec."Agreement Nos.") { ApplicationArea = All; }
                field("Calc Request Nos."; Rec."Calc Request Nos.") { ApplicationArea = All; }
                field("Settlement Nos."; Rec."Settlement Nos.") { ApplicationArea = All; }
                field("Default Chunk Size"; Rec."Default Chunk Size") { ApplicationArea = All; }
                field("Auto Post Accruals"; Rec."Auto Post Accruals") { ApplicationArea = All; }
                field("Audit Required"; Rec."Audit Required") { ApplicationArea = All; }
                field("Default Reason Code"; Rec."Default Reason Code") { ApplicationArea = All; }
            }
        }
    }
}
