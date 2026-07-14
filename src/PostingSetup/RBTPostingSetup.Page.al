page 50104 "RBT Rebate Posting Setup"
{
    Caption = 'RBT Rebate Posting Setup';
    PageType = List;
    SourceTable = "RBT Posting Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting group that identifies this rebate posting configuration.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code for this posting setup. Leave blank for local currency.';
                }
                field("Accrual Expense Acc."; Rec."Accrual Expense Acc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L Account used to record the rebate accrual expense (debit side of the accrual posting).';
                }
                field("Accrual Liab. Acc."; Rec."Accrual Liab. Acc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L Account used to record the rebate accrual liability (credit side of the accrual posting).';
                }
                field("Settlement Acc."; Rec."Settlement Acc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L Account used when the rebate accrual is settled against the vendor.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestAccounts)
            {
                ApplicationArea = All;
                Caption = 'Validate G/L Accounts';
                Image = TestReport;
                ToolTip = 'Verifies that all required G/L Accounts are populated and are Posting accounts.';

                trigger OnAction()
                var
                    PostingSetupOkMsg: Label 'Rebate Posting Setup %1 / %2 is valid.', Comment = '%1 = Posting Group, %2 = Currency Code';
                begin
                    Rec.TestAccounts();
                    Message(PostingSetupOkMsg, Rec."Posting Group", Rec."Currency Code");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(TestAccounts_Promoted; TestAccounts)
                {
                }
            }
        }
    }
}
