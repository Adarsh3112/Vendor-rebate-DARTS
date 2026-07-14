codeunit 50109 "RBT Recalc Engine Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test coverage for RBT Recalc Engine (codeunit 50103).
    //
    // Six scenarios:
    //   PercentageChangeProducesDelta       - happy path: rule bump -> one Adjustment entry
    //                                         linked via Corrects Entry No. with Calculated
    //                                         Amount = New - Old.
    //   ZeroDeltaSkipped                    - re-run without changing terms raises
    //                                         NothingToRecalcErr.
    //   DeltaPostingIsBalancedAndNetOnly    - full flow (Recalc + PostAccrual) -> exactly
    //                                         two balanced G/L entries whose absolute amount
    //                                         equals the delta (not the full new amount).
    //   RecalcIsIdempotent                  - second Recalc under the same version raises
    //                                         NothingToRecalcErr.
    //   MissingPostingSetupBlocksRecalc     - deleting Posting Setup rejects the recalc
    //                                         with an actionable error.
    //   AdjustmentEntriesRemainImmutable    - direct Modify on a produced Adjustment row
    //                                         fires the immutability trigger.
    //
    // BC's test runner rolls back the transaction after each test so tests are independent.
    //
    // Note on library dependencies: the sandbox package set does not ship the Microsoft
    // test-library codeunits (Assert, Library - ERM, Library - Purchase), so this codeunit
    // uses inline assertion helpers - matching the pattern already used by
    // RBTRuleEngineTest, RBTPostingEngineTest, and RBTSettlementEngineTest.

    var
        UniqueSeq: Integer;

    local procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1. Expected: %2. Actual: %3.', Comment = '%1 = message, %2 = expected, %3 = actual';
    begin
        if Format(Expected) <> Format(Actual) then
            Error(AssertionFailedErr, Msg, Format(Expected), Format(Actual));
    end;

    local procedure AssertTrue(Condition: Boolean; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1.', Comment = '%1 = message';
    begin
        if not Condition then
            Error(AssertionFailedErr, Msg);
    end;

    local procedure ContainsSubstring(Source: Text; Needle: Text): Boolean
    begin
        exit(StrPos(Source, Needle) > 0);
    end;

    local procedure ExpectedError(Needle: Text)
    var
        MissingSubstringErr: Label 'Expected error text to contain "%1" but got "%2".', Comment = '%1 = expected substring, %2 = actual error text';
    begin
        if not ContainsSubstring(GetLastErrorText(), Needle) then
            Error(MissingSubstringErr, Needle, GetLastErrorText());
    end;

    // ================ [Test] procedures ==================================================

    [Test]
    procedure PercentageChangeProducesDelta()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        NewEntry: Record "RBT Calculation Ledger Entry";
        CurrentVersion: Record "RBT Rebate Version";
        CalcRequest: Record "RBT Calc Request";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        DeltaCount: Integer;
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);

        // Bump the rule from 5% to 8% - triggers HandleAgreementModify + new version on the agreement
        // through the explicit CreateNextVersion path (rule edit is not detected by the Agreement's
        // OnModify, so we create the next version explicitly to simulate the retro scenario).
        Rule.Percentage := 8;
        Rule.Modify();
        VersionMgt.CreateNextVersion(Agreement, 'Percentage bumped from 5 to 8');

        // Sanity-check: we now have version 2 marked current.
        VersionMgt.GetCurrentVersion(Agreement."No.", CurrentVersion);
        AssertTrue(CurrentVersion."Version No." > 1, 'Rule bump must produce a new current version.');

        DeltaCount := RecalcEngine.RecalcPeriod(
            Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest);

        AreEqual(1, DeltaCount, 'Exactly one Adjustment entry must be produced by the 5%->8% bump.');

        NewEntry.SetRange("Agreement No.", Agreement."No.");
        NewEntry.SetRange("Entry Type", NewEntry."Entry Type"::Adjustment);
        NewEntry.SetRange("Corrects Entry No.", OldEntry."Entry No.");
        NewEntry.FindFirst();
        AreEqual(NewEntry."Entry Type"::Adjustment, NewEntry."Entry Type", 'Entry Type must be Adjustment.');
        AreEqual(OldEntry."Entry No.", NewEntry."Corrects Entry No.", 'Corrects Entry No. must equal the original Entry No.');
        AreEqual(CurrentVersion."Version No.", NewEntry."Agreement Version No.", 'Adjustment must be stamped with the current version.');
        // Delta = New - Old = (1000 * 8% = 80) - (1000 * 5% = 50) = 30
        AreEqual(30, NewEntry."Calculated Amount", 'Calculated Amount on the Adjustment must equal (New - Old) = 30.');
    end;

    [Test]
    procedure ZeroDeltaSkipped()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        CalcRequest: Record "RBT Calc Request";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);

        // Rule unchanged - Recalc must find no non-zero deltas and raise NothingToRecalcErr.
        asserterror RecalcEngine.RecalcPeriod(
            Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest);
        ExpectedError(Agreement."No.");
    end;

    [Test]
    procedure DeltaPostingIsBalancedAndNetOnly()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        CalcRequest: Record "RBT Calc Request";
        GLEntry: Record "G/L Entry";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        PostingEngine: Codeunit "RBT Posting Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        DeltaCount: Integer;
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);

        Rule.Percentage := 8;
        Rule.Modify();
        VersionMgt.CreateNextVersion(Agreement, 'Percentage bumped from 5 to 8');

        DeltaCount := RecalcEngine.RecalcPeriod(
            Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest);
        AreEqual(1, DeltaCount, 'One Adjustment expected.');

        PostingEngine.PostAccrual(CalcRequest);

        // Reload the Calc Request from DB to see the stamped Posted state.
        CalcRequest.Get(CalcRequest."No.");
        AreEqual(CalcRequest."Posting Status"::Posted, CalcRequest."Posting Status",
            'Calc Request must be Posted after PostAccrual.');
        AreEqual(2, CalcRequest."No. of G/L Entries", 'Exactly 2 G/L entries expected.');
        AssertTrue(CalcRequest."Document No." <> '', 'Document No. must be populated.');

        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        AreEqual(2, GLEntry.Count(), 'Exactly two G/L Entry rows must exist under the delta Document No.');
        GLEntry.CalcSums(Amount);
        AreEqual(0, GLEntry.Amount, 'Debit + Credit must sum to zero (balanced posting).');

        // The absolute amount on each side must be the DELTA (30), not the full new amount (80).
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", ExpenseAccNo);
        GLEntry.CalcSums(Amount);
        AreEqual(30, GLEntry.Amount, 'Expense debit must equal the net delta (30), not the full new amount (80).');

        GLEntry.Reset();
        GLEntry.SetRange("Document No.", CalcRequest."Document No.");
        GLEntry.SetRange("G/L Account No.", LiabAccNo);
        GLEntry.CalcSums(Amount);
        AreEqual(-30, GLEntry.Amount, 'Liability credit must equal minus the net delta (-30).');
    end;

    [Test]
    procedure RecalcIsIdempotent()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        CalcRequest1: Record "RBT Calc Request";
        CalcRequest2: Record "RBT Calc Request";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);

        Rule.Percentage := 8;
        Rule.Modify();
        VersionMgt.CreateNextVersion(Agreement, 'Percentage bumped from 5 to 8');

        // First recalc succeeds and inserts one Adjustment entry.
        RecalcEngine.RecalcPeriod(Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest1);

        // Second recalc under the same current version must produce zero new deltas
        // (idempotency guard on the CorrectsIdx secondary key), and therefore raise
        // NothingToRecalcErr.
        asserterror RecalcEngine.RecalcPeriod(Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest2);
        ExpectedError(Agreement."No.");
    end;

    [Test]
    procedure MissingPostingSetupBlocksRecalc()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        PostingSetup: Record "RBT Posting Setup";
        CalcRequest: Record "RBT Calc Request";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);
        Rule.Percentage := 8;
        Rule.Modify();
        VersionMgt.CreateNextVersion(Agreement, 'Percentage bumped from 5 to 8');

        // Delete both the specific and the default-group Posting Setup rows so the fallback
        // in GetPostingSetup finds nothing and raises the configuration error.
        if PostingSetup.Get(PostingGroup, '') then
            PostingSetup.Delete();
        if PostingSetup.Get('DEFAULT', '') then
            PostingSetup.Delete();

        asserterror RecalcEngine.RecalcPeriod(Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest);
        AssertTrue(
            ContainsSubstring(GetLastErrorText(), 'Posting Setup') or
            ContainsSubstring(GetLastErrorText(), 'Rebate Posting Setup'),
            'Missing-setup error must reference Posting Setup.');
    end;

    [Test]
    procedure AdjustmentEntriesRemainImmutable()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        OldEntry: Record "RBT Calculation Ledger Entry";
        NewEntry: Record "RBT Calculation Ledger Entry";
        CalcRequest: Record "RBT Calc Request";
        RecalcEngine: Codeunit "RBT Recalc Engine";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureWithOriginalEntry(Agreement, Rule, OldEntry, PostingGroup, 1000, 5);
        Rule.Percentage := 8;
        Rule.Modify();
        VersionMgt.CreateNextVersion(Agreement, 'Percentage bumped from 5 to 8');

        RecalcEngine.RecalcPeriod(Agreement."No.", WorkDate() - 30, WorkDate() + 30, WorkDate(), CalcRequest);

        // Fetch the produced Adjustment entry and attempt a direct Modify without the escape hatch.
        NewEntry.SetRange("Agreement No.", Agreement."No.");
        NewEntry.SetRange("Entry Type", NewEntry."Entry Type"::Adjustment);
        NewEntry.SetRange("Corrects Entry No.", OldEntry."Entry No.");
        NewEntry.FindFirst();
        NewEntry."Calculated Amount" := 999999;
        asserterror NewEntry.Modify(true);
        AssertTrue(
            ContainsSubstring(GetLastErrorText(), 'immutable') or
            ContainsSubstring(GetLastErrorText(), 'cannot be modified'),
            'Direct Modify on an Adjustment row must fire the immutability trigger.');
    end;

    // ================ Fixture helpers ====================================================

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

    local procedure BuildFixtureWithOriginalEntry(var Agreement: Record "RBT Rebate Agreement"; var Rule: Record "RBT Rebate Rule"; var OldEntry: Record "RBT Calculation Ledger Entry"; PostingGroup: Code[20]; BaseAmount: Decimal; PercentageValue: Decimal)
    var
        VendorNo: Code[20];
    begin
        VendorNo := EnsureVendor();
        CreateActiveVendorAgreement(Agreement, VendorNo, PostingGroup);
        CreatePercentageRule(Rule, Agreement, PercentageValue);
        InsertOriginalLedgerEntry(OldEntry, Agreement, Rule, BaseAmount, PercentageValue);
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; PostingGroup: Code[20])
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Recalc Engine Test Agreement';
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

    local procedure CreatePercentageRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; PercentageValue: Decimal)
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
        Rule.Percentage := PercentageValue;
        Rule.Insert();
    end;

    local procedure InsertOriginalLedgerEntry(var LedgerEntry: Record "RBT Calculation Ledger Entry"; var Agreement: Record "RBT Rebate Agreement"; var Rule: Record "RBT Rebate Rule"; BaseAmount: Decimal; PercentageValue: Decimal)
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
        LedgerEntry.Percentage := PercentageValue;
        LedgerEntry."Calculated Amount" := BaseAmount * PercentageValue / 100;
        LedgerEntry."Currency Code" := Agreement."Currency Code";
        // Entry Type is Original by default (enum value 0); do not touch it.
        LedgerEntry.SetAllowInternalEdit(true);
        LedgerEntry.Insert(true);
        LedgerEntry.SetAllowInternalEdit(false);
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
        GLAccount.Name := 'RBT Recalc Test ' + Prefix;
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
        Vendor.Name := 'RBT Recalc Test Vendor';
        Vendor.Insert();
        exit(VendorNo);
    end;

    local procedure UniqueCode20(Prefix: Text): Code[20]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq), 1, 20));
    end;
}
