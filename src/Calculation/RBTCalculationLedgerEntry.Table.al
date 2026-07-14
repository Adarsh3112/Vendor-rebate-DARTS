table 50105 "RBT Calculation Ledger Entry"
{
    Caption = 'RBT Calculation Ledger Entry';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Calc Ledger Entries";
    DrillDownPageId = "RBT Calc Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            OptionMembers = "Sales Invoice","Purchase Invoice";
            OptionCaption = 'Sales Invoice,Purchase Invoice';
        }
        field(3; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            DataClassification = CustomerContent;
        }
        field(4; "Source Document Line No."; Integer)
        {
            Caption = 'Source Document Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(10; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";
        }
        field(11; "Agreement Version No."; Integer)
        {
            Caption = 'Agreement Version No.';
            DataClassification = CustomerContent;
        }
        field(12; "Rule Line No."; Integer)
        {
            Caption = 'Rule Line No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Rule"."Line No." where("Agreement No." = field("Agreement No."));
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
        field(21; "Item Category"; Code[20])
        {
            Caption = 'Item Category';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(30; "Calculation Method"; Enum "RBT Calculation Method")
        {
            Caption = 'Calculation Method';
            DataClassification = CustomerContent;
        }
        field(31; "Base Amount"; Decimal)
        {
            Caption = 'Base Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(32; Percentage; Decimal)
        {
            Caption = 'Percentage';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(33; "Fixed Amount"; Decimal)
        {
            Caption = 'Fixed Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(34; "Calculated Amount"; Decimal)
        {
            Caption = 'Calculated Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(35; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        // Fields 40 and 41 were added by the Retroactive Recalc feature. Field IDs 30-35
        // were already occupied by pre-existing calculation fields, so the two new
        // delta-linkage fields use the next free block starting at 40. The Rule Engine's
        // Init() call zero-initialises them so historical entries continue to be produced
        // with Entry Type = Original and Corrects Entry No. = 0 without any code change.
        field(40; "Entry Type"; Enum "RBT Calc Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Corrects Entry No."; Integer)
        {
            Caption = 'Corrects Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "RBT Calculation Ledger Entry"."Entry No.";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AgreementVersionKey; "Agreement No.", "Agreement Version No.") { }
        key(SourceKey; "Source Type", "Source Document No.", "Source Document Line No.") { }
        key(PostingDateKey; "Posting Date") { }
        key(CorrectsIdx; "Corrects Entry No.", "Agreement Version No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Agreement No.", "Source Document No.", "Calculated Amount") { }
        fieldgroup(Brick; "Entry No.", "Agreement No.", "Source Document No.", "Item No.", "Calculated Amount") { }
    }

    var
        ImmutableEntryErr: Label 'Calculation Ledger Entry %1 is an immutable audit record and cannot be modified. Post a correcting entry through the Rule Engine instead.', Comment = '%1 = Entry No.';
        DeleteBlockedErr: Label 'Calculation Ledger Entry %1 cannot be deleted. Ledger entries are preserved permanently for audit purposes.', Comment = '%1 = Entry No.';
        AllowInternalEdit: Boolean;

    trigger OnModify()
    begin
        if not AllowInternalEdit then
            Error(ImmutableEntryErr, "Entry No.");
    end;

    trigger OnDelete()
    begin
        Error(DeleteBlockedErr, "Entry No.");
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used by the Rule Engine when it must
    /// stamp system fields. External callers never call this — attempts to modify
    /// without setting the flag fail with ImmutableEntryErr.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;
}
