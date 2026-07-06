table 50107 "RBT Settlement Line"
{
    Caption = 'RBT Settlement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Settlement No."; Code[20])
        {
            Caption = 'Settlement No.';
            TableRelation = "RBT Settlement Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Accrual Entry No."; Integer)
        {
            Caption = 'Accrual Entry No.';
            TableRelation = "RBT Rebate Ledg Ent" where("Entry Type" = const(Accrual));

            trigger OnValidate()
            var
                LedgerEntry: Record "RBT Rebate Ledg Ent";
            begin
                if "Accrual Entry No." = 0 then
                    exit;
                LedgerEntry.Get("Accrual Entry No.");
                Amount := LedgerEntry.Amount;
                "Currency Code" := LedgerEntry."Currency Code";
                if Description = '' then
                    Description := CopyStr(LedgerEntry."Document No.", 1, MaxStrLen(Description));
            end;
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(40; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
    }

    keys
    {
        key(PK; "Settlement No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        CheckParentNotPosted();
    end;

    trigger OnModify()
    begin
        CheckParentNotPosted();
    end;

    trigger OnDelete()
    begin
        CheckParentNotPosted();
    end;

    local procedure CheckParentNotPosted()
    var
        SettlementHeader: Record "RBT Settlement Header";
    begin
        if not SettlementHeader.Get("Settlement No.") then
            exit;
        if SettlementHeader.Status = SettlementHeader.Status::Posted then
            Error('Cannot modify Settlement Line because parent settlement %1 is Posted.', "Settlement No.");
    end;
}
