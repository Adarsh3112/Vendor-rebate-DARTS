page 50206 "BSB Rule Worksheet"
{
    PageType = List;
    SourceTable = "BSB Rebate Rule";
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Rebate Rule Worksheet';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Rule No."; Rec."Rule No.") { ApplicationArea = All; }
                field("Rule Type"; Rec."Rule Type") { ApplicationArea = All; }
                field(Basis; Rec.Basis) { ApplicationArea = All; }
                field("Calc Method"; Rec."Calc Method") { ApplicationArea = All; }
                field(Priority; Rec.Priority) { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}
