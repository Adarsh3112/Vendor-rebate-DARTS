table 50110 "RBT Job Chunk"
{
    // Progress and failure log for a single chunk of the RBT Job Dispatcher.
    //
    // Each Calc Request whose calculations are processed in the background
    // owns a fan-out of RBT Job Chunk rows - one row per chunk of source lines.
    // The dispatcher COMMITs after each successful chunk so an interrupted job
    // (server restart, timeout, admin cancel) can resume from the last incomplete
    // chunk without redoing work that already succeeded. Failed chunks are kept
    // with their Error Message and Retry Count so they can be inspected on the
    // Job Monitor page and retried on demand.
    //
    // Immutability:
    //   - A Completed chunk cannot be modified or deleted through user code -
    //     its work is already reflected in the Calculation Ledger Entry table.
    //   - The internal SetAllowInternalEdit escape hatch is used exclusively by
    //     the dispatcher to flip a Failed chunk back to Pending on retry.

    Caption = 'RBT Job Chunk';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Job Chunks";
    DrillDownPageId = "RBT Job Chunks";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Calc Request No."; Code[20])
        {
            Caption = 'Calc Request No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Calc Request"."No.";
            NotBlank = true;
        }
        field(11; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";
        }
        field(20; "Chunk No."; Integer)
        {
            Caption = 'Chunk No.';
            DataClassification = CustomerContent;
        }
        field(21; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            DataClassification = CustomerContent;
            ToolTip = 'Lower bound (inclusive) of the source-line window covered by this chunk.';
        }
        field(22; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            DataClassification = CustomerContent;
            ToolTip = 'Upper bound (inclusive) of the source-line window covered by this chunk.';
        }
        field(30; Status; Enum "RBT Job Chunk Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = Pending;
        }
        field(31; "Records Processed"; Integer)
        {
            Caption = 'Records Processed';
            DataClassification = CustomerContent;
            InitValue = 0;
        }
        field(32; "Entries Created"; Integer)
        {
            Caption = 'Entries Created';
            DataClassification = CustomerContent;
            InitValue = 0;
        }
        field(40; "Error Message"; Text[500])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(41; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
            InitValue = 0;
        }
        field(50; "Started At"; DateTime)
        {
            Caption = 'Started At';
            DataClassification = CustomerContent;
        }
        field(51; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = CustomerContent;
        }
        field(60; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            DataClassification = CustomerContent;
            ToolTip = 'Correlates this chunk with the Job Queue Entry that scheduled it. Blank when the job is run inline (Process Now).';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CalcReqKey; "Calc Request No.", "Chunk No.") { }
        key(StatusKey; "Calc Request No.", Status) { }
        key(AgreementKey; "Agreement No.", Status) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Calc Request No.", "Chunk No.", Status) { }
        fieldgroup(Brick; "Calc Request No.", "Chunk No.", Status, "Records Processed", "Entries Created") { }
    }

    var
        AllowInternalEdit: Boolean;
        CompletedImmutableErr: Label 'Job Chunk %1 for Calc Request %2 is Completed and cannot be modified. Completed chunks are preserved for audit purposes.', Comment = '%1 = Chunk No., %2 = Calc Request No.';
        CompletedDeleteErr: Label 'Job Chunk %1 for Calc Request %2 is Completed and cannot be deleted. Completed chunks are preserved for audit purposes.', Comment = '%1 = Chunk No., %2 = Calc Request No.';

    trigger OnModify()
    begin
        if AllowInternalEdit then
            exit;
        // xRec holds the DB state prior to the modification. A Completed chunk
        // is immutable regardless of what the new record looks like.
        if xRec.Status = xRec.Status::Completed then
            Error(CompletedImmutableErr, "Chunk No.", "Calc Request No.");
    end;

    trigger OnDelete()
    begin
        if AllowInternalEdit then
            exit;
        if Status = Status::Completed then
            Error(CompletedDeleteErr, "Chunk No.", "Calc Request No.");
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used by the RBT Job Dispatcher
    /// when it must transition a chunk between states (e.g. Failed -> Pending
    /// on retry, Processing -> Completed on success). External callers must
    /// not call this - direct modifications to a Completed chunk fail with
    /// CompletedImmutableErr.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;
}
