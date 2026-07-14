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
        field(10; "Rebate Agreement Nos."; Code[20])
        {
            Caption = 'Rebate Agreement Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(20; "Accrual Nos."; Code[20])
        {
            Caption = 'Accrual Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(30; "Settlement Nos."; Code[20])
        {
            Caption = 'Settlement Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(40; "Calculation Request Nos."; Code[20])
        {
            Caption = 'Calculation Request Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(50; "Rebate Audit Nos."; Code[20])
        {
            Caption = 'Rebate Audit Nos.';
            DataClassification = CustomerContent;
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
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
    end;
}
