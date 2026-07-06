page 50114 "RBT Settlement List"
{
    PageType = List;
    SourceTable = "RBT Settlement Header";
    Caption = 'Rebate Settlements';
    CardPageId = "RBT Settlement Card";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                }
                field("Vendor/Customer No."; Rec."Vendor/Customer No.")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Posted Credit Memo No."; Rec."Posted Credit Memo No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
