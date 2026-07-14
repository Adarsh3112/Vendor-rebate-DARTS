table 50104 "RBT Posting Setup"
{
    Caption = 'RBT Posting Setup';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Posting Setup";
    DrillDownPageId = "RBT Rebate Posting Setup";

    fields
    {
        field(1; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(10; "Accrual Expense Acc."; Code[20])
        {
            Caption = 'Accrual Expense Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAccount("Accrual Expense Acc.");
            end;
        }
        field(20; "Accrual Liab. Acc."; Code[20])
        {
            Caption = 'Accrual Liab. Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAccount("Accrual Liab. Acc.");
            end;
        }
        field(30; "Settlement Acc."; Code[20])
        {
            Caption = 'Settlement Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAccount("Settlement Acc.");
            end;
        }
    }

    keys
    {
        key(PK; "Posting Group", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Posting Group", "Currency Code", "Accrual Expense Acc.", "Accrual Liab. Acc.", "Settlement Acc.")
        {
        }
    }

    var
        AccountNotPostingErr: Label 'G/L Account %1 must be a Posting account to be used on Rebate Posting Setup.', Comment = '%1 = G/L Account No.';

    local procedure CheckGLAccount(AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if AccountNo = '' then
            exit;
        GLAccount.Get(AccountNo);
        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            Error(AccountNotPostingErr, AccountNo);
        GLAccount.CheckGLAcc();
    end;

    /// <summary>
    /// Retrieves the Rebate Posting Setup record for the given Posting Group and Currency Code combination.
    /// If no specific match is found, falls back to the same Posting Group with a blank Currency Code.
    /// Raises an error naming the exact setup page and record required if no match is found at all.
    /// </summary>
    /// <param name="PostingGroup">The Posting Group to look up.</param>
    /// <param name="CurrencyCode">The Currency Code to look up. Blank means local currency.</param>
    procedure GetPostingSetup(PostingGroup: Code[20]; CurrencyCode: Code[10])
    var
        PostingSetupMissingErr: Label 'Rebate Posting Setup for Posting Group %1 and Currency Code %2 does not exist. Create it on the Rebate Posting Setup page.', Comment = '%1 = Posting Group, %2 = Currency Code';
    begin
        if Rec.Get(PostingGroup, CurrencyCode) then
            exit;
        if Rec.Get(PostingGroup, '') then
            exit;
        Error(PostingSetupMissingErr, PostingGroup, CurrencyCode);
    end;

    /// <summary>
    /// Validates that all three G/L account fields are populated on this Rebate Posting Setup record.
    /// </summary>
    procedure TestAccounts()
    begin
        Rec.TestField("Accrual Expense Acc.");
        Rec.TestField("Accrual Liab. Acc.");
        Rec.TestField("Settlement Acc.");
    end;
}
