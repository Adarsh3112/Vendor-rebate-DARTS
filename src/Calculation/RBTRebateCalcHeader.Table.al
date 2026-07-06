table 50105 "RBT Rebate Calc Hdr"
{
    Caption = 'RBT Rebate Calc Hdr';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(10; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
        }
        field(20; "Calc. From Date"; Date)
        {
            Caption = 'Calc. From Date';
        }
        field(21; "Calc. To Date"; Date)
        {
            Caption = 'Calc. To Date';
        }
        field(30; "Posting Status"; Option)
        {
            Caption = 'Posting Status';
            OptionMembers = Open,Posted;
        }
        field(40; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            Editable = false;
        }
        field(50; "No. of G/L Entries"; Integer)
        {
            Caption = 'No. of G/L Entries';
            Editable = false;
        }
        field(60; "No. Series"; Code[20])
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
            RebateSetup.TestField("Calculation Nos.");
            "No." := NoSeries.GetNextNo(RebateSetup."Calculation Nos.");
            "No. Series" := RebateSetup."Calculation Nos.";
        end;
    end;

    trigger OnModify()
    var
        OldRec: Record "RBT Rebate Calc Hdr";
    begin
        if OldRec.Get("No.") then
            if OldRec."Posting Status" = OldRec."Posting Status"::Posted then
                Error('Calculation %1 has already been posted and cannot be modified.', "No.");
    end;
}
