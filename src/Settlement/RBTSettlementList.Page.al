page 50112 "RBT Settlement List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RBT Settlement Header";
    CardPageId = "RBT Settlement Card";
    Caption = 'RBT Settlements';
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
                    ToolTip = 'Settlement number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Free-text description of the settlement batch.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate Agreement covered by this settlement.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Vendor associated with a Vendor Rebate settlement.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Customer associated with a Customer Incentive settlement.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Current status: Draft, Pending, Approved, or Posted.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sum of Amount across all settlement lines.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'G/L posting date for the credit memo.';
                }
                field("Posted Credit Memo No."; Rec."Posted Credit Memo No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posted credit memo number if this settlement has been posted.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateProposals)
            {
                ApplicationArea = All;
                Caption = 'Generate Proposals';
                Image = SuggestLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Group all eligible posted Calc Requests into new Draft settlements.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                begin
                    SettlementEngine.GenerateProposalsAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
