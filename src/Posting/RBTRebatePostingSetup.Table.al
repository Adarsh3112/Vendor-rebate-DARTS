table 50109 "RBT Rebate Post Set"
{
    Caption = 'RBT Rebate Post Set';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Post Set";
    DrillDownPageId = "RBT Rebate Post Set";

    fields
    {
        field(1; "Rebate Group Code"; Code[20])
        {
            Caption = 'Rebate Group Code';
            NotBlank = false;
        }
        field(10; "Accrual Account No."; Code[20])
        {
            Caption = 'Accrual Account No.';
            TableRelation = "G/L Account";
        }
        field(20; "Expense Account No."; Code[20])
        {
            Caption = 'Expense Account No.';
            TableRelation = "G/L Account";
        }
        field(30; "Receivable Account No."; Code[20])
        {
            Caption = 'Receivable Account No.';
            TableRelation = "G/L Account";
        }
        field(40; "Payable Account No."; Code[20])
        {
            Caption = 'Payable Account No.';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(PK; "Rebate Group Code")
        {
            Clustered = true;
        }
    }

    procedure GetPostingSetup(RebateGroupCode: Code[20]): Boolean
    var
        PostingSetup: Record "RBT Rebate Post Set";
    begin
        if PostingSetup.Get(RebateGroupCode) then begin
            Rec := PostingSetup;
            exit(true);
        end;

        if RebateGroupCode <> '' then
            if PostingSetup.Get('') then begin
                Rec := PostingSetup;
                exit(true);
            end;

        Error('No Rebate Posting Setup exists for %1.', RebateGroupCode);
    end;
}
