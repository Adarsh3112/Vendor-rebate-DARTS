page 50100 "RBT Rebate Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "RBT Rebate Setup";
    Caption = 'RBT Rebate Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Agreement Nos."; Rec."Agreement Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to new Rebate Agreements.';
                }
                field("Settlement Nos."; Rec."Settlement Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Settlements.';
                }
                field("Calculation Nos."; Rec."Calculation Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. Series used to assign numbers to Rebate Calculation Requests.';
                }
                field("Audit Nos."; Rec."Audit Nos.")
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
