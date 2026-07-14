table 50107 "RBT Audit Entry"
{
    // Centralized, immutable audit trail for the Rebate module.
    //
    // Records every business-critical status change on a rebate agreement
    // (Sent For Approval, Cancelled, Approved, Activated) and every financial
    // posting event (Accrual Posted, Settlement Posted). See RBT Audit Mgt.
    // codeunit for the write API.
    //
    // RIMD IMMUTABILITY:
    //   OnModify and OnDelete triggers unconditionally Error() unless the internal
    //   InsertAudit path has toggled AllowInternalEdit. The escape hatch is used
    //   only by RBT Audit Mgt. and is turned off again immediately after Insert.

    Caption = 'RBT Audit Entry';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Audit Entries";
    DrillDownPageId = "RBT Audit Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(3; "Date Time"; DateTime)
        {
            Caption = 'Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; Action; Enum "RBT Audit Action")
        {
            Caption = 'Action';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "New Value"; Text[250])
        {
            Caption = 'New Value';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DocumentKey; "Document No.", "Date Time") { }
        key(ActionKey; Action, "Date Time") { }
        key(UserKey; "User ID", "Date Time") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Date Time", Action, "Document No.", "User ID") { }
        fieldgroup(Brick; "Entry No.", "Date Time", Action, "Document No.", "User ID", "New Value") { }
    }

    var
        ImmutableModifyErr: Label 'Audit Entry %1 is an immutable audit record and cannot be modified. Audit entries are preserved permanently for compliance.', Comment = '%1 = Entry No.';
        ImmutableDeleteErr: Label 'Audit Entry %1 cannot be deleted. Audit entries are preserved permanently for compliance.', Comment = '%1 = Entry No.';
        AllowInternalEdit: Boolean;

    trigger OnModify()
    begin
        // Immutability guard - the audit trail must never be altered after insert.
        // The RBT Audit Mgt. codeunit toggles AllowInternalEdit only around Insert()
        // to stamp the AutoIncrement Entry No. and the Date Time / User ID system fields.
        if not AllowInternalEdit then
            Error(ImmutableModifyErr, "Entry No.");
    end;

    trigger OnDelete()
    begin
        // Delete is blocked unconditionally - audit trail is append-only.
        Error(ImmutableDeleteErr, "Entry No.");
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used exclusively by RBT Audit Mgt.
    /// External callers must never call this; unauthorized modifications fail with
    /// ImmutableModifyErr regardless.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;
}
