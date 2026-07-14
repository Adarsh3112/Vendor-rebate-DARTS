page 50100 "RBT Rebate Setup"
{
    Caption = 'RBT Rebate Setup';
    PageType = Card;
    SourceTable = "RBT Rebate Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group("Numbering")
            {
                Caption = 'Numbering';

                field("Rebate Agreement Nos."; Rec."Rebate Agreement Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Agreement documents.';
                }
                field("Accrual Nos."; Rec."Accrual Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Accrual entries.';
                }
                field("Settlement Nos."; Rec."Settlement Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Settlement documents.';
                }
                field("Calculation Request Nos."; Rec."Calculation Request Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Calculation Requests.';
                }
                field("Rebate Audit Nos."; Rec."Rebate Audit Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Audit entries.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
    end;
}
