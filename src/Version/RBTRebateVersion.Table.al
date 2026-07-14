table 50103 "RBT Rebate Version"
{
    Caption = 'RBT Rebate Version';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Version List";
    DrillDownPageId = "RBT Rebate Version List";

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";
            NotBlank = true;
        }
        field(2; "Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = CustomerContent;
            MinValue = 1;
        }
        field(10; "Is Current"; Boolean)
        {
            Caption = 'Is Current';
            DataClassification = CustomerContent;
        }
        field(11; "Effective From"; Date)
        {
            Caption = 'Effective From';
            DataClassification = CustomerContent;
        }
        field(12; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }
        field(13; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Change Description"; Text[250])
        {
            Caption = 'Change Description';
            DataClassification = CustomerContent;
        }
        field(15; "Agreement Status Snapshot"; Enum "RBT Agreement Status")
        {
            Caption = 'Agreement Status Snapshot';
            DataClassification = CustomerContent;
        }
        field(16; "Start Date Snapshot"; Date)
        {
            Caption = 'Start Date Snapshot';
            DataClassification = CustomerContent;
        }
        field(17; "End Date Snapshot"; Date)
        {
            Caption = 'End Date Snapshot';
            DataClassification = CustomerContent;
        }
        field(18; "Description Snapshot"; Text[100])
        {
            Caption = 'Description Snapshot';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Version No.")
        {
            Clustered = true;
        }
        key(CurrentKey; "Agreement No.", "Is Current") { }
        key(EffectiveKey; "Agreement No.", "Effective From") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Agreement No.", "Version No.", "Is Current", "Effective From") { }
        fieldgroup(Brick; "Agreement No.", "Version No.", "Is Current", "Effective From", "Created At") { }
    }

    var
        ImmutableVersionErr: Label 'Rebate Version %1 for agreement %2 is a historical audit record and cannot be modified. Create a new version through the Rebate Agreement Card instead.';
        DeleteBlockedErr: Label 'Rebate Version %1 for agreement %2 cannot be deleted. Historical versions are preserved for audit purposes.';

    trigger OnModify()
    var
        AllowModify: Boolean;
    begin
        // Only allow modifications when performed by the versioning engine via the internal flag.
        AllowModify := AllowInternalEdit;
        if not AllowModify then
            Error(ImmutableVersionErr, "Version No.", "Agreement No.");
    end;

    trigger OnDelete()
    begin
        Error(DeleteBlockedErr, "Version No.", "Agreement No.");
    end;

    var
        AllowInternalEdit: Boolean;

    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;
}
