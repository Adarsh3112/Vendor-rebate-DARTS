codeunit 50106 "RBT Rule Engine Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test coverage for the RBT Rule Engine (codeunit 50100).
    //
    // Fixture strategy:
    //   - Each [Test] procedure calls Initialize(), which:
    //       * calls "RBT Install".InitializeSetup() to seed the Setup, No. Series
    //         and Default Posting Setup records the engine implicitly depends on;
    //       * creates a Vendor, an Item Category, two Items (one in the category and one
    //         outside it) and two Locations directly. Test-library packages
    //         (Library - Purchase, Library - Sales, Library - Inventory, Library - ERM)
    //         are the intended sources for these fixtures in a full BC test suite; they
    //         are noted here for documentation and can be substituted without changing the
    //         [Test] procedures.
    //   - Each test builds its own Draft agreement, activates it through
    //     "RBT Rebate Version Mgt.".ActivateAgreement so Version 1 exists, then inserts a
    //     "Purch. Inv. Line" (or Sales Invoice Line) shaped exactly for the scenario.
    //   - BC's test runner rolls back the transaction after each test, so tests remain
    //     independent without explicit cleanup.

    var
        NextPurchDocSuffix: Integer;
        UniqueSeq: Integer;

    // Inline assertion helpers - the sandbox package set does not ship the Microsoft test libraries
    // (Library Assert / Library - Utility / Library - Purchase etc). We implement the small subset
    // of assertions we need locally so this test codeunit compiles against the base symbols only.

    local procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1. Expected: %2. Actual: %3.', Comment = '%1 = assertion message, %2 = expected value, %3 = actual value';
    begin
        if Format(Expected) <> Format(Actual) then
            Error(AssertionFailedErr, Msg, Format(Expected), Format(Actual));
    end;

    local procedure Initialize(var Fixture: Record "RBT Rebate Agreement" temporary)
    var
        RBTInstall: Codeunit "RBT Install";
    begin
        RBTInstall.InitializeSetup();
        // silence unused-parameter warnings; the temporary record is a convenience handle for future extension.
        Fixture.Reset();
        NextPurchDocSuffix := 0;
    end;

    local procedure PrepareBaseFixture(var TestVendorNo: Code[20]; var TestItemNoA: Code[20]; var TestItemNoB: Code[20]; var TestItemCategoryCode: Code[20]; var TestLocationBlue: Code[10]; var TestLocationRed: Code[10])
    begin
        TestVendorNo := UniqueCode20('V');
        TestItemNoA := UniqueCode20('IA');
        TestItemNoB := UniqueCode20('IB');
        TestItemCategoryCode := UniqueCode20('C');
        TestLocationBlue := UniqueCode10('LB');
        TestLocationRed := UniqueCode10('LR');
        EnsureItemCategory(TestItemCategoryCode);
        EnsureItem(TestItemNoA, TestItemCategoryCode);
        EnsureItem(TestItemNoB, '');
        EnsureLocation(TestLocationBlue);
        EnsureLocation(TestLocationRed);
        EnsureVendor(TestVendorNo);
    end;

    // -------- Positive method tests ---------------------------------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPercentageMethodProducesExpectedAmount()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 1000, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(1, LedgerEntry.Count(), 'Percentage rule should produce exactly one ledger entry.');
        LedgerEntry.FindFirst();
        AreEqual(LedgerEntry."Calculation Method"::Percentage, LedgerEntry."Calculation Method", 'Method should be Percentage.');
        AreEqual(50, LedgerEntry."Calculated Amount", 'Calculated Amount should equal Base * Percentage / 100 (1000*5/100=50).');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestFixedAmountMethodProducesExpectedAmount()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreateFixedRule(Rule, Agreement, 25, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 1000, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(1, LedgerEntry.Count(), 'Fixed rule should produce exactly one ledger entry.');
        LedgerEntry.FindFirst();
        AreEqual(LedgerEntry."Calculation Method"::Fixed, LedgerEntry."Calculation Method", 'Method should be Fixed.');
        AreEqual(25, LedgerEntry."Calculated Amount", 'Calculated Amount should equal the rule Fixed Amount (25).');
    end;

    // -------- Filter tests -----------------------------------------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestItemFilterMatch()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, ItemA, '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 500, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(1, LedgerEntry.Count(), 'Item filter match should produce exactly one ledger entry.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestItemFilterMissProducesNoEntry()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, ItemA, '', '');
        InsertPurchInvLineForItem(Agreement, ItemB, 500, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(0, LedgerEntry.Count(), 'Item filter miss must produce zero ledger entries.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestItemCategoryFilterMatch()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, '', CategoryCode, '');
        InsertPurchInvLineForItem(Agreement, ItemA, 500, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(1, LedgerEntry.Count(), 'Item Category match should produce one ledger entry.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestLocationFilterMissProducesNoEntry()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, '', '', LocBlue);
        InsertPurchInvLineForItem(Agreement, ItemA, 500, WorkDate(), LocRed);

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(0, LedgerEntry.Count(), 'Location filter miss must produce zero ledger entries.');
    end;

    // -------- Date-window tests ------------------------------------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPostingDateBeforeStartDateExcluded()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate(), WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 500, WorkDate() - 5, '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(0, LedgerEntry.Count(), 'Source line before Start Date must be excluded.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPostingDateAfterEndDateExcluded()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate());
        CreatePercentageRule(Rule, Agreement, 10, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 500, WorkDate() + 5, '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(0, LedgerEntry.Count(), 'Source line after End Date must be excluded.');
    end;

    // -------- Idempotency ------------------------------------------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestIdempotencySecondRunNoDuplicates()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        FirstRunCount: Integer;
        SecondRunCount: Integer;
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 1000, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");
        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        FirstRunCount := LedgerEntry.Count();

        RuleEngine.Run(Agreement."No.");
        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        SecondRunCount := LedgerEntry.Count();

        AreEqual(FirstRunCount, SecondRunCount, 'Re-running the engine must not create duplicate ledger entries.');
    end;

    // -------- Type filter must not be unconditionally forced ------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestBlankItemFilterDoesNotForceTypeItem()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10, '', '', '');
        // Insert a G/L Account purchase line - if the engine incorrectly forces Type=Item this row will be filtered out.
        InsertPurchInvGLLine(Agreement, 500, WorkDate());

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(1, LedgerEntry.Count(),
            'When rule has no Item filter, a G/L Account line inside the date window MUST be included (Type=Item must NOT be unconditionally forced).');
    end;

    // -------- Immutability -----------------------------------------------------------------

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestImmutabilityLedgerEntryCannotBeModified()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 1000, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        LedgerEntry.FindFirst();
        LedgerEntry."Calculated Amount" := 999;
        asserterror LedgerEntry.Modify();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestImmutabilityLedgerEntryCannotBeDeleted()
    var
        FixtureAgreement: Record "RBT Rebate Agreement" temporary;
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        RuleEngine: Codeunit "RBT Rule Engine";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        VendorNo: Code[20];
        ItemA: Code[20];
        ItemB: Code[20];
        CategoryCode: Code[20];
        LocBlue: Code[10];
        LocRed: Code[10];
    begin
        Initialize(FixtureAgreement);
        PrepareBaseFixture(VendorNo, ItemA, ItemB, CategoryCode, LocBlue, LocRed);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5, '', '', '');
        InsertPurchInvLineForItem(Agreement, ItemA, 1000, WorkDate(), '');

        RuleEngine.Run(Agreement."No.");

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        LedgerEntry.FindFirst();
        asserterror LedgerEntry.Delete();
    end;

    // ================= Fixture helpers ==============================================

    local procedure UniqueCode20(Prefix: Text): Code[20]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq), 1, 20));
    end;

    local procedure UniqueCode10(Prefix: Text): Code[10]
    begin
        UniqueSeq += 1;
        exit(CopyStr('R' + Prefix + Format(UniqueSeq), 1, 10));
    end;

    local procedure EnsureItemCategory(CategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        if ItemCategory.Get(CategoryCode) then
            exit;
        ItemCategory.Init();
        ItemCategory.Code := CategoryCode;
        ItemCategory.Description := 'RBT Test Category';
        ItemCategory.Insert();
    end;

    local procedure EnsureItem(ItemNo: Code[20]; CategoryCode: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then begin
            if Item."Item Category Code" <> CategoryCode then begin
                Item."Item Category Code" := CategoryCode;
                Item.Modify();
            end;
            exit;
        end;
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := 'RBT Test Item';
        Item."Item Category Code" := CategoryCode;
        Item.Insert();
    end;

    local procedure EnsureLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit;
        Location.Init();
        Location.Code := LocationCode;
        Location.Name := 'RBT Test Location';
        Location.Insert();
    end;

    local procedure EnsureVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit;
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Name := 'RBT Test Vendor';
        Vendor.Insert();
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Test Agreement';
        Agreement."Type" := Agreement."Type"::"Vendor Rebate";
        Agreement."Vendor No." := VendorNo;
        Agreement."Start Date" := StartDate;
        Agreement."End Date" := EndDate;
        Agreement.Status := Agreement.Status::Draft;
        Agreement.Modify();
        VersionMgt.ActivateAgreement(Agreement);
        Agreement.Find();
    end;

    local procedure CreatePercentageRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; PercentageValue: Decimal; ItemNo: Code[20]; ItemCategory: Code[20]; LocationCode: Code[10])
    begin
        Rule.Init();
        Rule."Agreement No." := Agreement."No.";
        Rule."Line No." := 0;
        Rule.Insert(true);
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Percentage := PercentageValue;
        Rule."Item No." := ItemNo;
        Rule."Item Category" := ItemCategory;
        Rule."Location Code" := LocationCode;
        Rule.Modify();
    end;

    local procedure CreateFixedRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; FixedAmount: Decimal; ItemNo: Code[20]; ItemCategory: Code[20]; LocationCode: Code[10])
    begin
        Rule.Init();
        Rule."Agreement No." := Agreement."No.";
        Rule."Line No." := 0;
        Rule.Insert(true);
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Fixed;
        Rule."Fixed Amount" := FixedAmount;
        Rule."Item No." := ItemNo;
        Rule."Item Category" := ItemCategory;
        Rule."Location Code" := LocationCode;
        Rule.Modify();
    end;

    local procedure InsertPurchInvLineForItem(var Agreement: Record "RBT Rebate Agreement"; ItemNo: Code[20]; LineAmount: Decimal; PostingDate: Date; LocationCode: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DocNo: Code[20];
    begin
        DocNo := NextTestPurchDocNo();
        if not PurchInvHeader.Get(DocNo) then begin
            PurchInvHeader.Init();
            PurchInvHeader."No." := DocNo;
            PurchInvHeader."Buy-from Vendor No." := Agreement."Vendor No.";
            PurchInvHeader."Pay-to Vendor No." := Agreement."Vendor No.";
            PurchInvHeader."Posting Date" := PostingDate;
            PurchInvHeader.Insert();
        end;
        PurchInvLine.Init();
        PurchInvLine."Document No." := DocNo;
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Agreement."Vendor No.";
        PurchInvLine."Pay-to Vendor No." := Agreement."Vendor No.";
        PurchInvLine."Posting Date" := PostingDate;
        PurchInvLine.Type := PurchInvLine.Type::Item;
        PurchInvLine."No." := ItemNo;
        PurchInvLine.Quantity := 1;
        PurchInvLine.Amount := LineAmount;
        PurchInvLine."Location Code" := LocationCode;
        PurchInvLine.Insert();
    end;

    local procedure InsertPurchInvGLLine(var Agreement: Record "RBT Rebate Agreement"; LineAmount: Decimal; PostingDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DocNo: Code[20];
    begin
        DocNo := NextTestPurchDocNo();
        if not PurchInvHeader.Get(DocNo) then begin
            PurchInvHeader.Init();
            PurchInvHeader."No." := DocNo;
            PurchInvHeader."Buy-from Vendor No." := Agreement."Vendor No.";
            PurchInvHeader."Pay-to Vendor No." := Agreement."Vendor No.";
            PurchInvHeader."Posting Date" := PostingDate;
            PurchInvHeader.Insert();
        end;
        PurchInvLine.Init();
        PurchInvLine."Document No." := DocNo;
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Agreement."Vendor No.";
        PurchInvLine."Pay-to Vendor No." := Agreement."Vendor No.";
        PurchInvLine."Posting Date" := PostingDate;
        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        PurchInvLine."No." := '';
        PurchInvLine.Quantity := 1;
        PurchInvLine.Amount := LineAmount;
        PurchInvLine.Insert();
    end;

    local procedure NextTestPurchDocNo(): Code[20]
    begin
        NextPurchDocSuffix += 1;
        exit(CopyStr('RBT-TPI-' + Format(NextPurchDocSuffix), 1, 20));
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Swallow Activate/version messages emitted by RBT Rebate Version Mgt. so tests run non-interactively.
    end;
}
