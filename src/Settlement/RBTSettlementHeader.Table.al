table 50106 "RBT Settlement Header"
{
    Caption = 'RBT Settlement Header';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Settlement List";
    DrillDownPageId = "RBT Settlement List";

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
                    NoSeries.TestManual(RebateSetup."Settlement Nos.");
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
                if "Agreement No." = '' then
                    exit;
                if Agreement.Get("Agreement No.") then begin
                    "Vendor No." := Agreement."Vendor No.";
                    "Customer No." := Agreement."Customer No.";
                    "Currency Code" := Agreement."Currency Code";
                    "Posting Group" := Agreement."Posting Group";
                end;
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
            DataClassification = CustomerContent;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(14; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(15; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(17; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = CustomerContent;
        }
        field(20; Status; Enum "RBT Settlement Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = Draft;
            Editable = false;
        }
        field(21; "Sent For Approval Date"; DateTime)
        {
            Caption = 'Sent For Approval Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "Sent For Approval By"; Code[50])
        {
            Caption = 'Sent For Approval By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(23; "Approved Date"; DateTime)
        {
            Caption = 'Approved Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(25; "Posted Date"; DateTime)
        {
            Caption = 'Posted Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(30; "Credit Memo Document Type"; Option)
        {
            Caption = 'Credit Memo Document Type';
            OptionCaption = ' ,Purchase,Sales';
            OptionMembers = " ",Purchase,Sales;
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(31; "Posted Credit Memo No."; Code[20])
        {
            Caption = 'Posted Credit Memo No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            FieldClass = FlowField;
            CalcFormula = sum("RBT Settlement Line".Amount where("Settlement No." = field("No.")));
            Editable = false;
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(StatusKey; Status) { }
        key(AgreementKey; "Agreement No.") { }
        key(VendorKey; "Vendor No.") { }
        key(CustomerKey; "Customer No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Agreement No.", Status) { }
        fieldgroup(Brick; "No.", Description, "Agreement No.", Status, "Total Amount") { }
    }

    var
        AllowInternalEdit: Boolean;
        MissingSeriesErr: Label 'Settlement Nos. is not set up. Open the RBT Rebate Setup page and specify a No. Series for Settlements.';
        PostedImmutableErr: Label 'Settlement %1 has Status = Posted and cannot be modified. Posted settlements are preserved for audit purposes.', Comment = '%1 = No.';
        PostedDeleteBlockedErr: Label 'Settlement %1 has Status = Posted and cannot be deleted. Posted settlements are preserved for audit purposes.', Comment = '%1 = No.';

    trigger OnInsert()
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.GetSetup();
            if RebateSetup."Settlement Nos." = '' then
                Error(MissingSeriesErr);
            "No. Series" := RebateSetup."Settlement Nos.";
            "No." := NoSeries.GetNextNo("No. Series", 0D, true);
        end;
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        if "Settlement Date" = 0D then
            "Settlement Date" := WorkDate();
    end;

    trigger OnModify()
    begin
        if AllowInternalEdit then
            exit;
        // xRec holds the record state prior to this modification. Once the header
        // has transitioned to Posted, no further edits are allowed except through
        // the internal-edit escape hatch used by the Settlement Engine itself.
        if xRec.Status = xRec.Status::Posted then
            Error(PostedImmutableErr, "No.");
    end;

    trigger OnDelete()
    begin
        if AllowInternalEdit then
            exit;
        if Status = Status::Posted then
            Error(PostedDeleteBlockedErr, "No.");
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used by the RBT Settlement Engine
    /// when it must stamp Status = Posted, Posted Credit Memo No. and Posted Date/By
    /// immediately after a successful posting.
    /// External callers never call this - direct modifications to a Posted
    /// Settlement fail with PostedImmutableErr.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;

    /// <summary>
    /// Returns TRUE while the settlement is still in Draft status.
    /// Bound to page Editable properties so header fields become read-only once approval/posting starts.
    /// </summary>
    procedure IsEditable(): Boolean
    begin
        exit(Status = Status::Draft);
    end;

    procedure AssistEdit(): Boolean
    var
        Settlement: Record "RBT Settlement Header";
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        RebateSetup.GetSetup();
        Settlement := Rec;
        if NoSeries.LookupRelatedNoSeries(RebateSetup."Settlement Nos.", xRec."No. Series", Settlement."No. Series") then begin
            Settlement."No." := NoSeries.GetNextNo(Settlement."No. Series", 0D, true);
            Rec := Settlement;
            exit(true);
        end;
    end;
}
