table 50111 "RBT Calc Ledg Entry"
{
    Caption = 'RBT Calc Ledg Entry';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Calc Ledg Ents";
    DrillDownPageId = "RBT Calc Ledg Ents";

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
            TableRelation = "RBT Agreement Header";
            NotBlank = true;
        }
        field(11; "Version No."; Integer)
        {
            Caption = 'Version No.';
            TableRelation = "RBT Agmt Version"."Version No." where("Agreement No." = field("Agreement No."));
            MinValue = 1;
        }
        field(12; "Rule No."; Integer)
        {
            Caption = 'Rule No.';
        }
        field(20; "Source Trans. No."; Code[20])
        {
            Caption = 'Source Trans. No.';
        }
        field(21; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionMembers = Purchase,Sales;
            OptionCaption = 'Purchase,Sales';
        }
        field(30; "Amount LCY"; Decimal)
        {
            Caption = 'Amount LCY';
            AutoFormatType = 1;
        }
        field(31; "Amount FCY"; Decimal)
        {
            Caption = 'Amount FCY';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(33; "Exchange Rate"; Decimal)
        {
            Caption = 'Exchange Rate';
            DecimalPlaces = 0 : 6;
            MinValue = 0;
        }
        field(40; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(50; "Calculation Req. No."; Code[20])
        {
            Caption = 'Calculation Req. No.';
            TableRelation = "RBT Rebate Calc Hdr"."No.";
        }
        field(60; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(61; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User;
            Editable = false;
        }
        field(70; "Corrects Entry No."; Integer)
        {
            Caption = 'Corrects Entry No.';
            TableRelation = "RBT Calc Ledg Entry";
        }
        field(80; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
        field(81; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Agreement; "Agreement No.", "Version No.")
        {
        }
        key(CalcRequest; "Calculation Req. No.")
        {
        }
        key(Source; "Source Type", "Source Trans. No.")
        {
        }
    }

    var
        ModifyErr: Label 'RBT Calc Ledg Entry %1 is immutable and cannot be modified.', Comment = '%1 = Entry No.';
        DeleteErr: Label 'RBT Calc Ledg Entry %1 is immutable and cannot be deleted.', Comment = '%1 = Entry No.';

    trigger OnModify()
    begin
        Error(ModifyErr, "Entry No.");
    end;

    trigger OnDelete()
    begin
        Error(DeleteErr, "Entry No.");
    end;

    trigger OnRename()
    begin
        Error(ModifyErr, "Entry No.");
    end;
}
