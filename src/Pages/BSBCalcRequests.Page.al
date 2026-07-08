page 50208 "BSB Calc Requests"
{
    PageType = List;
    SourceTable = "BSB Calc Request";
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Rebate Calculation Requests';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Request Type"; Rec."Request Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Date From"; Rec."Date From") { ApplicationArea = All; }
                field("Date To"; Rec."Date To") { ApplicationArea = All; }
                field("Recalc Mode"; Rec."Recalc Mode") { ApplicationArea = All; }
                field("Idempotency Key"; Rec."Idempotency Key") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCalculation)
            {
                ApplicationArea = All;
                Caption = 'Run Calculation';
                trigger OnAction()
                var
                    CalcEngine: Codeunit "BSB Calc Engine";
                begin
                    CalcEngine.RunCalculation(Rec);
                end;
            }
        }
    }
}
