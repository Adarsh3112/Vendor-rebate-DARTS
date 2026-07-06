page 50105 "RBT Rebate Ledg Ents"
{
    PageType = List;
    SourceTable = "RBT Rebate Ledg Ent";
    Caption = 'Rebate Ledger Entries';
    Editable = false;
    UsageCategory = History;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Closed by Settlement No."; Rec."Closed by Settlement No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {area(processing)
        {
            action(Settle)
            {
                Caption = 'Settle Accrual';
                Image = Settlement;
                ApplicationArea = All;
                trigger OnAction()
                var
                    RebateCalc: Codeunit "RBT Rebate Calc.";
                begin
                    RebateCalc.PostSettlement(Rec);
                    Message('Settlement posted successfully.');
                end;
            }
        }
    }
}