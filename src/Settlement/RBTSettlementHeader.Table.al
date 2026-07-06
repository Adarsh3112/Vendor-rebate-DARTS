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
        }
        field(10; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = "RBT Agreement Header";

            trigger OnValidate()
            var
                AgreementHeader: Record "RBT Agreement Header";
            begin
                if "Agreement No." = '' then
                    exit;
                AgreementHeader.Get("Agreement No.");
                "Type" := AgreementHeader."Type";
                "Currency Code" := AgreementHeader."Currency Code";
                case AgreementHeader."Type" of
                    AgreementHeader."Type"::Vendor:
                        "Vendor/Customer No." := AgreementHeader."Vendor No.";
                    AgreementHeader."Type"::Customer:
                        "Vendor/Customer No." := AgreementHeader."Customer No.";
                end;
            end;
        }
        field(15; "Type"; Enum "RBT Agreement Type")
        {
            Caption = 'Type';
        }
        field(20; "Vendor/Customer No."; Code[20])
        {
            Caption = 'Vendor/Customer No.';
            TableRelation = if ("Type" = const(Vendor)) Vendor
                            else if ("Type" = const(Customer)) Customer;
        }
        field(30; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
        }
        field(40; Status; Enum "RBT Settlement Status")
        {
            Caption = 'Status';
            Editable = false;
            InitValue = Draft;
        }
        field(50; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(70; "Credit Memo Type"; Option)
        {
            Caption = 'Credit Memo Type';
            OptionMembers = " ",Purchase,Sales;
            OptionCaption = ' ,Purchase,Sales';
        }
        field(71; "Credit Memo No."; Code[20])
        {
            Caption = 'Credit Memo No.';
        }
        field(72; "Posted Credit Memo No."; Code[20])
        {
            Caption = 'Posted Credit Memo No.';
        }
        field(80; "No. Series"; Code[20])
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
            RebateSetup.GetSetup();
            RebateSetup.TestField("Settlement Nos.");
            "No." := NoSeries.GetNextNo(RebateSetup."Settlement Nos.", WorkDate());
            "No. Series" := RebateSetup."Settlement Nos.";
        end;
    end;

    trigger OnModify()
    var
        OldRec: Record "RBT Settlement Header";
    begin
        if Status = Status::Posted then begin
            if not OldRec.Get("No.") then
                exit;
            // Allow only the controlled write path that finalises posting:
            // the management codeunit transitions from Pending to Posted.
            if OldRec.Status = Status::Posted then
                Error('Settlement %1 has been posted and cannot be modified.', "No.");
            exit;
        end;

        if not OldRec.Get("No.") then
            exit;

        if OldRec.Status <> OldRec.Status::Draft then begin
            if "Agreement No." <> OldRec."Agreement No." then
                Error('Cannot change Agreement No. when status is %1.', OldRec.Status);
            if "Vendor/Customer No." <> OldRec."Vendor/Customer No." then
                Error('Cannot change Vendor/Customer No. when status is %1.', OldRec.Status);
            if Amount <> OldRec.Amount then
                Error('Cannot change Amount when status is %1.', OldRec.Status);
            if "Type" <> OldRec."Type" then
                Error('Cannot change Type when status is %1.', OldRec.Status);
        end;
    end;

    trigger OnDelete()
    var
        SettlementLine: Record "RBT Settlement Line";
    begin
        if Status = Status::Posted then
            Error('Settlement %1 has been posted and cannot be deleted.', "No.");

        if Status = Status::Draft then begin
            SettlementLine.SetRange("Settlement No.", "No.");
            if not SettlementLine.IsEmpty() then
                SettlementLine.DeleteAll();
        end;
    end;
}
