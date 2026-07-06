page 50103 "RBT Rebate Calc Card"
{
    PageType = Card;
    SourceTable = "RBT Rebate Calc Hdr";
    Caption = 'Rebate Calculation';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Agreement: Record "RBT Rebate Agreement";
                        Header: Record "RBT Agreement Header";
                    begin
                        // In a real UI this would offer a choice or a multi-table lookup. 
                        // For now we try the new model first as it is the target for MVP v2.
                        Header.SetRange(Status, Header.Status::Active);
                        if Page.RunModal(0, Header) = Action::LookupOK then begin
                            Rec."Agreement No." := Header."No.";
                            exit(true);
                        end;

                        Agreement.SetRange(Status, Agreement.Status::Active);
                        if Page.RunModal(0, Agreement) = Action::LookupOK then begin
                            Rec."Agreement No." := Agreement."No.";
                            exit(true);
                        end;
                    end;
                }
                field("Calc. From Date"; Rec."Calc. From Date") { ApplicationArea = All; }
                field("Calc. To Date"; Rec."Calc. To Date") { ApplicationArea = All; }
                field("Posting Status"; Rec."Posting Status") { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Calculate)
            {
                Caption = 'Post Accrual';
                Image = PostOrder;
                ApplicationArea = All;
                trigger OnAction()
                var
                    RebateCalc: Codeunit "RBT Rebate Calc.";
                begin
                    RebateCalc.Run(Rec);
                    Message('Accrual posted successfully.');
                end;
            }
            action(PreviewPosting)
            {
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                ApplicationArea = All;
                trigger OnAction()
                var
                    AccrualEngine: Codeunit "RBT Accrual Engine";
                    GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
                begin
                    GenJnlPostPreview.Preview(AccrualEngine, Rec);
                end;
            }
        }
    }
}