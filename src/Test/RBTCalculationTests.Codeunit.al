codeunit 50105 "RBT Calculation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Automated Test Coverage - Task 239.
    //
    // Covers the three acceptance-criteria scenarios end-to-end using the same
    // fixture pattern established by the existing RBT test codeunits:
    //
    //   1. TestPositiveAccrualCalculation      - happy path: active agreement + rule +
    //                                             seeded Calc Ledger Entry -> PostAccrual
    //                                             creates a balanced two-line G/L journal.
    //   2. TestBlockedDuplicatePosting          - second PostAccrual on the same Calc
    //                                             Request raises an explicit error and
    //                                             does not create additional G/L entries.
    //   3. TestNegativeActivationMissingSignatory - ActivateAgreement fails with a clear
    //                                             error when Signatory Code is blank; the
    //                                             agreement remains in Draft.
    //
    // Object naming: this codeunit is assigned ID 50105 as required by the task
    // acceptance criteria. The previous occupant of 50105 ("RBT Rebate Version Mgt.")
    // has been moved to 50119 - all references to that codeunit are name-based
    // (Codeunit "RBT Rebate Version Mgt."), so the renumber is source-compatible.

    var
        UniqueSeq: Integer;

    // ---------- Inline assertion helpers ----------------------------------------------------
    // The sandbox package set does not ship the Microsoft test libraries. We implement the
    // small subset of assertions the tests need directly on the test codeunit.

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

    // ================= [Test] procedures ==================================================

    /// <summary>
    /// Positive path: activates an agreement with a Percentage rule, seeds a
    /// Calculation Ledger Entry for the accrual period, and posts. Verifies that the
    /// Calc Request transitions to Posted, records 2 G/L entries, and produces a
    /// balanced debit-Expense / credit-Liability G/L journal.
    /// </summary>
    [Test]
    procedure TestPositiveAccrualCalculation()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        GLEntry: Record "G/L Entry";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        // Arrange
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 1000, 10);

        // Act
        PostingEngine.PostAccrual(CalcRequest);

        // Assert - Calc Request stamped as Posted with 2 G/L entries and a Document No.
        CalcRequest.Get(CalcRequest."No.");
        AreEqual(CalcRequest."Posting Status"::Posted, CalcRequest."Posting Status",
            'Posting Status must be Posted after successful PostAccrual.');
        AreEqual(2, CalcRequest."No. of G/L Entries",
            'No. of G/L Entries must be 2 (one debit + one credit line).');
        AssertTrue(CalcRequest."Document No." <> '',
            'Document No. must be populated after posting.');

        // Assert - G/L journal is balanced.
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        AreEqual(2, GLEntry.Count(),
            'Exactly two G/L Entry rows must exist for the accrual Document No.');
        GLEntry.CalcSums(Amount);
        AreEqual(0, GLEntry.Amount,
            'Debit + Credit on the accrual document must sum to zero (balanced posting).');

        // Assert - expense side is a positive debit.
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", ExpenseAccNo);
        GLEntry.CalcSums(Amount);
        AssertTrue(GLEntry.Amount > 0,
            'Accrual Expense account must carry a positive debit amount.');

        // Assert - liability side is a negative credit.
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", LiabAccNo);
        GLEntry.CalcSums(Amount);
        AssertTrue(GLEntry.Amount < 0,
            'Accrual Liability account must carry a negative credit amount.');
    end;

    /// <summary>
    /// Duplicate-post guard: a second PostAccrual on the same Calc Request must be
    /// rejected with an explicit error, and no additional G/L entries may be
    /// produced. This exercises the AlreadyPostedErr guard in RBT Posting Engine.
    /// </summary>
    [Test]
    procedure TestBlockedDuplicatePosting()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        GLEntry: Record "G/L Entry";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        RequestNo: Code[20];
        DocNo: Code[20];
        GLEntryCountAfterFirstPost: Integer;
    begin
        // Arrange - first post succeeds.
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixture(Agreement, CalcRequest, PostingGroup, 500, 20);

        PostingEngine.PostAccrual(CalcRequest);
        CalcRequest.Get(CalcRequest."No.");
        RequestNo := CalcRequest."No.";
        DocNo := CalcRequest."Document No.";

        AreEqual(CalcRequest."Posting Status"::Posted, CalcRequest."Posting Status",
            'First PostAccrual must leave the Calc Request in Posted status.');

        GLEntry.SetRange("Document No.", DocNo);
        GLEntryCountAfterFirstPost := GLEntry.Count();
        AreEqual(2, GLEntryCountAfterFirstPost,
            'First posting must have created exactly two G/L Entry rows.');

        // Act + Assert - second PostAccrual must be rejected with a message naming the Calc Request No.
        asserterror PostingEngine.PostAccrual(CalcRequest);
        AssertTrue(ContainsSubstring(GetLastErrorText(), RequestNo),
            'Duplicate-post error must reference the Calc Request No. so the user knows which record blocked.');

        // Assert - no additional G/L entries were produced by the blocked second attempt.
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocNo);
        AreEqual(GLEntryCountAfterFirstPost, GLEntry.Count(),
            'Blocked duplicate posting must not create any additional G/L Entry rows.');

        // Assert - Calc Request state was not corrupted by the failed second attempt.
        CalcRequest.Get(RequestNo);
        AreEqual(CalcRequest."Posting Status"::Posted, CalcRequest."Posting Status",
            'Posting Status must remain Posted after the blocked duplicate attempt.');
        AreEqual(2, CalcRequest."No. of G/L Entries",
            'No. of G/L Entries must remain 2 after the blocked duplicate attempt.');
    end;

    /// <summary>
    /// Negative activation: activation is blocked when the mandatory Signatory Code
    /// is missing. The agreement must remain in Draft and no version row may exist.
    /// This exercises the signatory-first guard in RBT Rebate Version Mgt.
    /// </summary>
    [Test]
    procedure TestNegativeActivationMissingSignatory()
    var
        Agreement: Record "RBT Rebate Agreement";
        Version: Record "RBT Rebate Version";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        VendorNo: Code[20];
        AgreementNo: Code[20];
    begin
        // Arrange - Draft agreement with Signed Date but NO Signatory Code.
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        VendorNo := EnsureVendor();

        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Missing Signatory Test';
        Agreement."Type" := Agreement."Type"::"Vendor Rebate";
        Agreement."Vendor No." := VendorNo;
        Agreement."Start Date" := WorkDate() - 30;
        Agreement."End Date" := WorkDate() + 30;
        Agreement."Currency Code" := '';
        Agreement."Posting Group" := PostingGroup;
        // Signatory Code deliberately left blank; Signed Date supplied to prove that
        // Signatory Code alone is what fails, not Signed Date.
        Agreement."Signatory Code" := '';
        Agreement."Signed Date" := WorkDate();
        Agreement.Modify();
        AgreementNo := Agreement."No.";

        // Act + Assert - activation must fail with an actionable error naming the agreement.
        asserterror VersionMgt.ActivateAgreement(Agreement);
        AssertTrue(ContainsSubstring(GetLastErrorText(), 'Signatory'),
            'Activation error text must mention Signatory to direct the user to the missing field.');
        AssertTrue(ContainsSubstring(GetLastErrorText(), AgreementNo),
            'Activation error must name the specific agreement that failed activation.');

        // Assert - agreement state was NOT changed by the failed activation attempt.
        Agreement.Get(AgreementNo);
        AreEqual(Agreement.Status::Draft, Agreement.Status,
            'Agreement must remain in Draft when activation is blocked by missing Signatory Code.');

        // Assert - NO version row was inserted for a failed activation.
        Version.SetRange("Agreement No.", AgreementNo);
        AreEqual(0, Version.Count(),
            'No RBT Rebate Version row must be inserted when activation is blocked.');
    end;

    // ================= Fixture helpers ====================================================

    local procedure Initialize(var ExpenseAccNo: Code[20]; var LiabAccNo: Code[20]; var PostingGroup: Code[20])
    var
        RBTInstall: Codeunit "RBT Install";
        PostingSetup: Record "RBT Posting Setup";
    begin
        // Seed Setup + No. Series so agreement / calc request auto-numbering works.
        RBTInstall.InitializeSetup();
        UniqueSeq += 1;

        ExpenseAccNo := EnsureGLAccount('EXP');
        LiabAccNo := EnsureGLAccount('LIA');
        PostingGroup := UniqueCode20('PG');

        // Posting Setup for (PostingGroup, blank Currency) - used by PostAccrual.
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
        InsertLedgerEntry(LedgerEntry, Agreement, Rule, BaseAmount, Percentage);
        CreateCalcRequest(CalcRequest, Agreement);
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; PostingGroup: Code[20])
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        SignatoryCode: Code[50];
    begin
        // Ensure a User Setup row exists so the Signatory Code table-relation is satisfied.
        SignatoryCode := EnsureUserSetup();

        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Calculation Tests Agreement';
        Agreement."Type" := Agreement."Type"::"Vendor Rebate";
        Agreement."Vendor No." := VendorNo;
        Agreement."Start Date" := WorkDate() - 30;
        Agreement."End Date" := WorkDate() + 30;
        Agreement."Currency Code" := '';
        Agreement."Posting Group" := PostingGroup;
        Agreement."Signatory Code" := SignatoryCode;
        Agreement."Signed Date" := WorkDate();
        Agreement.Modify();

        VersionMgt.ActivateAgreement(Agreement);
        Agreement.Find();
    end;

    local procedure CreatePercentageRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; Percentage: Decimal)
    var
        ExistingRule: Record "RBT Rebate Rule";
        NextLineNo: Integer;
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
        // The Rule Engine normally seeds Calc Ledger Entries from real Purchase Invoice Lines;
        // for a focused unit test we insert one entry directly using the internal-edit escape
        // hatch. PostAccrual then aggregates via CalcSums exactly as it does in production.
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
        CalcRequest.Description := 'RBT Calculation Tests Request';
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

    local procedure EnsureUserSetup(): Code[50]
    var
        UserSetup: Record "User Setup";
        UserIdCode: Code[50];
    begin
        // Signatory Code has a table-relation to User Setup; the current UserId is
        // guaranteed to exist as a valid identifier. Create the User Setup row on demand.
        UserIdCode := CopyStr(UserId(), 1, MaxStrLen(UserIdCode));
        if UserIdCode = '' then
            UserIdCode := 'RBT-SIGN';
        if UserSetup.Get(UserIdCode) then
            exit(UserIdCode);
        UserSetup.Init();
        UserSetup."User ID" := UserIdCode;
        UserSetup.Insert();
        exit(UserIdCode);
    end;

    local procedure UniqueCode20(Prefix: Text): Code[20]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq), 1, 20));
    end;
}
