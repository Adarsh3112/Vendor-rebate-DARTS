table 50101 "RBT Rebate Agreement"
{
    Caption = 'RBT Rebate Agreement';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Agreement Card";
    DrillDownPageId = "RBT Rebate Agreement Card";

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
                    NoSeries.TestManual(RebateSetup."Rebate Agreement Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Type"; Enum "RBT Agreement Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(4; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(5; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Start Date" <> 0D) and ("End Date" <> 0D) and ("End Date" < "Start Date") then
                    Error(EndDateBeforeStartErr, "No.");
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Start Date" <> 0D) and ("End Date" <> 0D) and ("End Date" < "Start Date") then
                    Error(EndDateBeforeStartErr, "No.");
            end;
        }
        field(8; Status; Enum "RBT Agreement Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = Draft;
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(10; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = CustomerContent;
        }
        field(20; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(30; "Signatory Code"; Code[50])
        {
            Caption = 'Signatory Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
            ValidateTableRelation = true;
            ToolTip = 'User Setup code of the person who signed this agreement. Mandatory before activation.';
        }
        field(31; "Signed Date"; Date)
        {
            Caption = 'Signed Date';
            DataClassification = CustomerContent;
            ToolTip = 'Date on which this agreement was physically signed. Must be on or before today before activation.';

            trigger OnValidate()
            begin
                if ("Signed Date" <> 0D) and ("Signed Date" > WorkDate()) then
                    Error(SignedDateFutureErr, "No.");
            end;
        }
        field(40; "Sent For Approval Date"; DateTime)
        {
            Caption = 'Sent For Approval Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Sent For Approval By"; Code[50])
        {
            Caption = 'Sent For Approval By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(42; "Approved Date"; DateTime)
        {
            Caption = 'Approved Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(43; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(VendorKey; "Vendor No.", "Start Date") { }
        key(CustomerKey; "Customer No.", "Start Date") { }
        key(StatusKey; Status) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Vendor No.", "Customer No.", Status) { }
        fieldgroup(Brick; "No.", Description, "Vendor No.", "Customer No.", Status) { }
    }

    var
        AllowInternalEdit: Boolean;
        EndDateBeforeStartErr: Label 'On agreement %1, End Date cannot be earlier than Start Date. Adjust the dates on the Rebate Agreement Card.';
        MissingSeriesErr: Label 'Rebate Agreement Nos. is not set up. Open the RBT Rebate Setup page and specify a No. Series for Rebate Agreements.';
        SignedDateFutureErr: Label 'On agreement %1, Signed Date cannot be a future date. Enter the actual signing date on the RBT Rebate Agreement Card.';

    trigger OnInsert()
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.GetSetup();
            if RebateSetup."Rebate Agreement Nos." = '' then
                Error(MissingSeriesErr);
            "No. Series" := RebateSetup."Rebate Agreement Nos.";
            "No." := NoSeries.GetNextNo("No. Series", 0D, true);
        end;
    end;

    trigger OnModify()
    var
        OldRec: Record "RBT Rebate Agreement";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        // xRec holds the previous state of the record before this modification.
        OldRec := xRec;
        // When the internal-edit escape hatch is on (used by activation, approval workflow),
        // skip versioning side-effects so the state transitions themselves do not trigger a new version.
        if AllowInternalEdit then
            exit;
        VersionMgt.HandleAgreementModify(Rec, OldRec);
    end;

    /// <summary>
    /// Toggles the internal-edit escape hatch used by RBT Rebate Version Mgt. and
    /// the RBT Rebate Agreement Approval codeunit when they must stamp workflow
    /// fields (Status, Sent For Approval Date/By, Approved Date/By) without
    /// triggering the versioning OnModify guard.
    /// External callers never call this - direct modifications while the flag is
    /// off go through HandleAgreementModify.
    /// </summary>
    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;

    /// <summary>
    /// Returns TRUE while the agreement is still editable by end-users.
    /// Draft and Pending Approval states allow header edits; Approved/Active/Closed
    /// force the workflow.
    /// </summary>
    procedure IsEditable(): Boolean
    begin
        exit(Status in [Status::Draft, Status::"Pending Approval"]);
    end;

    procedure AssistEdit(): Boolean
    var
        RebateAgreement: Record "RBT Rebate Agreement";
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        RebateSetup.GetSetup();
        RebateAgreement := Rec;
        if NoSeries.LookupRelatedNoSeries(RebateSetup."Rebate Agreement Nos.", xRec."No. Series", RebateAgreement."No. Series") then begin
            RebateAgreement."No." := NoSeries.GetNextNo(RebateAgreement."No. Series", 0D, true);
            Rec := RebateAgreement;
            exit(true);
        end;
    end;
}
