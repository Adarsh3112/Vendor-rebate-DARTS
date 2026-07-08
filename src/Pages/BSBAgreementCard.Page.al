page 50205 "BSB Agreement Card"
{
    PageType = Card;
    SourceTable = "BSB Agreement";
    ApplicationArea = All;
    Caption = 'Rebate Agreement';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; }
                field("Reason Code"; Rec."Reason Code") { ApplicationArea = All; }
            }
            group(Scope)
            {
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Group"; Rec."Customer Group") { ApplicationArea = All; }
                field("Country Code"; Rec."Country Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Dimension Filter"; Rec."Dimension Filter") { ApplicationArea = All; }
            }
            group(Terms)
            {
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field("Settlement Method"; Rec."Settlement Method") { ApplicationArea = All; }
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Current Version"; Rec."Current Version") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Submit)
            {
                ApplicationArea = All;
                Caption = 'Submit';
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "BSB Agreement Mgt";
                begin
                    AgreementMgt.SubmitForApproval(Rec);
                end;
            }
            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "BSB Agreement Mgt";
                begin
                    AgreementMgt.Approve(Rec);
                end;
            }
            action(Activate)
            {
                ApplicationArea = All;
                Caption = 'Activate';
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "BSB Agreement Mgt";
                begin
                    AgreementMgt.Activate(Rec);
                end;
            }
        }
    }
}
