page 50204 "BSB Agreement List"
{
    PageType = List;
    SourceTable = "BSB Agreement";
    CardPageId = "BSB Agreement Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Agreements';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Current Version"; Rec."Current Version") { ApplicationArea = All; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; }
            }
        }
    }
}
