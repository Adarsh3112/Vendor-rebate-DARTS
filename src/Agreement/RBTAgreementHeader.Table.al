table 50102 "RBT Agreement Header"
{
    Caption = 'RBT Agreement Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Type"; Enum "RBT Agreement Type")
        {
            Caption = 'Type';
        }
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(15; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(20; "Customer Group"; Code[20])
        {
            Caption = 'Customer Group';
            TableRelation = "Customer Price Group";
        }
        field(30; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(31; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(40; Status; Enum "RBT Agreement Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(50; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Type" = const(Vendor)) "Vendor Posting Group"
                            else if ("Type" = const(Customer)) "Customer Posting Group";
        }
        field(60; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(70; "Signatory Code"; Code[50])
        {
            Caption = 'Signatory Code';
            TableRelation = "User Setup";
        }
        field(80; "Signed Date"; Date)
        {
            Caption = 'Signed Date';
        }
        field(90; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(100; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            TableRelation = "Country/Region";
        }
        field(110; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.Get();
            RebateSetup.TestField("Agreement Nos.");
            "No." := NoSeries.GetNextNo(RebateSetup."Agreement Nos.");
            "No. Series" := RebateSetup."Agreement Nos.";
        end;
    end;

    trigger OnModify()
    var
        OldRec: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        if not OldRec.Get("No.") then
            exit;

        // Status transitions issued by the management codeunit (Draft|Pending|...
        // -> Active) are allowed through unconditionally. The codeunit calls
        // CreateNewVersion itself in that path, so we must not re-spawn a
        // version here when the only change is the Status field.
        if OldRec.Status <> Status then
            exit;

        // FR-002: every edit to an Active agreement spawns a new immutable
        // version snapshot before any field-locking check runs. CheckFieldLocking
        // for the Active branch is intentionally relaxed - the new version row
        // becomes the audit record of what changed.
        if OldRec.Status = OldRec.Status::Active then begin
            if HasBusinessChange(OldRec) then begin
                CheckFieldLocking(OldRec);
                RebateMgmt.CreateNewVersion(Rec);
            end;
            exit;
        end;

        // For every other non-Draft status (Pending Approval, Closed, Suspended,
        // Expired) the historical field-locking rules continue to apply.
        if OldRec.Status <> OldRec.Status::Draft then
            CheckFieldLocking(OldRec);
    end;

    local procedure HasBusinessChange(OldRec: Record "RBT Agreement Header"): Boolean
    begin
        exit(
            ("Vendor No." <> OldRec."Vendor No.") or
            ("Customer No." <> OldRec."Customer No.") or
            ("Customer Group" <> OldRec."Customer Group") or
            ("Start Date" <> OldRec."Start Date") or
            ("End Date" <> OldRec."End Date") or
            ("Type" <> OldRec."Type") or
            ("Posting Group" <> OldRec."Posting Group") or
            ("Currency Code" <> OldRec."Currency Code") or
            ("Location Code" <> OldRec."Location Code") or
            ("Country Code" <> OldRec."Country Code") or
            ("Signatory Code" <> OldRec."Signatory Code") or
            ("Signed Date" <> OldRec."Signed Date"));
    end;

    local procedure CheckFieldLocking(OldRec: Record "RBT Agreement Header")
    begin
        if "Vendor No." <> OldRec."Vendor No." then
            Error('Cannot change Vendor No. when status is %1', Status);
        if "Customer No." <> OldRec."Customer No." then
            Error('Cannot change Customer No. when status is %1', Status);
        if "Type" <> OldRec."Type" then
            Error('Cannot change Type when status is %1', Status);
        if "Start Date" <> OldRec."Start Date" then
            Error('Cannot change Start Date when status is %1', Status);
        if "Currency Code" <> OldRec."Currency Code" then
            Error('Cannot change Currency Code when status is %1', Status);
    end;
}
