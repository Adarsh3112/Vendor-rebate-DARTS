page 50202 "BSB Audit Entries"
{
    PageType = List;
    SourceTable = "BSB Audit Entry";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    Caption = 'Rebate Audit Entries';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Date Time"; Rec."Date Time") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field(Action; Rec.Action) { ApplicationArea = All; }
                field("Record ID Text"; Rec."Record ID Text") { ApplicationArea = All; }
                field("Old Value"; Rec."Old Value") { ApplicationArea = All; }
                field("New Value"; Rec."New Value") { ApplicationArea = All; }
                field("Reason Code"; Rec."Reason Code") { ApplicationArea = All; }
                field("Source Reference"; Rec."Source Reference") { ApplicationArea = All; }
            }
        }
    }
}
