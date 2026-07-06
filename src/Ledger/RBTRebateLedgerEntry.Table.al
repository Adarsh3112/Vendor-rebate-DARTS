table 50110 "RBT Rebate Ledg Ent"
{
    Caption = 'RBT Rebate Ledg Ent';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Ledg Ents";
    DrillDownPageId = "RBT Rebate Ledg Ents";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = "RBT Rebate Agreement";
        }
        field(11; "Version No."; Integer)
        {
            Caption = 'Version No.';
            TableRelation = "RBT Rebate Agmt Ver"."Version No." where("Agreement No." = field("Agreement No."));
        }
        field(20; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(40; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(50; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(51; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
        }
        field(60; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(70; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionMembers = Accrual,Settlement;
        }
        field(80; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Open,Closed;
            OptionCaption = 'Open,Closed';
            InitValue = Open;
        }
        field(81; "Closed by Settlement No."; Code[20])
        {
            Caption = 'Closed by Settlement No.';
            TableRelation = "RBT Settlement Header";
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
        Error('Posted entries cannot be modified. Create a correcting entry.');
    end;

    trigger OnDelete()
    begin
        Error('Posted entries cannot be deleted.');
    end;
}
