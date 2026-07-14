page 50108 "RBT Calc Request Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "RBT Calc Request";
    Caption = 'RBT Calc Request';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = NoFieldEditable;
                    ToolTip = 'Specifies the calc request number. Auto-assigned from the RBT-CALC No. Series when left blank.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'Free-text description of the accrual batch.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'Rebate Agreement whose Calculation Ledger Entries will be aggregated and posted.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'Currency of the accrual. Auto-populated from the Agreement.';
                }
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'Start of the calculation period (inclusive).';
                }
                field("Period End"; Rec."Period End")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'End of the calculation period (inclusive).';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                    ToolTip = 'G/L posting date for the two-line accrual journal.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';

                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Open until the accrual has been posted to G/L. Becomes Posted after successful posting.';
                }
                field("No. of G/L Entries"; Rec."No. of G/L Entries")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Number of G/L entries produced by the accrual posting (2 for a balanced debit/credit).';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'General Journal Document No. produced by the accrual posting.';
                }
                field("Total Accrual Amount"; Rec."Total Accrual Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Sum of Calculated Amount from Calculation Ledger Entries in the period.';
                }
                field("Settlement No."; Rec."Settlement No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Settlement document that closed this posted Calc Request. Blank while the Calc Request is unsettled.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Post a balanced Accrual Expense / Accrual Liability G/L entry pair for this Calc Request.';

                trigger OnAction()
                var
                    PostingEngine: Codeunit "RBT Posting Engine";
                    ConfirmPostQst: Label 'Post the rebate accrual for Calc Request %1?', Comment = '%1 = Calc Request No.';
                begin
                    if not Confirm(ConfirmPostQst, false, Rec."No.") then
                        exit;
                    PostingEngine.PostAccrual(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Preview)
            {
                ApplicationArea = All;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Preview the G/L entries that would be produced by posting this Calc Request, without persisting any change.';

                trigger OnAction()
                var
                    PostingEngine: Codeunit "RBT Posting Engine";
                begin
                    PostingEngine.PreviewAccrual(Rec);
                end;
            }
        }
    }

    var
        NoFieldEditable: Boolean;
        IsRequestEditable: Boolean;

    trigger OnOpenPage()
    begin
        NoFieldEditable := true;
        IsRequestEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NoFieldEditable := true;
        IsRequestEditable := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        NoFieldEditable := Rec.IsEditable();
        IsRequestEditable := Rec.IsEditable();
    end;
}
