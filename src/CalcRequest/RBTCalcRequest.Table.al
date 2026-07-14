table 50109 "RBT Calc Request"
{
    Caption = 'RBT Calc Request';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Calc Request List";
    DrillDownPageId = "RBT Calc Request List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                RebateSetup: Record "RBT Rebate Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    RebateSetup.GetSetup();
                    NoSeries.TestManual(RebateSetup."Calculation Request Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(10; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";

            trigger OnValidate()
            var
                Agreement: Record "RBT Rebate Agreement";
            begin
                if "Agreement No." = '' then begin
                    "Currency Code" := '';
                    exit;
                end;
                if Agreement.Get("Agreement No.") then
                    "Currency Code" := Agreement."Currency Code";
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = CustomerContent;
        }
        field(13; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = CustomerContent;
        }
        field(14; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(30; "Posting Status"; Enum "RBT Posting Status")
        {
            Caption = 'Posting Status';
            DataClassification = CustomerContent;
            InitValue = Open;
            Editable = false;
        }
        field(31; "No. of G/L Entries"; Integer)
        {
            Caption = 'No. of G/L Entries';
            DataClassification = CustomerContent;
            InitValue = 0;
            Editable = false;
        }
        field(32; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(35; "Settlement No."; Code[20])
        {
            Caption = 'Settlement No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "RBT Settlement Header"."No.";
        }
        field(40; "Total Accrual Amount"; Decimal)
        {
            Caption = 'Total Accrual Amount';
            FieldClass = FlowField;
            // Sums Calculated Amount from all Calculation Ledger Entries for the referenced Agreement.
            // Period-window filtering is applied inside the Posting Engine (AggregateAmount) at post time;
            // this FlowField provides an at-a-glance total on the Calc Request card and list.
            CalcFormula = sum("RBT Calculation Ledger Entry"."Calculated Amount" where("Agreement No." = field("Agreement No.")));
            Editable = false;
            AutoFormatType = 1;
        }
        field(50; "Total Chunks"; Integer)
        {
            Caption = 'Total Chunks';
            FieldClass = FlowField;
            // Total number of RBT Job Chunk rows the background dispatcher has planned
            // for this Calc Request. Zero until PlanChunks / ScheduleJob has run.
            CalcFormula = count("RBT Job Chunk" where("Calc Request No." = field("No.")));
            Editable = false;
        }
        field(51; "Completed Chunks"; Integer)
        {
            Caption = 'Completed Chunks';
            FieldClass = FlowField;
            // Number of chunks that finished without error. Combined with Total Chunks
            // and Failed Chunks, gives the operator an at-a-glance progress signal.
            CalcFormula = count("RBT Job Chunk" where("Calc Request No." = field("No."), Status = const(Completed)));
            Editable = false;
        }
        field(52; "Failed Chunks"; Integer)
        {
            Caption = 'Failed Chunks';
            FieldClass = FlowField;
            // Number of chunks currently in Failed status. Non-zero means the operator
            // should inspect Error Message on the RBT Job Chunks page and retry.
            CalcFormula = count("RBT Job Chunk" where("Calc Request No." = field("No."), Status = const(Failed)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(StatusKey; "Posting Status") { }
        key(AgreementKey; "Agreement No.") { }
        key(SettlementKey; "Settlement No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Agreement No.", "Posting Status") { }
        fieldgroup(Brick; "No.", Description, "Agreement No.", "Posting Status", "Total Accrual Amount") { }
    }

    var
        AllowInternalEdit: Boolean;
        MissingSeriesErr: Label 'Calculation Request Nos. is not set up. Open the RBT Rebate Setup page and specify a No. Series for Calculation Requests.';
        PostedImmutableErr: Label 'Calc Request %1 has Posting Status = Posted and cannot be modified. Create a new Calc Request to record further accruals.', Comment = '%1 = No.';
        PostedDeleteBlockedErr: Label 'Calc Request %1 has Posting Status = Posted and cannot be deleted. Posted calc requests are preserved for audit purposes.', Comment = '%1 = No.';

    trigger OnInsert()
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.GetSetup();
            if RebateSetup."Calculation Request Nos." = '' then
                Error(MissingSeriesErr);
            "No. Series" := RebateSetup."Calculation Request Nos.";
            "No." := NoSeries.GetNextNo("No. Series", 0D, true);
        end;
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
    end;

    trigger OnModify()
    begin
        if AllowInternalEdit then
            exit;
        // xRec holds the record state prior to this modification. Immutability is based on
        // the pre-modify DB Posting Status - a user cannot bypass the block by flipping
        // Posting Status back to Open in the same Modify call.
        if xRec."Posting Status" = xRec."Posting Status"::Posted then
            Error(PostedImmutableErr, "No.");
    end;

    trigger OnDelete()
    begin
        if AllowInternalEdit then
            exit;
        if "Posting Status" = "Posting Status"::Posted then
            Error(PostedDeleteBlockedErr, "No.");
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used by the RBT Posting Engine
    /// when it must stamp Posting Status, No. of G/L Entries, and Document No.
    /// immediately after a successful posting.
    /// External callers never call this - direct modifications to a Posted
    /// Calc Request fail with PostedImmutableErr.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;

    procedure AssistEdit(): Boolean
    var
        CalcRequest: Record "RBT Calc Request";
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        RebateSetup.GetSetup();
        CalcRequest := Rec;
        if NoSeries.LookupRelatedNoSeries(RebateSetup."Calculation Request Nos.", xRec."No. Series", CalcRequest."No. Series") then begin
            CalcRequest."No." := NoSeries.GetNextNo(CalcRequest."No. Series", 0D, true);
            Rec := CalcRequest;
            exit(true);
        end;
    end;

    /// <summary>
    /// Convenience accessor: returns TRUE while the Calc Request has not yet been posted.
    /// Bound to the Editable page property so header fields become read-only after posting.
    /// </summary>
    procedure IsEditable(): Boolean
    begin
        exit("Posting Status" <> "Posting Status"::Posted);
    end;
}
