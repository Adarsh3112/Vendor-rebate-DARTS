page 50112 "RBT Settlement Card"
{
    PageType = Card;
    SourceTable = "RBT Settlement Header";
    Caption = 'Rebate Settlement';
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Draft;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Vendor/Customer No."; Rec."Vendor/Customer No.")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Draft;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Draft;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Draft;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyleTxt;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(CreditMemo)
            {
                Caption = 'Credit Memo';
                field("Credit Memo Type"; Rec."Credit Memo Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Credit Memo No."; Rec."Credit Memo No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Posted Credit Memo No."; Rec."Posted Credit Memo No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            part(SettlementLines; "RBT Settlement Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Settlement No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Lifecycle)
            {
                Caption = 'Lifecycle';
                action(SubmitForApproval)
                {
                    Caption = 'Submit for Approval';
                    Image = SendApprovalRequest;
                    ApplicationArea = All;
                    Enabled = Rec.Status = Rec.Status::Draft;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        SettlementMgmt.SubmitForApproval(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(PostSettlement)
                {
                    Caption = 'Post';
                    Image = Post;
                    ApplicationArea = All;
                    Enabled = Rec.Status = Rec.Status::Pending;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        SettlementMgmt.PostSettlement(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(SuggestAccruals)
                {
                    Caption = 'Suggest Accruals';
                    Image = SuggestLines;
                    ApplicationArea = All;
                    Enabled = Rec.Status = Rec.Status::Draft;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        SettlementMgmt.SuggestAccruals(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateStatusStyle();
    end;

    var
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        StatusStyleTxt: Text;

    local procedure UpdateStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Draft:
                StatusStyleTxt := 'Standard';
            Rec.Status::Pending:
                StatusStyleTxt := 'Ambiguous';
            Rec.Status::Posted:
                StatusStyleTxt := 'Favorable';
        end;
    end;
}
