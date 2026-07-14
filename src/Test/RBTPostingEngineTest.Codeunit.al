codeunit 50107 "RBT Posting Engine Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test coverage for RBT Posting Engine (codeunit 50101).
    //
    // Fixture strategy mirrors RBTRuleEngineTest:
    //   Initialize() seeds Setup + No. Series via RBT Install, creates two G/L Accounts
    //   (Accrual Expense + Accrual Liability) and a Posting Setup row keyed by a test
    //   Posting Group + blank Currency Code. Each [Test] procedure then builds its own
    //   activated agreement, a Percentage rule, a matching Purchase Invoice Line, runs
    //   the Rule Engine to seed Calculation Ledger Entries, and creates an RBT Calc
    //   Request whose period window covers the seeded entries.
    //
    // BC's test runner rolls back the transaction after each test, so tests remain
    // independent without explicit cleanup.

    var
        UniqueSeq: Integer;

    // Inline assertion helpers - the sandbox package set does not ship the Microsoft
    // test libraries. We implement the small subset of assertions needed locally.
    local procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1. Expected: %2. Actual: %3.', Comment = '%1 = assertion message, %2 = expected value, %3 = actual value';
    begin
        if Format(Expected) <> Format(Actual) then
            Error(AssertionFailedErr, Msg, Format(Expected), Format(Actual));
    end;

    local procedure AssertTrue(Condition: Boolean; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1.', Comment = '%1 = assertion message';
    begin
        if not Condition then
            Error(AssertionFailedErr, Msg);
    end;

    local procedure ContainsSubstring(Source: Text; Needle: Text): Boolean
    begin
        exit(StrPos(Source, Needle) > 0);
    end;

    // =============== [Test] procedures =====================================================

    [Test]
    procedure TestPostAccrualHappyPath()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        GLEntry: Record "G/L Entry";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        SumAmount: Decimal;
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);

        PostingEngine.PostAccrual(CalcRequest);

        CalcRequest.Get(CalcRequest."No.");
        AreEqual(CalcRequest."Posting Status"::Posted, CalcRequest."Posting Status", 'Posting Status must be Posted after PostAccrual.');
        AreEqual(2, CalcRequest."No. of G/L Entries", 'No. of G/L Entries must be 2 (debit + credit).');
        AssertTrue(CalcRequest."Document No." <> '', 'Document No. must be populated after posting.');

        // Two G/L entries for the accrual document, balanced.
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        AreEqual(2, GLEntry.Count(), 'Exactly two G/L Entry rows must exist for the accrual Document No.');
        GLEntry.CalcSums(Amount);
        AreEqual(0, GLEntry.Amount, 'Debit + Credit must sum to zero (balanced posting).');

        SumAmount := 0;
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", ExpenseAccNo);
        GLEntry.CalcSums(Amount);
        AssertTrue(GLEntry.Amount > 0, 'Expense account G/L Entry must be a positive debit.');

        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", LiabAccNo);
        GLEntry.CalcSums(Amount);
        AssertTrue(GLEntry.Amount < 0, 'Liability account G/L Entry must be a negative credit.');
    end;

    [Test]
    procedure TestPostAccrualDuplicateRejected()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        ExpectedNo: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);

        PostingEngine.PostAccrual(CalcRequest);
        CalcRequest.Get(CalcRequest."No.");
        ExpectedNo := CalcRequest."No.";

        asserterror PostingEngine.PostAccrual(CalcRequest);
        AssertTrue(ContainsSubstring(GetLastErrorText(), ExpectedNo),
            'Duplicate-post error must name the Calc Request No.');
    end;

    [Test]
    procedure TestPostAccrualMissingPostingSetupBlocks()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        PostingSetup: Record "RBT Posting Setup";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);

        // Remove the posting setup for this group / blank currency to force the missing-setup path.
        if PostingSetup.Get(PostingGroup, '') then
            PostingSetup.Delete();

        asserterror PostingEngine.PostAccrual(CalcRequest);
        AssertTrue(ContainsSubstring(GetLastErrorText(), 'Posting Setup') or
                   ContainsSubstring(GetLastErrorText(), 'Rebate Posting Setup'),
            'Missing-setup error text must reference Posting Setup.');
    end;

    [Test]
    procedure TestPostAccrualBlankAccountsBlocks()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        PostingSetup: Record "RBT Posting Setup";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);

        // Blank the Accrual Expense Acc. so TestField(Accrual Expense Acc.) fires.
        PostingSetup.Get(PostingGroup, '');
        PostingSetup."Accrual Expense Acc." := '';
        PostingSetup.Modify();

        asserterror PostingEngine.PostAccrual(CalcRequest);
        AssertTrue(ContainsSubstring(GetLastErrorText(), 'Accrual Expense Acc.'),
            'Blank-account error must name Accrual Expense Acc.');
    end;

    [Test]
    procedure TestPreviewLeavesCalcRequestOpen()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        GLEntry: Record "G/L Entry";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        DocNoBefore: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);
        DocNoBefore := CalcRequest."Document No.";

        // Preview infrastructure deliberately raises a preview-completed error to roll back.
        asserterror PostingEngine.PreviewAccrual(CalcRequest);

        CalcRequest.Get(CalcRequest."No.");
        AreEqual(CalcRequest."Posting Status"::Open, CalcRequest."Posting Status",
            'Posting Status must remain Open after PreviewAccrual.');
        AreEqual(0, CalcRequest."No. of G/L Entries", 'No. of G/L Entries must remain 0 after preview.');
        AreEqual(DocNoBefore, CalcRequest."Document No.",
            'Document No. must not change after preview.');

        // No persistent G/L Entry for anything under the calc request agreement in this test.
        GLEntry.Reset();
        GLEntry.SetFilter(Description, StrSubstNo('Rebate Accrual %1', CalcRequest."No."));
        AreEqual(0, GLEntry.Count(), 'No G/L Entry rows must persist for a preview.');
    end;

    [Test]
    procedure TestNothingToPostRaisesError()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        // Build an agreement + calc request but do NOT seed any Calc Ledger Entries.
        BuildFixtureWithoutLedgerEntries(Agreement, CalcRequest, PostingGroup);

        asserterror PostingEngine.PostAccrual(CalcRequest);
        AssertTrue(ContainsSubstring(GetLastErrorText(), CalcRequest."No."),
            'Nothing-to-post error must name the Calc Request No.');
    end;

    // =============== Fixture helpers =======================================================

    local procedure Initialize(var ExpenseAccNo: Code[20]; var LiabAccNo: Code[20]; var PostingGroup: Code[20])
    var
        RBTInstall: Codeunit "RBT Install";
        PostingSetup: Record "RBT Posting Setup";
    begin
        RBTInstall.InitializeSetup();
        UniqueSeq += 1;

        ExpenseAccNo := EnsureGLAccount('EXP');
        LiabAccNo := EnsureGLAccount('LIA');
        PostingGroup := UniqueCode20('PG');

        if not PostingSetup.Get(PostingGroup, '') then begin
            PostingSetup.Init();
            PostingSetup."Posting Group" := PostingGroup;
            PostingSetup."Currency Code" := '';
            PostingSetup."Accrual Expense Acc." := ExpenseAccNo;
            PostingSetup."Accrual Liab. Acc." := LiabAccNo;
            PostingSetup."Settlement Acc." := ExpenseAccNo;
            PostingSetup.Insert();
        end else begin
            PostingSetup."Accrual Expense Acc." := ExpenseAccNo;
            PostingSetup."Accrual Liab. Acc." := LiabAccNo;
            PostingSetup."Settlement Acc." := ExpenseAccNo;
            PostingSetup.Modify();
        end;
    end;

    local procedure BuildFixture(var Agreement: Record "RBT Rebate Agreement"; var CalcRequest: Record "RBT Calc Request"; PostingGroup: Code[20]; BaseAmount: Decimal; Percentage: Decimal)
    var
        Rule: Record "RBT Rebate Rule";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
    begin
        VendorNo := EnsureVendor();
        CreateActiveVendorAgreement(Agreement, VendorNo, PostingGroup);
        CreatePercentageRule(Rule, Agreement, Percentage);
        // Directly insert a Calculation Ledger Entry that the engine will aggregate.
        InsertLedgerEntry(LedgerEntry, Agreement, Rule, BaseAmount, Percentage);

        CreateCalcRequest(CalcRequest, Agreement);
    end;

    local procedure BuildFixtureWithoutLedgerEntries(var Agreement: Record "RBT Rebate Agreement"; var CalcRequest: Record "RBT Calc Request"; PostingGroup: Code[20])
    var
        VendorNo: Code[20];
    begin
        VendorNo := EnsureVendor();
        CreateActiveVendorAgreement(Agreement, VendorNo, PostingGroup);
        CreateCalcRequest(CalcRequest, Agreement);
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; PostingGroup: Code[20])
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Posting Engine Test Agreement';
        Agreement."Type" := Agreement."Type"::"Vendor Rebate";
        Agreement."Vendor No." := VendorNo;
        Agreement."Start Date" := WorkDate() - 30;
        Agreement."End Date" := WorkDate() + 30;
        Agreement."Currency Code" := '';
        Agreement."Posting Group" := PostingGroup;
        Agreement.Modify();
        VersionMgt.ActivateAgreement(Agreement);
        Agreement.Find();
    end;

    local procedure CreatePercentageRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; Percentage: Decimal)
    var
        NextLineNo: Integer;
        ExistingRule: Record "RBT Rebate Rule";
    begin
        ExistingRule.SetRange("Agreement No.", Agreement."No.");
        if ExistingRule.FindLast() then
            NextLineNo := ExistingRule."Line No." + 10000
        else
            NextLineNo := 10000;
        Rule.Init();
        Rule."Agreement No." := Agreement."No.";
        Rule."Line No." := NextLineNo;
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Percentage := Percentage;
        Rule.Insert();
    end;

    local procedure InsertLedgerEntry(var LedgerEntry: Record "RBT Calculation Ledger Entry"; var Agreement: Record "RBT Rebate Agreement"; var Rule: Record "RBT Rebate Rule"; BaseAmount: Decimal; Percentage: Decimal)
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        CurrentVersion: Record "RBT Rebate Version";
    begin
        VersionMgt.GetCurrentVersion(Agreement."No.", CurrentVersion);
        LedgerEntry.Init();
        LedgerEntry."Source Type" := LedgerEntry."Source Type"::"Purchase Invoice";
        LedgerEntry."Source Document No." := UniqueCode20('D');
        LedgerEntry."Source Document Line No." := 10000;
        LedgerEntry."Posting Date" := WorkDate();
        LedgerEntry."Agreement No." := Agreement."No.";
        LedgerEntry."Agreement Version No." := CurrentVersion."Version No.";
        LedgerEntry."Rule Line No." := Rule."Line No.";
        LedgerEntry."Calculation Method" := LedgerEntry."Calculation Method"::Percentage;
        LedgerEntry."Base Amount" := BaseAmount;
        LedgerEntry.Percentage := Percentage;
        LedgerEntry."Calculated Amount" := BaseAmount * Percentage / 100;
        LedgerEntry."Currency Code" := Agreement."Currency Code";
        LedgerEntry.SetAllowInternalEdit(true);
        LedgerEntry.Insert(true);
        LedgerEntry.SetAllowInternalEdit(false);
    end;

    local procedure CreateCalcRequest(var CalcRequest: Record "RBT Calc Request"; var Agreement: Record "RBT Rebate Agreement")
    begin
        CalcRequest.Init();
        CalcRequest."No." := '';
        CalcRequest.Insert(true);
        CalcRequest.Description := 'RBT Posting Engine Test Request';
        CalcRequest.Validate("Agreement No.", Agreement."No.");
        CalcRequest."Period Start" := WorkDate() - 30;
        CalcRequest."Period End" := WorkDate() + 30;
        CalcRequest."Posting Date" := WorkDate();
        CalcRequest.Modify();
    end;

    local procedure EnsureGLAccount(Prefix: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
        AccountNo: Code[20];
    begin
        AccountNo := UniqueCode20(Prefix);
        if GLAccount.Get(AccountNo) then
            exit(AccountNo);
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount.Name := 'RBT Test Account ' + Prefix;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := true;
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Insert();
        exit(AccountNo);
    end;

    local procedure EnsureVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        VendorNo := UniqueCode20('V');
        if Vendor.Get(VendorNo) then
            exit(VendorNo);
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Name := 'RBT Test Vendor';
        Vendor.Insert();
        exit(VendorNo);
    end;

    local procedure UniqueCode20(Prefix: Text): Code[20]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq), 1, 20));
    end;
}
