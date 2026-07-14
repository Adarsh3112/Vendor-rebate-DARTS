page 50109 "RBT Calc Request List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RBT Calc Request";
    CardPageId = "RBT Calc Request Card";
    Caption = 'RBT Calc Requests';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Calc Request number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Description of the accrual batch.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate Agreement covered by this Calc Request.';
                }
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = All;
                    ToolTip = 'Start of the calculation period.';
                }
                field("Period End"; Rec."Period End")
                {
                    ApplicationArea = All;
                    ToolTip = 'End of the calculation period.';
                }
                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Open until the accrual has been posted to G/L; Posted after successful posting.';
                }
                field("No. of G/L Entries"; Rec."No. of G/L Entries")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of G/L entries produced by the accrual posting.';
                }
                field("Total Accrual Amount"; Rec."Total Accrual Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sum of Calculated Amount from Calculation Ledger Entries in the period.';
                }
            }
        }
    }
}
