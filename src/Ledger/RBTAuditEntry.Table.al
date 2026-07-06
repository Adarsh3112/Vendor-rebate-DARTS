table 50112 "RBT Audit Entry"
{
    Caption = 'RBT Audit Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(20; "Action"; Text[50])
        {
            Caption = 'Action';
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User;
        }
        field(40; "Execution Time"; DateTime)
        {
            Caption = 'Execution Time';
        }
        field(50; "Details"; Text[250])
        {
            Caption = 'Details';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnModify()
    begin
        Error('Audit entries are immutable and cannot be modified.');
    end;

    trigger OnDelete()
    begin
        Error('Audit entries are immutable and cannot be deleted.');
    end;
}
