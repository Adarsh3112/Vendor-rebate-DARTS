page 50212 "BSB Settlement Card"
{
    PageType = Card;
    SourceTable = "BSB Settlement Hdr";
    ApplicationArea = All;
    Caption = 'Rebate Settlement';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Settlement No."; Rec."Settlement No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Party No."; Rec."Party No.") { ApplicationArea = All; }
                field(Period; Rec.Period) { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
                field("Adjustment Amount"; Rec."Adjustment Amount") { ApplicationArea = All; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; }
                field(Posted; Rec.Posted) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                trigger OnAction()
                var
                    ApprovalMgt: Codeunit "BSB Approval Mgt";
                begin
                    ApprovalMgt.ApproveSettlement(Rec);
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                trigger OnAction()
                var
                    SettlementEngine: Codeunit "BSB Settlement Engine";
                begin
                    SettlementEngine.PostSettlement(Rec);
                end;
            }
        }
    }
}
