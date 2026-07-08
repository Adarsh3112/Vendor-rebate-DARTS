page 50203 "BSB Integration Log"
{
    PageType = List;
    SourceTable = "BSB Integration Msg";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Integration Log';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Message No."; Rec."Message No.") { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field("Message Type"; Rec."Message Type") { ApplicationArea = All; }
                field("External Ref. ID"; Rec."External Ref. ID") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Related Record"; Rec."Related Record") { ApplicationArea = All; }
                field("Retry Count"; Rec."Retry Count") { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Completed At"; Rec."Completed At") { ApplicationArea = All; }
            }
        }
    }
}
