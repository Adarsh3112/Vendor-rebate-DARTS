page 50101 "RBT Rebate Agmt Card"
{
    PageType = Card;
    SourceTable = "RBT Rebate Agreement";
    Caption = 'Rebate Agreement';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Vendor Name"; Rec."Vendor Name") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Signatory Code"; Rec."Signatory Code") { ApplicationArea = All; }
                field("Signed Date"; Rec."Signed Date") { ApplicationArea = All; }
            }
            group(Calculation)
            {
                field("Calc. Method"; Rec."Calc. Method") { ApplicationArea = All; }
                field("Rebate %"; Rec."Rebate %") { ApplicationArea = All; }
                field("Baseline Amount"; Rec."Baseline Amount") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Start Date"; Rec."Start Date") { ApplicationArea = All; }
                field("End Date"; Rec."End Date") { ApplicationArea = All; }
            }
            part(Tiers; "RBT Rebate Tier Sub")
            {
                ApplicationArea = All;
                SubPageLink = "Agreement No." = field("No.");
            }
            part(RebateRules; "RBT Rebate Rule Sub")
            {
                ApplicationArea = All;
                Caption = 'Rebate Rules';
                SubPageLink = "Agreement No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Activate)
            {
                Caption = 'Activate';
                Image = Approve;
                ApplicationArea = All;
                trigger OnAction()
                var
                    RebateMgmt: Codeunit "RBT Rebate Mgmt.";
                begin
                    RebateMgmt.ActivateAgreement(Rec);
                end;
            }
            action(Close)
            {
                Caption = 'Close';
                Image = Close;
                ApplicationArea = All;
                trigger OnAction()
                var
                    RebateMgmt: Codeunit "RBT Rebate Mgmt.";
                begin
                    RebateMgmt.CloseAgreement(Rec);
                end;
            }
        }
        area(navigation)
        {
            action(Versions)
            {
                Caption = 'Versions';
                Image = Versions;
                RunObject = page "RBT Rebate Agmt Vers";
                RunPageLink = "Agreement No." = field("No.");
                ApplicationArea = All;
            }
            action(RebateRulesAction)
            {
                Caption = 'Rebate Rules';
                Image = List;
                RunObject = page "RBT Rebate Rules";
                RunPageLink = "Agreement No." = field("No.");
                ApplicationArea = All;
            }
        }
    }
}
