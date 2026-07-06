table 50100 "RBT Rebate Setup"
{
    Caption = 'RBT Rebate Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Agreement Nos."; Code[20])
        {
            Caption = 'Agreement Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Settlement Nos."; Code[20])
        {
            Caption = 'Settlement Nos.';
            TableRelation = "No. Series";
        }
        field(30; "Calculation Nos."; Code[20])
        {
            Caption = 'Calculation Nos.';
            TableRelation = "No. Series";
        }
        field(40; "Audit Nos."; Code[20])
        {
            Caption = 'Audit Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    var
        RebateSetup: Record "RBT Rebate Setup";
    begin
        if not Rec.Get() then begin
            RebateSetup.Init();
            RebateSetup."Primary Key" := '';
            RebateSetup.Insert();
            Rec := RebateSetup;
        end;
    end;
}
