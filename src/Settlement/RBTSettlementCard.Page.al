page 50110 "RBT Settlement Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "RBT Settlement Header";
    Caption = 'RBT Settlement';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsDraft;

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = NoFieldEditable;
                    ToolTip = 'Settlement number. Auto-assigned from the RBT-SET No. Series when left blank.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Free-text description of this settlement batch.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate Agreement covered by this settlement.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Vendor whose credit memo will be posted for a Vendor Rebate settlement.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Customer whose credit memo will be posted for a Customer Incentive settlement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Currency of the settlement.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting Group that resolves the G/L account via RBT Posting Setup.';
                }
                field("Settlement Date"; Rec."Settlement Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Business date the settlement was raised.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'G/L posting date used when the credit memo is posted.';
                }
            }
            part(Lines; "RBT Settlement Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Settlement No." = field("No.");
                UpdatePropagation = Both;
            }
            group(StatusInfo)
            {
                Caption = 'Status';

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Draft -> Pending -> Approved -> Posted. Managed by the Settlement Engine.';
                }
                field("Sent For Approval Date"; Rec."Sent For Approval Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When the settlement was submitted for approval.';
                }
                field("Sent For Approval By"; Rec."Sent For Approval By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'User who submitted the settlement for approval.';
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When the settlement was approved.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'User who approved the settlement.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When the settlement was posted.';
                }
                field("Posted By"; Rec."Posted By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'User who posted the settlement.';
                }
                field("Credit Memo Document Type"; Rec."Credit Memo Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Purchase (Vendor Rebate) or Sales (Customer Incentive) credit memo type produced by posting.';
                }
                field("Posted Credit Memo No."; Rec."Posted Credit Memo No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Number of the posted credit memo produced when this settlement was posted.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Sum of Amount across all settlement lines.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateProposal)
            {
                ApplicationArea = All;
                Caption = 'Generate Proposal';
                Image = SuggestLines;
                ToolTip = 'Re-populate this Draft settlement from eligible posted Calc Requests.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                    HeaderFilter: Record "RBT Settlement Header";
                begin
                    HeaderFilter.SetRange("No.", Rec."No.");
                    SettlementEngine.GenerateProposals(HeaderFilter);
                    CurrPage.Update(false);
                end;
            }
            action(SendForApproval)
            {
                ApplicationArea = All;
                Caption = 'Send for Approval';
                Image = SendApprovalRequest;
                Enabled = IsDraft;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Submit this Draft settlement into the standard BC approval workflow.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                begin
                    SettlementEngine.SendForApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelApproval)
            {
                ApplicationArea = All;
                Caption = 'Cancel Approval Request';
                Image = CancelApprovalRequest;
                Enabled = IsPending;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Recall a pending approval request and return the settlement to Draft.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                begin
                    SettlementEngine.CancelApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Enabled = IsPending;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Direct-approval fallback. Only usable when no approval workflow is configured.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                begin
                    SettlementEngine.Approve(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                Enabled = IsApproved;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Post this Approved settlement. Produces a Purchase or Sales Credit Memo.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                    ConfirmPostQst: Label 'Post settlement %1?', Comment = '%1 = Settlement No.';
                begin
                    if not Confirm(ConfirmPostQst, false, Rec."No.") then
                        exit;
                    SettlementEngine.PostSettlement(Rec);
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
                ToolTip = 'Preview the credit memo posting for this settlement without persisting any change.';

                trigger OnAction()
                var
                    SettlementEngine: Codeunit "RBT Settlement Engine";
                begin
                    SettlementEngine.PreviewSettlement(Rec);
                end;
            }
        }
    }

    var
        NoFieldEditable: Boolean;
        IsDraft: Boolean;
        IsPending: Boolean;
        IsApproved: Boolean;

    trigger OnOpenPage()
    begin
        NoFieldEditable := true;
        RefreshStatusFlags();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NoFieldEditable := true;
        IsDraft := true;
        IsPending := false;
        IsApproved := false;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        NoFieldEditable := Rec.IsEditable();
        RefreshStatusFlags();
    end;

    local procedure RefreshStatusFlags()
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        IsPending := Rec.Status = Rec.Status::Pending;
        IsApproved := Rec.Status = Rec.Status::Approved;
    end;
}
