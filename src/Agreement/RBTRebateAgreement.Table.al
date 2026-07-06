table 50101 "RBT Rebate Agreement"
{
    Caption = 'RBT Rebate Agreement';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get("Vendor No.") then
                    "Vendor Name" := Vendor.Name;
            end;
        }
        field(11; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            Editable = false;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
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
        field(50; "Calc. Method"; Enum "RBT Calc Method")
        {
            Caption = 'Calculation Method';
        }
        field(60; "Rebate %"; Decimal)
        {
            Caption = 'Rebate %';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Baseline Amount"; Decimal)
        {
            Caption = 'Baseline Amount';
        }
        field(80; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(90; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(100; "Signatory Code"; Code[20])
        {
            Caption = 'Signatory Code';
            TableRelation = "User Setup";
        }
        field(110; "Signed Date"; Date)
        {
            Caption = 'Signed Date';
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
        OldRec: Record "RBT Rebate Agreement";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        if OldRec.Get("No.") then
            if (OldRec.Status = OldRec.Status::Active) then begin
                CheckFieldLocking(OldRec);
                if "Rebate %" <> OldRec."Rebate %" then
                    RebateMgmt.CreateVersion(Rec);
            end else if (OldRec.Status <> OldRec.Status::Draft) and (OldRec.Status <> OldRec.Status::"Pending Approval") then
                CheckFieldLocking(OldRec);
    end;

    local procedure CheckFieldLocking(OldRec: Record "RBT Rebate Agreement")
    begin
        if "Vendor No." <> OldRec."Vendor No." then Error('Cannot change Vendor No. when status is %1', Status);
        if "Start Date" <> OldRec."Start Date" then Error('Cannot change Start Date when status is %1', Status);
        if "Calc. Method" <> OldRec."Calc. Method" then Error('Cannot change Calc. Method when status is %1', Status);
    end;
}