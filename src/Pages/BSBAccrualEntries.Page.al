page 50210 "BSB Accrual Entries"
{
    PageType = List;
    SourceTable = "BSB Accrual Entry";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Rebate Accrual Entries';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Calc Entry No."; Rec."Calc Entry No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Party No."; Rec."Party No.") { ApplicationArea = All; }
                field(Period; Rec.Period) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Open Amount"; Rec."Open Amount") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Posting Ref."; Rec."Posting Ref.") { ApplicationArea = All; }
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
                trigger OnAction()
                var
                    PostingEngine: Codeunit "BSB Posting Engine";
                begin
                    PostingEngine.PostAccrual(Rec);
                end;
            }
        }
    }
}
