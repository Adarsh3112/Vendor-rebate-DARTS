page 50109 "RBT Rebate Post Set"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "RBT Rebate Post Set";
    Caption = 'Rebate Posting Setup';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Rebate Group Code"; Rec."Rebate Group Code") { ApplicationArea = All; }
                field("Accrual Account No."; Rec."Accrual Account No.") { ApplicationArea = All; }
                field("Expense Account No."; Rec."Expense Account No.") { ApplicationArea = All; }
                field("Receivable Account No."; Rec."Receivable Account No.") { ApplicationArea = All; }
                field("Payable Account No."; Rec."Payable Account No.") { ApplicationArea = All; }
            }
        }
    }
}
