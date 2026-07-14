page 50111 "RBT Settlement Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "RBT Settlement Line";
    Caption = 'Settlement Lines';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Line number within the settlement.';
                }
                field("Calc Request No."; Rec."Calc Request No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Source Calc Request that produced the accrual now being settled.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate Agreement that generated this accrual.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Vendor for a Vendor Rebate settlement line.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Customer for a Customer Incentive settlement line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Settlement amount, copied from the source Calc Request Total Accrual Amount.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Currency of the settlement line.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Original posting date of the source Calc Request.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Line description.';
                }
            }
        }
    }
}
