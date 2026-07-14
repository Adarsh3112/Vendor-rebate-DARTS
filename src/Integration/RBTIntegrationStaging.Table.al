table 50108 "RBT Integration Staging"
{
    Caption = 'RBT Integration Staging';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Integration Staging List";
    DrillDownPageId = "RBT Integration Staging List";

    // Staging table for external integrations. External systems land raw payloads
    // here through the RBT Integration Staging API page. A management codeunit
    // (RBT Integration Mgt.) promotes eligible rows into live RBT Rebate Agreement
    // records. Direct writes to live BC tables from external callers are forbidden.

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "External ID"; Code[50])
        {
            Caption = 'External ID';
            DataClassification = CustomerContent;
            ToolTip = 'Idempotency key supplied by the external system. Combined with Source System it identifies a unique inbound message.';
        }
        field(3; "Source System"; Code[20])
        {
            Caption = 'Source System';
            DataClassification = CustomerContent;
            ToolTip = 'Name of the external system that supplied this payload (e.g. SHOPIFY, ERP1).';
        }
        field(4; Status; Enum "RBT Integration Staging Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = New;
            ToolTip = 'Lifecycle state of the staging row: New, Processing, Processed, or Error.';
        }
        field(5; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = CustomerContent;
            SubType = UserDefined;
        }
        field(6; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
            ToolTip = 'Error text captured the last time promotion failed. Blank on success.';
        }
        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(8; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; "Promoted To Agreement No."; Code[20])
        {
            Caption = 'Promoted To Agreement No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "RBT Rebate Agreement"."No.";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ExternalIDKey; "Source System", "External ID")
        {
            // Uniqueness of (Source System, External ID) is enforced inside RBT Integration Mgt.Ingest
            // using the silent-acknowledge pattern; the database key is non-unique so a duplicate
            // ingest never surfaces a native primary-key error to the external caller.
            Unique = false;
        }
        key(StatusKey; Status) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Source System", "External ID", Status) { }
        fieldgroup(Brick; "Entry No.", "Source System", "External ID", Status) { }
    }

    var
        AllowInternalEdit: Boolean;
        ImmutableFieldChangedErr: Label 'On staging row %1, %2 cannot be modified once the row has been ingested. Only Status, Error Message, Processed At and Promoted To Agreement No. are updated by the management codeunit.', Comment = '%1 = Entry No.; %2 = field caption';

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        // Every legitimate mutation of a staging row is performed through
        // RBT Integration Mgt., which toggles SetAllowInternalEdit(true) around
        // the Modify call. Any modify without the flag is an unauthorised external
        // edit of the raw envelope and is rejected.
        //
        // Comparing individual fields against xRec is unsafe here because BLOB
        // fields (Payload) require CalcFields, which re-reads from the DB and
        // therefore returns the current value, not the pre-modify value.
        if AllowInternalEdit then
            exit;
        if "External ID" <> xRec."External ID" then
            Error(ImmutableFieldChangedErr, "Entry No.", FieldCaption("External ID"));
        if "Source System" <> xRec."Source System" then
            Error(ImmutableFieldChangedErr, "Entry No.", FieldCaption("Source System"));
        if "Created At" <> xRec."Created At" then
            Error(ImmutableFieldChangedErr, "Entry No.", FieldCaption("Created At"));
    end;

    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;

    procedure SetPayload(PayloadText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Payload);
        Payload.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(PayloadText);
    end;

    procedure GetPayload(): Text
    var
        InStream: InStream;
        PayloadText: Text;
    begin
        CalcFields(Payload);
        if not Payload.HasValue() then
            exit('');
        Payload.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(PayloadText);
        exit(PayloadText);
    end;
}
