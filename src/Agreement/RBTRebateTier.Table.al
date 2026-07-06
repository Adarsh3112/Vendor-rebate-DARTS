table 50108 "RBT Rebate Tier"
{
    Caption = 'RBT Rebate Tier';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = "RBT Rebate Agreement";
        }
        field(2; "Minimum Amount"; Decimal)
        {
            Caption = 'Minimum Amount';
        }
        field(10; "Rebate %"; Decimal)
        {
            Caption = 'Rebate %';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Minimum Amount")
        {
            Clustered = true;
        }
    }
}
