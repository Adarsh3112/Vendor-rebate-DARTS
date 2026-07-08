page 50214 "BSB Job Monitor"
{
    PageType = List;
    SourceTable = "BSB Process Chunk";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Job Monitor';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Chunk No."; Rec."Chunk No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Processed Count"; Rec."Processed Count") { ApplicationArea = All; }
                field("Error Count"; Rec."Error Count") { ApplicationArea = All; }
                field("Retry Count"; Rec."Retry Count") { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
            }
        }
    }
}
