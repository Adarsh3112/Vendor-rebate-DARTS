table 50103 "RBT Agmt Version"
{
    Caption = 'RBT Agmt Version';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20])
        { 
            Caption = 'Agreement No.'; 
            TableRelation = "RBT Agreement Header"; 
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
        field(40; "Type"; Enum "RBT Agreement Type") 
        { 
            Caption = 'Type'; 
        }
        field(50; "Vendor No."; Code[20]) 
        { 
            Caption = 'Vendor No.'; 
            TableRelation = Vendor; 
        }
        field(51; "Customer No."; Code[20]) 
        { 
            Caption = 'Customer No.'; 
            TableRelation = Customer; 
        }
        field(60; "Start Date"; Date) 
        { 
            Caption = 'Start Date'; 
        }
        field(61; "End Date"; Date) 
        { 
            Caption = 'End Date'; 
        }
        field(70; "Posting Group"; Code[20]) 
        { 
            Caption = 'Posting Group'; 
        }
        field(80; "Currency Code"; Code[10]) 
        { 
            Caption = 'Currency Code'; 
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Version No.")
        { 
            Clustered = true; 
        }
    }

    trigger OnModify()
    begin
        Error('Historical versions are immutable.');
    end;

    trigger OnDelete()
    begin
        Error('Historical versions cannot be deleted.');
    end;
}
