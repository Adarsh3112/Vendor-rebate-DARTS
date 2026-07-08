page 50211 "BSB Settlement List"
{
    PageType = List;
    SourceTable = "BSB Settlement Hdr";
    CardPageId = "BSB Settlement Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Settlements';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Settlement No."; Rec."Settlement No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Party No."; Rec."Party No.") { ApplicationArea = All; }
                field(Period; Rec.Period) { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; }
                field(Posted; Rec.Posted) { ApplicationArea = All; }
            }
        }
    }
}
