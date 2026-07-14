page 50101 "RBT Rebate Agreement Card"
{
    Caption = 'RBT Rebate Agreement Card';
    PageType = Card;
    SourceTable = "RBT Rebate Agreement";
    ApplicationArea = All;
    UsageCategory = Documents;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsHeaderEditable;

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique number identifying the rebate agreement. Assigned automatically from the No. Series defined in RBT Rebate Setup.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the rebate agreement.';
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the agreement is a Vendor Rebate or a Customer Incentive.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the current status of the rebate agreement: Draft, Pending Approval, Approved, Active, or Closed.';
                }
            }
            group(Parties)
            {
                Caption = 'Parties';
                Editable = IsHeaderEditable;

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor associated with this agreement. Used when Type is Vendor Rebate.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer associated with this agreement. Used when Type is Customer Incentive.';
                }
            }
            group(Dates)
            {
                Caption = 'Validity';
                Editable = IsHeaderEditable;

                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first date on which the rebate agreement is effective.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date on which the rebate agreement is effective.';
                }
            }
            group(Signatory)
            {
                Caption = 'Signatory';
                Editable = IsHeaderEditable;

                field("Signatory Code"; Rec."Signatory Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the User Setup code of the person who signed this agreement. Mandatory before activation.';
                }
                field("Signed Date"; Rec."Signed Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which this agreement was signed. Must be on or before today before activation.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                Editable = IsHeaderEditable;

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code used for amounts on this agreement.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting group used to determine the G/L accounts for rebate postings related to this agreement.';
                }
            }
            group(ApprovalTracking)
            {
                Caption = 'Approval';

                field("Sent For Approval Date"; Rec."Sent For Approval Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When the agreement was submitted for approval.';
                }
                field("Sent For Approval By"; Rec."Sent For Approval By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'User who submitted the agreement for approval.';
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'When the agreement was approved.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'User who approved the agreement.';
                }
            }
            part("Rebate Rules"; "RBT Rebate Rules Part")
            {
                Caption = 'Rebate Rules';
                ApplicationArea = All;
                SubPageLink = "Agreement No." = FIELD("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Approval)
            {
                Caption = 'Approval';

                action(SendForApproval)
                {
                    Caption = 'Send for Approval';
                    Image = SendApprovalRequest;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = IsDraft;
                    ToolTip = 'Submit this Draft agreement into the standard BC approval workflow. Signatory Code and Signed Date must be set.';

                    trigger OnAction()
                    var
                        AgreementApproval: Codeunit "RBT Rebate Agreement Approval";
                    begin
                        AgreementApproval.SendForApproval(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(CancelApproval)
                {
                    Caption = 'Cancel Approval Request';
                    Image = CancelApprovalRequest;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = IsPendingApproval;
                    ToolTip = 'Recall a pending approval request and return the agreement to Draft.';

                    trigger OnAction()
                    var
                        AgreementApproval: Codeunit "RBT Rebate Agreement Approval";
                    begin
                        AgreementApproval.CancelApprovalRequest(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Approve)
                {
                    Caption = 'Approve';
                    Image = Approve;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = IsPendingApproval;
                    ToolTip = 'Direct-approval fallback. Only usable when no approval workflow is configured or when acting as the approver.';

                    trigger OnAction()
                    var
                        AgreementApproval: Codeunit "RBT Rebate Agreement Approval";
                    begin
                        AgreementApproval.Approve(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Lifecycle)
            {
                Caption = 'Lifecycle';

                action(Activate)
                {
                    Caption = 'Activate';
                    Image = ReleaseDoc;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Activates the rebate agreement and creates Version 1. Requires Signatory Code and Signed Date. Only Draft or Approved agreements can be activated.';

                    trigger OnAction()
                    var
                        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
                    begin
                        VersionMgt.ActivateAgreement(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RecalcRetroactive)
                {
                    Caption = 'Recalc Retroactive...';
                    Image = Recalculate;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = Rec.Status = Rec.Status::Active;
                    ToolTip = 'Re-evaluates already-calculated rebate entries for a chosen period against the current agreement version and posts only the delta to the G/L.';

                    trigger OnAction()
                    var
                        RecalcEngine: Codeunit "RBT Recalc Engine";
                        PostingEngine: Codeunit "RBT Posting Engine";
                        CalcRequest: Record "RBT Calc Request";
                        PeriodStart: Date;
                        PeriodEnd: Date;
                        PostingDate: Date;
                        DeltaCount: Integer;
                        RecalcDialog: Page "RBT Recalc Retroactive Dialog";
                        SuccessMsg: Label 'Retroactive recalculation posted %1 delta entries for Agreement %2. Calc Request %3 has been created and posted to the G/L.', Comment = '%1 = Delta count, %2 = Agreement No., %3 = Calc Request No.';
                    begin
                        // Capture period + posting date via a lightweight dialog page.
                        RecalcDialog.SetDefaults(Rec."Start Date", Rec."End Date", WorkDate());
                        if RecalcDialog.RunModal() <> Action::OK then
                            exit;
                        RecalcDialog.GetValues(PeriodStart, PeriodEnd, PostingDate);

                        // Delta compute is entirely delegated to the codeunit - the page never
                        // performs any calculation itself, per the management-codeunit rule.
                        DeltaCount := RecalcEngine.RecalcPeriod(Rec."No.", PeriodStart, PeriodEnd, PostingDate, CalcRequest);

                        // Chain into the existing single G/L posting path.
                        PostingEngine.PostAccrual(CalcRequest);

                        Message(SuccessMsg, DeltaCount, Rec."No.", CalcRequest."No.");
                        CurrPage.Update(false);
                    end;
                }
            }
            group(History)
            {
                Caption = 'History';

                action(Versions)
                {
                    Caption = 'Versions';
                    Image = History;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Opens the list of versions recorded for this rebate agreement.';
                    RunObject = page "RBT Rebate Version List";
                    RunPageLink = "Agreement No." = FIELD("No.");
                }
            }
        }
    }

    var
        IsHeaderEditable: Boolean;
        IsDraft: Boolean;
        IsPendingApproval: Boolean;

    trigger OnOpenPage()
    begin
        RefreshFlags();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsHeaderEditable := true;
        IsDraft := true;
        IsPendingApproval := false;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshFlags();
    end;

    local procedure RefreshFlags()
    begin
        IsHeaderEditable := Rec.IsEditable();
        IsDraft := Rec.Status = Rec.Status::Draft;
        IsPendingApproval := Rec.Status = Rec.Status::"Pending Approval";
    end;
}
