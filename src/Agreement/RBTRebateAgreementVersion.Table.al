table 50113 "RBT Rebate Agmt Ver"
{
    Caption = 'RBT Rebate Agmt Ver';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Agmt Vers";
    DrillDownPageId = "RBT Rebate Agmt Vers";

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = "RBT Rebate Agreement";
        }
        field(2; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(10; "Is Current Version"; Boolean)
        {
            Caption = 'Is Current Version';
        }
        field(20; "Effective From"; Date)
        {
            Caption = 'Effective From';
        }
        field(30; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(40; "Rebate %"; Decimal)
        {
            Caption = 'Rebate %';
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Version No.")
        {
            Clustered = true;
        }
    }
}
