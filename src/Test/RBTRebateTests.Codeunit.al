codeunit 50105 "RBT Rebate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    [Test]
    procedure TestAgreementActivationAndVersioning()
    var
        Agreement: Record "RBT Rebate Agreement";
        AgreementVersion: Record "RBT Rebate Agmt Ver";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateAgreement(Agreement);
        RebateMgmt.ActivateAgreement(Agreement);

        // Verify
        Agreement.Get(Agreement."No.");
        Agreement.TestField(Status, Agreement.Status::Active);

        AgreementVersion.SetRange("Agreement No.", Agreement."No.");
        Assert.AreEqual(1, AgreementVersion.Count(), 'Exactly one version should exist.');
        AgreementVersion.FindFirst();
        Assert.IsTrue(AgreementVersion."Is Current Version", 'Version 1 should be current.');
    end;

    [Test]
    procedure TestAccrualPostingIdempotency()
    var
        CalcHeader: Record "RBT Rebate Calc Hdr";
        Agreement: Record "RBT Rebate Agreement";
        RebateCalc: Codeunit "RBT Rebate Calc.";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreement(Agreement);
        Agreement.Validate("Rebate %", 10);
        Agreement.Modify();
        RebateMgmt.ActivateAgreement(Agreement);

        CreateCalcHeader(CalcHeader, Agreement."No.");

        // Exercise 1
        RebateCalc.Run(CalcHeader);

        // Exercise 2 - Should fail
        asserterror RebateCalc.Run(CalcHeader);

        // Verify
        Assert.ExpectedError('already been posted');
    end;

    [Test]
    procedure TestAgreementHeaderActivationHappyPath()
    var
        Header: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();

        RebateMgmt.ActivateAgreementHeader(Header);

        // Verify
        Header.Get(Header."No.");
        Assert.IsTrue(Header.Status = Header.Status::Active, 'Header should be Active after activation.');
        Assert.IsTrue(Header."No." <> '', 'Header No. should be auto-assigned from the Agreement Nos. series.');
    end;

    [Test]
    procedure TestAgreementHeaderActivationMissingSignatory()
    var
        Header: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        // Intentionally leave Signatory Code blank
        Header."Signed Date" := WorkDate();
        Header.Modify();

        // Exercise + Verify
        asserterror RebateMgmt.ActivateAgreementHeader(Header);
        Assert.ExpectedError('Signatory Code');
    end;

    [Test]
    procedure TestAgreementHeaderActivationFutureSignedDate()
    var
        Header: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate() + 5;
        Header.Modify();

        // Exercise + Verify
        asserterror RebateMgmt.ActivateAgreementHeader(Header);
        Assert.ExpectedError('future');
    end;

    [Test]
    procedure TestAgreementHeaderFieldLockingPostActivation()
    var
        Header: Record "RBT Agreement Header";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Exercise - changing Vendor No. after activation must raise an error
        Header.Get(Header."No.");
        Header."Vendor No." := 'V002';
        asserterror Header.Modify();

        // Verify
        Assert.ExpectedError('Cannot change Vendor No.');
    end;

    [Test]
    procedure TestAgreementHeaderDraftEditable()
    var
        Header: Record "RBT Agreement Header";
        Vendor: Record Vendor;
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Ensure secondary vendor exists
        Vendor.Init();
        Vendor."No." := 'V002';
        Vendor.Name := 'Test Vendor 2';
        if Vendor.Insert() then;

        // Exercise - change Vendor No. while in Draft
        Header."Vendor No." := 'V002';
        Header.Modify();

        // Verify
        Header.Get(Header."No.");
        Assert.AreEqual('V002', Header."Vendor No.", 'Vendor No. should be editable in Draft.');
        Assert.IsTrue(Header.Status = Header.Status::Draft, 'Header should still be in Draft status.');
    end;

    [Test]
    procedure TestHeaderActivationCreatesAgreementVersion1()
    var
        Header: Record "RBT Agreement Header";
        Version: Record "RBT Agmt Version";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();

        // Exercise
        RebateMgmt.ActivateAgreementHeader(Header);

        // Verify
        Version.Reset();
        Version.SetRange("Agreement No.", Header."No.");
        Assert.AreEqual(1, Version.Count(), 'Activating the header must insert exactly one RBT Agmt Version row.');
        Version.FindFirst();
        Assert.AreEqual(1, Version."Version No.", 'The first version must be numbered 1.');
        Assert.IsTrue(Version."Is Current Version", 'Version 1 must be flagged as the current version.');
        Assert.IsTrue(Version."Effective From" <> 0D, 'Effective From must be stamped.');
        Assert.IsTrue(Version."Created At" <> 0DT, 'Created At must be stamped.');
    end;

    [Test]
    procedure TestActiveHeaderEditCreatesNewVersion()
    var
        Header: Record "RBT Agreement Header";
        Version: Record "RBT Agmt Version";
        Vendor: Record Vendor;
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        Version1IsCurrent: Boolean;
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        Vendor.Init();
        Vendor."No." := 'V002';
        Vendor.Name := 'Test Vendor 2';
        if Vendor.Insert() then;

        // Exercise
        Header.Get(Header."No.");
        Header."Location Code" := 'YELLOW';
        Header.Modify();

        // Verify
        Version.Reset();
        Version.SetRange("Agreement No.", Header."No.");
        Assert.AreEqual(2, Version.Count(), 'Editing an Active header must spawn a new RBT Agmt Version row, giving 2 total.');

        Version.SetRange("Version No.", 1);
        Version.FindFirst();
        Version1IsCurrent := Version."Is Current Version";
        Assert.IsTrue(not Version1IsCurrent, 'Version 1 must be demoted to Is Current Version = false after the edit.');

        Version.Reset();
        Version.SetRange("Agreement No.", Header."No.");
        Version.SetRange("Version No.", 2);
        Version.FindFirst();
        Assert.IsTrue(Version."Is Current Version", 'Version 2 must be flagged as the current version.');
    end;

    [Test]
    procedure TestRuleInsertionOnOldAgreement()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreement(Agreement);

        // Exercise
        Rule.Init();
        Rule."Agreement No." := Agreement."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 5;
        Rule.Insert(true);

        // Verify
        Assert.AreEqual(1, Rule."Rule No.", 'Rule should be insertable for old agreement model.');
    end;

    [Test]
    procedure TestCalculationForAgreementHeaderWithRules()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        PurchInvLine: Record "Purch. Inv. Line";
        RebateCalc: Codeunit "RBT Rebate Calc.";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 10;
        Rule.Insert(true);

        // Create some history
        PurchInvLine.Init();
        PurchInvLine."Document No." := 'INV001';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 1000;
        PurchInvLine.Insert();

        CreateCalcHeader(CalcHeader, Header."No.");

        // Exercise
        RebateCalc.Run(CalcHeader);

        // Verify
        CalcHeader.Get(CalcHeader."No.");
        Assert.AreEqual(100, CalcHeader."Total Amount", 'Rebate amount should be 100 (10% of 1000).');
    end;

    [Test]
    procedure TestAgreementVersionIsImmutable()
    var
        Header: Record "RBT Agreement Header";
        Version: Record "RBT Agmt Version";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        Version.Reset();
        Version.SetRange("Agreement No.", Header."No.");
        Version.FindFirst();

        Version."Effective From" := WorkDate() + 10;
        asserterror Version.Modify(true);
        Assert.ExpectedError('immutable');

        Version.Find();
        asserterror Version.Delete(true);
        Assert.ExpectedError('immutable');
    end;

    // ============================================================
    //  Task 180: RBT Rebate Rule table tests
    // ============================================================

    [Test]
    procedure TestRebateRuleInsertAutoAssignsRuleNo()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Exercise - first rule on agreement, Rule No. left at 0 (auto-assign)
        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 5;
        Rule.Description := 'Top tier purchase rebate';
        Rule.Insert(true);

        // Verify
        Assert.AreEqual(1, Rule."Rule No.", 'First rule on an agreement must auto-number to 1.');
        Assert.AreEqual(Header."No.", Rule."Agreement No.", 'Agreement No. must be preserved.');
    end;

    [Test]
    procedure TestRebateRuleSequentialNumbering()
    var
        Header: Record "RBT Agreement Header";
        Rule1: Record "RBT Rebate Rule";
        Rule2: Record "RBT Rebate Rule";
        Rule3: Record "RBT Rebate Rule";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Exercise - insert three rules under the same agreement
        Rule1.Init();
        Rule1."Agreement No." := Header."No.";
        Rule1.Basis := Rule1.Basis::"Sales Amount";
        Rule1."Calculation Method" := Rule1."Calculation Method"::"Fixed Amount";
        Rule1.Value := 100;
        Rule1.Insert(true);

        Rule2.Init();
        Rule2."Agreement No." := Header."No.";
        Rule2.Basis := Rule2.Basis::Quantity;
        Rule2."Calculation Method" := Rule2."Calculation Method"::"Tiered Percentage";
        Rule2.Value := 2.5;
        Rule2.Insert(true);

        Rule3.Init();
        Rule3."Agreement No." := Header."No.";
        Rule3.Basis := Rule3.Basis::Margin;
        Rule3."Calculation Method" := Rule3."Calculation Method"::"Slab Amount";
        Rule3.Value := 50;
        Rule3.Insert(true);

        // Verify - rule numbers are 1, 2, 3 within this agreement
        Assert.AreEqual(1, Rule1."Rule No.", 'Rule 1 must be numbered 1.');
        Assert.AreEqual(2, Rule2."Rule No.", 'Rule 2 must be numbered 2.');
        Assert.AreEqual(3, Rule3."Rule No.", 'Rule 3 must be numbered 3.');
    end;

    [Test]
    procedure TestRebateRuleBasisEnumCoversAllSpecValues()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        Basis: Enum "RBT Rebate Basis";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Exercise - one rule per Basis value mandated by the spec
        InsertRuleWithBasis(Header."No.", Basis::"Sales Amount");
        InsertRuleWithBasis(Header."No.", Basis::"Purchase Amount");
        InsertRuleWithBasis(Header."No.", Basis::Quantity);
        InsertRuleWithBasis(Header."No.", Basis::Margin);
        InsertRuleWithBasis(Header."No.", Basis::"Payment Date");
        InsertRuleWithBasis(Header."No.", Basis::"Invoice Date");
        InsertRuleWithBasis(Header."No.", Basis::"Shipment Date");

        // Verify - exactly seven rules persisted
        Rule.Reset();
        Rule.SetRange("Agreement No.", Header."No.");
        Assert.AreEqual(7, Rule.Count(), 'Every Basis value from the spec must be insertable.');
    end;

    [Test]
    procedure TestRebateRuleCalcMethodEnumCoversAllSpecValues()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        Method: Enum "RBT Rebate Calc Method";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Exercise - one rule per Calculation Method mandated by the spec
        InsertRuleWithMethod(Header."No.", Method::"Fixed Amount");
        InsertRuleWithMethod(Header."No.", Method::Percentage);
        InsertRuleWithMethod(Header."No.", Method::"Tiered Percentage");
        InsertRuleWithMethod(Header."No.", Method::"Slab Amount");

        // Verify
        Rule.Reset();
        Rule.SetRange("Agreement No.", Header."No.");
        Assert.AreEqual(4, Rule.Count(), 'Every Calculation Method from the spec must be insertable.');
    end;

    [Test]
    procedure TestRebateRuleBlobCriteriaRoundTrip()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        InclusionJson: Text;
        ExclusionFilter: Text;
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 3;
        Rule.Insert(true);

        InclusionJson := '{"itemCategory":["ELEC","COMP"],"minQty":10}';
        ExclusionFilter := 'Item No.=..1000|9999..';

        // Exercise
        Rule.SetInclusionCriteria(InclusionJson);
        Rule.SetExclusionCriteria(ExclusionFilter);

        // Verify - blob content round-trips back through the read accessors
        Rule.Get(Rule."Agreement No.", Rule."Rule No.");
        Assert.AreEqual(InclusionJson, Rule.GetInclusionCriteria(), 'Inclusion Criteria blob must round-trip exactly.');
        Assert.AreEqual(ExclusionFilter, Rule.GetExclusionCriteria(), 'Exclusion Criteria blob must round-trip exactly.');
    end;

    [Test]
    procedure TestRebateRuleRejectsUnknownAgreement()
    var
        Rule: Record "RBT Rebate Rule";
        Assert: Codeunit "Assert";
    begin
        // Setup
        Initialize();

        // Exercise + Verify
        Rule.Init();
        Rule."Agreement No." := 'AGR-NOPE';
        Rule.Basis := Rule.Basis::"Sales Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 1;
        asserterror Rule.Insert(true);
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure TestRebateRuleLockedAfterAgreementActivation()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
    begin
        // Setup - draft header + rule
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 5;
        Rule.Insert(true);

        // Activate the parent agreement
        Header.Get(Header."No.");
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Exercise - attempt to change the rule's Value while parent is Active
        Rule.Get(Header."No.", Rule."Rule No.");
        Rule.Value := 99;
        asserterror Rule.Modify(true);

        // Verify
        Assert.ExpectedError('cannot be modified');
    end;

    // ============================================================
    //  Task 181: RBT Elig Engine tests
    // ============================================================

    [Test]
    procedure TestEligibilityVendorAgreementInRangeMatchesPurchInvLine()
    var
        Header: Record "RBT Agreement Header";
        PurchInvLine: Record "Purch. Inv. Line";
        EligibilityEngine: Codeunit "RBT Elig Engine";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        EligibleAmount: Decimal;
        EligibleQty: Decimal;
        Count: Integer;
    begin
        // Setup — Active Vendor agreement with a 30-day validity window
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Start Date" := WorkDate() - 10;
        Header."End Date" := WorkDate() + 10;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Posted Purch. Inv. Line for the same vendor, in window
        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-A';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 500;
        PurchInvLine.Quantity := 5;
        PurchInvLine.Insert();

        // Exercise + Verify
        Count := EligibilityEngine.CountEligibleLines(Header);
        Assert.IsTrue(Count >= 1, 'In-range posted purch line must be reported eligible.');

        EligibilityEngine.CalcEligibleAmount(Header, EligibleAmount, EligibleQty);
        Assert.AreEqual(500, EligibleAmount, 'Eligible amount must aggregate the seeded line amount.');
    end;

    [Test]
    procedure TestEligibilityVendorAgreementOutsideDateRangeExcluded()
    var
        Header: Record "RBT Agreement Header";
        PurchInvLine: Record "Purch. Inv. Line";
        EligibilityEngine: Codeunit "RBT Elig Engine";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        Count: Integer;
    begin
        // Setup — agreement End Date is 30 days ago
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Start Date" := WorkDate() - 60;
        Header."End Date" := WorkDate() - 30;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate() - 45;
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Purch line dated today — outside the agreement window
        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-B';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 999;
        PurchInvLine.Insert();

        // Exercise + Verify
        Count := EligibilityEngine.CountEligibleLines(Header);
        Assert.AreEqual(0, Count, 'Lines outside the agreement validity window must be excluded.');
    end;

    [Test]
    procedure TestEligibilityCustomerAgreementMatchesSalesInvoiceLine()
    var
        Header: Record "RBT Agreement Header";
        SalesInvLine: Record "Sales Invoice Line";
        Customer: Record Customer;
        EligibilityEngine: Codeunit "RBT Elig Engine";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        Count: Integer;
    begin
        // Setup — Active Customer agreement
        Initialize();
        Customer.Init();
        Customer."No." := 'C001';
        Customer.Name := 'Test Customer';
        if Customer.Insert() then;

        CreateAgreementHeader(Header, Header."Type"::Customer);
        Header."Customer No." := Customer."No.";
        Header."Start Date" := WorkDate() - 10;
        Header."End Date" := WorkDate() + 10;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Posted Sales Invoice Line for the same customer, in window
        SalesInvLine.Init();
        SalesInvLine."Document No." := 'SI-181-A';
        SalesInvLine."Line No." := 10000;
        SalesInvLine."Sell-to Customer No." := Customer."No.";
        SalesInvLine."Posting Date" := WorkDate();
        SalesInvLine."Line Amount" := 750;
        SalesInvLine.Quantity := 3;
        SalesInvLine.Insert();

        // Exercise + Verify
        Count := EligibilityEngine.CountEligibleLines(Header);
        Assert.IsTrue(Count >= 1, 'In-range posted sales invoice line must be reported eligible.');
    end;

    [Test]
    procedure TestEligibilityNonActiveAgreementRaises()
    var
        Header: Record "RBT Agreement Header";
        EligibilityEngine: Codeunit "RBT Elig Engine";
        Assert: Codeunit "Assert";
    begin
        // Setup — Draft agreement (NOT activated)
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);

        // Exercise + Verify
        asserterror EligibilityEngine.CountEligibleLines(Header);
        Assert.ExpectedError('Status');
    end;

    [Test]
    procedure TestEligibilityHonoursInclusionCriteriaBlob()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
        PurchInvLine: Record "Purch. Inv. Line";
        EligibilityEngine: Codeunit "RBT Elig Engine";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        EligibleAmount: Decimal;
        EligibleQty: Decimal;
        Count: Integer;
    begin
        // Setup — Draft header + rule with Inclusion Criteria 'ITEM-A',
        // then activate.
        Initialize();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Start Date" := WorkDate() - 5;
        Header."End Date" := WorkDate() + 5;
        Header.Modify();

        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 5;
        Rule.Insert(true);
        Rule.SetInclusionCriteria('ITEM-A');

        Header.Get(Header."No.");
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // Two purch invoice lines on the same vendor + date range,
        // but different item No. — only ITEM-A should pass the
        // inclusion filter.
        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-C1';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."No." := 'ITEM-A';
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 200;
        PurchInvLine.Insert();

        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-C2';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."No." := 'ITEM-B';
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 800;
        PurchInvLine.Insert();

        // Exercise + Verify — only the ITEM-A line counts
        Count := EligibilityEngine.CountEligibleLines(Header);
        Assert.AreEqual(1, Count, 'Only the line matching the Inclusion Criteria item No. must be eligible.');

        EligibilityEngine.CalcEligibleAmount(Header, EligibleAmount, EligibleQty);
        Assert.AreEqual(200, EligibleAmount, 'Eligible amount must equal only the ITEM-A line amount.');
    end;

    [Test]
    procedure TestOnAfterCheckEligibilityEventIsPublished()
    var
        Header: Record "RBT Agreement Header";
        PurchInvLine: Record "Purch. Inv. Line";
        EligibilityEngine: Codeunit "RBT Elig Engine";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
        Assert: Codeunit "Assert";
        Tester: Codeunit "RBT Rebate Tests";
        Count: Integer;
    begin
        // Setup — Active Vendor agreement + two posted purch lines
        Initialize();
        BindSubscription(Tester);
        Tester.ResetEventCounter();
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Start Date" := WorkDate() - 5;
        Header."End Date" := WorkDate() + 5;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-E1';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 100;
        PurchInvLine.Insert();

        PurchInvLine.Init();
        PurchInvLine."Document No." := 'PI-181-E2';
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := Header."Vendor No.";
        PurchInvLine."Posting Date" := WorkDate();
        PurchInvLine."Line Amount" := 200;
        PurchInvLine.Insert();

        // Exercise
        Count := EligibilityEngine.CountEligibleLines(Header);

        // Verify — subscriber fired once per eligible line
        Assert.AreEqual(Count, Tester.GetEventCounter(), 'OnAfterCheckEligibility must fire exactly once per eligible source line.');
        Assert.IsTrue(Tester.GetEventCounter() >= 2, 'Both seeded lines must have raised the integration event.');
        UnbindSubscription(Tester);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"RBT Elig Engine", 'OnAfterCheckEligibility', '', false, false)]
    local procedure OnAfterCheckEligibilitySubscriber(AgreementHeader: Record "RBT Agreement Header"; SourceRecordRef: RecordRef; var IsEligible: Boolean)
    begin
        EventCounter += 1;
    end;
    procedure ResetEventCounter()
    begin
        EventCounter := 0;
    end;

    procedure GetEventCounter(): Integer
    begin
        exit(EventCounter);
    end;

    var
        EventCounter: Integer;

    local procedure InsertRuleWithBasis(AgreementNo: Code[20]; BasisValue: Enum "RBT Rebate Basis")
    var
        Rule: Record "RBT Rebate Rule";
    begin
        Rule.Init();
        Rule."Agreement No." := AgreementNo;
        Rule.Basis := BasisValue;
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := 1;
        Rule.Insert(true);
    end;

    local procedure InsertRuleWithMethod(AgreementNo: Code[20]; MethodValue: Enum "RBT Rebate Calc Method")
    var
        Rule: Record "RBT Rebate Rule";
    begin
        Rule.Init();
        Rule."Agreement No." := AgreementNo;
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := MethodValue;
        Rule.Value := 1;
        Rule.Insert(true);
    end;

    local procedure Initialize()
    begin
        // Library - Test Initialize is missing in this environment
    end;

    local procedure CreateAgreement(var Agreement: Record "RBT Rebate Agreement")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := 'V001';
        Vendor.Name := 'Test Vendor';
        if Vendor.Insert() then;

        Agreement.Init();
        Agreement.Validate("Vendor No.", Vendor."No.");
        Agreement."Start Date" := WorkDate();
        Agreement.Insert(true);
    end;

    local procedure CreateCalcHeader(var CalcHeader: Record "RBT Rebate Calc Hdr"; AgreementNo: Code[20])
    begin
        CalcHeader.Init();
        CalcHeader.Validate("Agreement No.", AgreementNo);
        CalcHeader."Calc. From Date" := WorkDate();
        CalcHeader."Calc. To Date" := WorkDate();
        CalcHeader.Insert(true);
    end;

    local procedure CreateAgreementHeader(var Header: Record "RBT Agreement Header"; AgreementType: Enum "RBT Agreement Type")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := 'V001';
        Vendor.Name := 'Test Vendor';
        if Vendor.Insert() then;

        Header.Init();
        Header."Type" := AgreementType;
        if AgreementType = AgreementType::Vendor then
            Header."Vendor No." := Vendor."No.";
        Header."Start Date" := WorkDate();
        Header.Insert(true);
    end;

    // ====================================================================
    // T-005 — Accrual Posting Engine test coverage (Task 183, F-04)
    // ====================================================================

    [Test]
    procedure Test_AccrualEngine_PostsBalancedGLPair_PerCalcLedgerEntry()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        GLEntry: Record "G/L Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        ExpenseAcc: Code[20];
        AccrualAcc: Code[20];
        PostingGroup: Code[20];
        ExpenseAmt: Decimal;
        AccrualAmt: Decimal;
        ExpenseCount: Integer;
        AccrualCount: Integer;
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-01';
        ExpenseAcc := '9101';
        AccrualAcc := '9102';
        SeedPostingSetup(PostingGroup, ExpenseAcc, AccrualAcc);
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, '', 100);

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify - two G/L entries with Document No = CalcHeader."No."
        GLEntry.SetRange("Document No.", CalcHeader."No.");
        if GLEntry.FindSet() then
            repeat
                if GLEntry."G/L Account No." = ExpenseAcc then begin
                    ExpenseCount += 1;
                    ExpenseAmt += GLEntry.Amount;
                end;
                if GLEntry."G/L Account No." = AccrualAcc then begin
                    AccrualCount += 1;
                    AccrualAmt += GLEntry.Amount;
                end;
            until GLEntry.Next() = 0;

        Assert.IsTrue(ExpenseCount >= 1, 'Expected at least one G/L entry on the Expense account.');
        Assert.IsTrue(AccrualCount >= 1, 'Expected at least one G/L entry on the Accrual account.');
        Assert.IsTrue(ExpenseAmt > 0, 'Expense leg should carry a positive amount.');
        Assert.IsTrue(AccrualAmt < 0, 'Accrual leg should carry a negative amount.');
        Assert.AreEqual(0, ExpenseAmt + AccrualAmt, 'Expense + Accrual legs must balance to zero.');
    end;

    [Test]
    procedure Test_AccrualEngine_SkipsAlreadyPostedRows_NoDuplicateGLEntries()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        ReloadCalcLedgEntry: Record "RBT Calc Ledg Entry";
        GLEntry: Record "G/L Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        PostingGroup: Code[20];
        GLEntriesBefore: Integer;
        GLEntriesAfter: Integer;
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-02';
        SeedPostingSetup(PostingGroup, '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, '', 100);

        // Pre-mark the row as Posted via skip-trigger pattern.
        CalcLedgEntry.Posted := true;
        CalcLedgEntry."Posted At" := CurrentDateTime();
        CalcLedgEntry.Modify(false);

        GLEntry.SetRange("Document No.", CalcHeader."No.");
        GLEntriesBefore := GLEntry.Count();

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify - no new G/L entries; Posted flag still true.
        GLEntry.SetRange("Document No.", CalcHeader."No.");
        GLEntriesAfter := GLEntry.Count();
        Assert.AreEqual(GLEntriesBefore, GLEntriesAfter, 'Already-posted Calc Ledg Entry rows must be skipped silently.');

        ReloadCalcLedgEntry.Get(CalcLedgEntry."Entry No.");
        Assert.IsTrue(ReloadCalcLedgEntry.Posted, 'Posted flag must remain true for the already-posted row.');
    end;

    [Test]
    procedure Test_AccrualEngine_UsesPostingGroupFromAgreementHeader_NotVendor()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        GLEntry: Record "G/L Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        HeaderPostingGroup: Code[20];
        VendorPostingGroup: Code[20];
        HeaderExpense: Code[20];
        HeaderAccrual: Code[20];
        VendorExpense: Code[20];
        VendorAccrual: Code[20];
        FoundHeaderAccounts: Boolean;
        FoundVendorAccounts: Boolean;
    begin
        // Setup - two competing posting setup rows.
        Initialize();
        HeaderPostingGroup := 'REBATE-A';
        VendorPostingGroup := 'DOMESTIC';
        HeaderExpense := '9101';
        HeaderAccrual := '9102';
        VendorExpense := '9201';
        VendorAccrual := '9202';
        SeedPostingSetup(HeaderPostingGroup, HeaderExpense, HeaderAccrual);
        SeedPostingSetup(VendorPostingGroup, VendorExpense, VendorAccrual);

        CreateActiveHeaderWithPostingGroup(Header, HeaderPostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, '', 100);

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify - engine must use the header's posting group (9101/9102),
        // NOT the vendor's vendor-posting-group (9201/9202).
        GLEntry.SetRange("Document No.", CalcHeader."No.");
        if GLEntry.FindSet() then
            repeat
                if (GLEntry."G/L Account No." = HeaderExpense) or (GLEntry."G/L Account No." = HeaderAccrual) then
                    FoundHeaderAccounts := true;
                if (GLEntry."G/L Account No." = VendorExpense) or (GLEntry."G/L Account No." = VendorAccrual) then
                    FoundVendorAccounts := true;
            until GLEntry.Next() = 0;

        Assert.IsTrue(FoundHeaderAccounts, 'Engine must source G/L accounts from the agreement header posting group.');
        Assert.IsTrue(not FoundVendorAccounts, 'Engine must NOT use the vendor posting group rows.');
    end;

    [Test]
    procedure Test_AccrualEngine_PropagatesDimensionsFromSourceHeader()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        PostingGroup: Code[20];
        ExpectedDim1: Code[20];
        SourceDocNo: Code[20];
        DimensionFlowed: Boolean;
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-03';
        SeedPostingSetup(PostingGroup, '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);

        SourceDocNo := 'PINV-DIM-001';
        ExpectedDim1 := 'DEPT-100';
        PurchInvHeader.Init();
        PurchInvHeader."No." := SourceDocNo;
        PurchInvHeader."Shortcut Dimension 1 Code" := ExpectedDim1;
        if PurchInvHeader.Insert() then;

        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, SourceDocNo, 100);

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify - at least one G/L entry must carry the source Shortcut Dim 1.
        GLEntry.SetRange("Document No.", CalcHeader."No.");
        if GLEntry.FindSet() then
            repeat
                if GLEntry."Global Dimension 1 Code" = ExpectedDim1 then
                    DimensionFlowed := true;
            until GLEntry.Next() = 0;

        Assert.IsTrue(DimensionFlowed, 'Shortcut Dimension 1 Code must flow from source Purch. Inv. Header to G/L Entry.');
    end;

    [Test]
    procedure Test_AccrualEngine_OuterDuplicateGuard_RaisesError()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        PostingGroup: Code[20];
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-04';
        SeedPostingSetup(PostingGroup, '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");

        // Pre-mark request as Posted.
        CalcHeader."Posting Status" := CalcHeader."Posting Status"::Posted;
        CalcHeader.Modify();

        // Exercise + Verify - must raise the explicit duplicate-post error.
        asserterror AccrualEngine.Run(CalcHeader);
        Assert.ExpectedError('already been posted');
    end;

    [Test]
    procedure Test_AccrualEngine_MarksCalcLedgerEntryAsPosted()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        ReloadCalcLedgEntry: Record "RBT Calc Ledg Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        PostingGroup: Code[20];
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-05';
        SeedPostingSetup(PostingGroup, '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, '', 100);
        Assert.IsTrue(not CalcLedgEntry.Posted, 'Pre-condition: row must start unposted.');

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify
        ReloadCalcLedgEntry.Get(CalcLedgEntry."Entry No.");
        Assert.IsTrue(ReloadCalcLedgEntry.Posted, 'Posted flag must be true after engine run.');
        Assert.IsTrue(ReloadCalcLedgEntry."Posted At" <> 0DT, 'Posted At must be stamped after engine run.');
    end;

    [Test]
    procedure Test_AccrualEngine_WritesAuditEntry()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        AuditEntry: Record "RBT Audit Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        Assert: Codeunit "Assert";
        PostingGroup: Code[20];
    begin
        // Setup
        Initialize();
        PostingGroup := 'RBT-PG-06';
        SeedPostingSetup(PostingGroup, '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, PostingGroup);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", CalcLedgEntry."Source Type"::Purchase, '', 100);

        // Exercise
        AccrualEngine.Run(CalcHeader);

        // Verify - audit entry for the agreement with Action = 'Post Accrual'.
        AuditEntry.SetRange("Document No.", Header."No.");
        AuditEntry.SetRange(Action, 'Post Accrual');
        Assert.IsTrue(not AuditEntry.IsEmpty(), 'An RBT Audit Entry with Action ''Post Accrual'' must be written on successful run.');
    end;

    // ====================================================================
    // T-005 helpers
    // ====================================================================

    local procedure SeedPostingSetup(PostingGroupCode: Code[20]; ExpenseAcc: Code[20]; AccrualAcc: Code[20])
    var
        PostingSetup: Record "RBT Rebate Post Set";
        GLAccount: Record "G/L Account";
    begin
        EnsureGLAccount(GLAccount, ExpenseAcc);
        EnsureGLAccount(GLAccount, AccrualAcc);

        if not PostingSetup.Get(PostingGroupCode) then begin
            PostingSetup.Init();
            PostingSetup."Rebate Group Code" := PostingGroupCode;
            PostingSetup."Expense Account No." := ExpenseAcc;
            PostingSetup."Accrual Account No." := AccrualAcc;
            PostingSetup.Insert();
        end else begin
            PostingSetup."Expense Account No." := ExpenseAcc;
            PostingSetup."Accrual Account No." := AccrualAcc;
            PostingSetup.Modify();
        end;
    end;

    local procedure EnsureGLAccount(var GLAccount: Record "G/L Account"; AccountNo: Code[20])
    begin
        if GLAccount.Get(AccountNo) then
            exit;
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := true;
        if GLAccount.Insert() then;
    end;

    local procedure CreateActiveHeaderWithPostingGroup(var Header: Record "RBT Agreement Header"; PostingGroupCode: Code[20])
    var
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        CreateAgreementHeader(Header, Header."Type"::Vendor);
        Header."Posting Group" := PostingGroupCode;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);
        Header.Get(Header."No.");
    end;

    local procedure InsertCalcLedgerEntry(var CalcLedgEntry: Record "RBT Calc Ledg Entry"; AgreementNo: Code[20]; CalcRequestNo: Code[20]; SourceType: Option Purchase,Sales; SourceTransNo: Code[20]; AmountFCY: Decimal)
    begin
        CalcLedgEntry.Init();
        CalcLedgEntry."Agreement No." := AgreementNo;
        CalcLedgEntry."Version No." := 1;
        CalcLedgEntry."Rule No." := 0;
        CalcLedgEntry."Source Type" := SourceType;
        CalcLedgEntry."Source Trans. No." := SourceTransNo;
        CalcLedgEntry."Amount FCY" := AmountFCY;
        CalcLedgEntry."Amount LCY" := AmountFCY;
        CalcLedgEntry."Exchange Rate" := 1;
        CalcLedgEntry."Currency Code" := '';
        CalcLedgEntry."Posting Date" := WorkDate();
        CalcLedgEntry."Calculation Req. No." := CalcRequestNo;
        CalcLedgEntry."Created At" := CurrentDateTime();
        CalcLedgEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(CalcLedgEntry."Created By"));
        CalcLedgEntry.Insert(false);
    end;

    // ====================================================================
    // T-008 - Settlement lifecycle test coverage (Task 184)
    // ====================================================================

    [Test]
    procedure TestSettlementNoSeriesAssignment()
    var
        Settlement: Record "RBT Settlement Header";
        Assert: Codeunit "Assert";
    begin
        Initialize();
        EnsureSettlementSetup();

        Settlement.Init();
        Settlement.Insert(true);

        Assert.IsTrue(CopyStr(Settlement."No.", 1, 9) = 'RBT-SETL-', 'Settlement No. must come from RBT-SETL series.');
        Assert.AreEqual('RBT-SETL', Settlement."No. Series", 'No. Series must be RBT-SETL.');
    end;

    [Test]
    procedure TestSubmitForApprovalTransitionsDraftToPending()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        AuditEntry: Record "RBT Audit Entry";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S01');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);

        SettlementMgmt.SubmitForApproval(Settlement);
        Settlement.Get(Settlement."No.");

        Assert.AreEqual(Settlement.Status::Pending, Settlement.Status, 'Status must transition to Pending after Submit.');

        AuditEntry.SetRange("Document No.", Settlement."No.");
        AuditEntry.SetRange(Action, 'Submit');
        Assert.IsTrue(not AuditEntry.IsEmpty(), 'Submit audit entry must be written.');
    end;

    [Test]
    procedure TestSubmitWithNoLinesFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
    begin
        Initialize();
        EnsureSettlementSetup();
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S02');

        Settlement.Init();
        Settlement.Insert(true);
        Settlement.Validate("Agreement No.", Header."No.");
        Settlement.Amount := 100;
        Settlement.Modify();

        asserterror SettlementMgmt.SubmitForApproval(Settlement);
        Assert.ExpectedError('no lines');
    end;

    [Test]
    procedure TestSubmitWithMismatchedAmountFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S03');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);

        // Force a mismatch.
        Settlement.Amount := 999;
        Settlement.Modify();

        asserterror SettlementMgmt.SubmitForApproval(Settlement);
        Assert.ExpectedError('does not match');
    end;

    [Test]
    procedure TestPostVendorAgreementCreatesPurchaseCreditMemo()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S04', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S04');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);

        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        Settlement.Get(Settlement."No.");
        Assert.AreEqual(Settlement.Status::Posted, Settlement.Status, 'Settlement must be Posted.');
        Assert.AreEqual(Settlement."Credit Memo Type"::Purchase, Settlement."Credit Memo Type", 'Credit Memo Type must be Purchase for Vendor agreement.');
        Assert.IsTrue(Settlement."Posted Credit Memo No." <> '', 'Posted Credit Memo No. must be non-blank.');
        Assert.IsTrue(PurchCrMemoHdr.Get(Settlement."Posted Credit Memo No."), 'Purch. Cr. Memo Hdr must exist for the posted credit memo.');
    end;

    [Test]
    procedure TestPostCustomerAgreementCreatesSalesCreditMemo()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S05', '9101', '9102');
        CreateActiveCustomerHeaderWithPostingGroup(Header, 'RBT-PG-S05');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);

        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        Settlement.Get(Settlement."No.");
        Assert.AreEqual(Settlement.Status::Posted, Settlement.Status, 'Settlement must be Posted.');
        Assert.AreEqual(Settlement."Credit Memo Type"::Sales, Settlement."Credit Memo Type", 'Credit Memo Type must be Sales for Customer agreement.');
        Assert.IsTrue(Settlement."Posted Credit Memo No." <> '', 'Posted Credit Memo No. must be non-blank.');
        Assert.IsTrue(SalesCrMemoHdr.Get(Settlement."Posted Credit Memo No."), 'Sales Cr.Memo Header must exist for the posted credit memo.');
    end;

    [Test]
    procedure TestPostMarksAccrualEntriesClosed()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementLine: Record "RBT Settlement Line";
        LedgerEntry: Record "RBT Rebate Ledg Ent";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S06', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S06');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);

        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        Assert.IsTrue(SettlementLine.FindSet(), 'Settlement must have lines.');
        repeat
            LedgerEntry.Get(SettlementLine."Accrual Entry No.");
            Assert.AreEqual(LedgerEntry.Status::Closed, LedgerEntry.Status, 'Accrual ledger entry must be Closed after settlement post.');
            Assert.AreEqual(Settlement."No.", LedgerEntry."Closed by Settlement No.", 'Closed by Settlement No. must reference the settlement.');
        until SettlementLine.Next() = 0;
    end;

    [Test]
    procedure TestPostWithNoOpenAccrualsFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        LedgerEntry: Record "RBT Rebate Ledg Ent";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S07', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S07');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);
        SettlementMgmt.SubmitForApproval(Settlement);

        // Pre-close the accrual entry via skip-trigger so the pre-post guard finds nothing open.
        LedgerEntry.Get(AccrualEntryNo);
        LedgerEntry.Status := LedgerEntry.Status::Closed;
        LedgerEntry.Modify(false);

        asserterror SettlementMgmt.PostSettlement(Settlement);
        Assert.ExpectedError('no open accrual entries');
    end;

    [Test]
    procedure TestPostAlreadyPostedFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S08', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S08');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);
        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        Settlement.Get(Settlement."No.");
        asserterror SettlementMgmt.PostSettlement(Settlement);
        Assert.ExpectedError('already been posted');
    end;

    [Test]
    procedure TestPostBlockedVendorFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        Vendor: Record Vendor;
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S09', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S09');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);
        SettlementMgmt.SubmitForApproval(Settlement);

        // Block the vendor.
        Vendor.Get(Header."Vendor No.");
        Vendor.Blocked := Vendor.Blocked::All;
        Vendor.Modify();

        asserterror SettlementMgmt.PostSettlement(Settlement);

        // Restore for cleanliness.
        Vendor.Get(Header."Vendor No.");
        Vendor.Blocked := Vendor.Blocked::" ";
        Vendor.Modify();
        Assert.IsTrue(true, 'Posting against blocked vendor must error.');
    end;

    [Test]
    procedure TestPostBlockedCustomerFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        Customer: Record Customer;
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S10', '9101', '9102');
        CreateActiveCustomerHeaderWithPostingGroup(Header, 'RBT-PG-S10');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);
        SettlementMgmt.SubmitForApproval(Settlement);

        // Block the customer.
        Customer.Get(Header."Customer No.");
        Customer.Blocked := Customer.Blocked::All;
        Customer.Modify();

        asserterror SettlementMgmt.PostSettlement(Settlement);

        Customer.Get(Header."Customer No.");
        Customer.Blocked := Customer.Blocked::" ";
        Customer.Modify();
        Assert.IsTrue(true, 'Posting against blocked customer must error.');
    end;

    [Test]
    procedure TestModifyPostedSettlementFails()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        AccrualEntryNo: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        SeedPostingSetup('RBT-PG-S11', '9101', '9102');
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S11');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);
        CreateSettlementWithLine(Settlement, Header."No.", AccrualEntryNo, 250);
        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        Settlement.Get(Settlement."No.");
        Settlement.Amount := 99;
        asserterror Settlement.Modify();
        Assert.ExpectedError('cannot be modified');
    end;

    [Test]
    procedure TestSuggestAccrualsPopulatesLines()
    var
        Settlement: Record "RBT Settlement Header";
        Header: Record "RBT Agreement Header";
        SettlementLine: Record "RBT Settlement Line";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        Assert: Codeunit "Assert";
        LineCount: Integer;
    begin
        Initialize();
        EnsureSettlementSetup();
        CreateActiveHeaderWithPostingGroup(Header, 'RBT-PG-S12');
        InsertOpenAccrualLedgerEntry(Header."No.", 100);
        InsertOpenAccrualLedgerEntry(Header."No.", 200);
        InsertOpenAccrualLedgerEntry(Header."No.", 300);

        Settlement.Init();
        Settlement.Insert(true);
        Settlement.Validate("Agreement No.", Header."No.");
        Settlement.Modify();

        SettlementMgmt.SuggestAccruals(Settlement);

        Settlement.Get(Settlement."No.");
        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        LineCount := SettlementLine.Count();
        Assert.AreEqual(3, LineCount, 'SuggestAccruals must insert one line per open accrual entry.');
        Assert.AreEqual(600, Settlement.Amount, 'Header Amount must equal sum of suggested line amounts.');
    end;

    // ====================================================================
    // T-008 helpers
    // ====================================================================

    local procedure EnsureSettlementSetup()
    var
        RebateSetup: Record "RBT Rebate Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get('RBT-SETL') then begin
            NoSeries.Init();
            NoSeries.Code := 'RBT-SETL';
            NoSeries.Description := 'Rebate Settlements';
            NoSeries."Default Nos." := true;
            NoSeries.Insert();
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := 'RBT-SETL';
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'RBT-SETL-0001';
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup."Primary Key" := '';
            RebateSetup.Insert();
        end;
        if RebateSetup."Settlement Nos." <> 'RBT-SETL' then begin
            RebateSetup."Settlement Nos." := 'RBT-SETL';
            RebateSetup.Modify();
        end;
    end;

    local procedure CreateSettlementWithLine(var Settlement: Record "RBT Settlement Header"; AgreementNo: Code[20]; AccrualEntryNo: Integer; Amt: Decimal)
    var
        SettlementLine: Record "RBT Settlement Line";
    begin
        Settlement.Init();
        Settlement.Insert(true);
        Settlement.Validate("Agreement No.", AgreementNo);
        Settlement.Amount := Amt;
        Settlement.Modify();

        SettlementLine.Init();
        SettlementLine."Settlement No." := Settlement."No.";
        SettlementLine."Line No." := 10000;
        SettlementLine.Validate("Accrual Entry No.", AccrualEntryNo);
        SettlementLine.Amount := Amt;
        SettlementLine.Insert();
    end;

    local procedure InsertOpenAccrualLedgerEntry(AgreementNo: Code[20]; Amt: Decimal): Integer
    var
        LedgerEntry: Record "RBT Rebate Ledg Ent";
    begin
        LedgerEntry.Init();
        LedgerEntry."Agreement No." := AgreementNo;
        LedgerEntry."Posting Date" := WorkDate();
        LedgerEntry."Document No." := 'ACR-TEST';
        LedgerEntry.Amount := Amt;
        LedgerEntry."Amount (LCY)" := Amt;
        LedgerEntry."Entry Type" := LedgerEntry."Entry Type"::Accrual;
        LedgerEntry.Status := LedgerEntry.Status::Open;
        LedgerEntry.Insert(true);
        exit(LedgerEntry."Entry No.");
    end;

    local procedure CreateActiveCustomerHeaderWithPostingGroup(var Header: Record "RBT Agreement Header"; PostingGroupCode: Code[20])
    var
        Customer: Record Customer;
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        Customer.Init();
        Customer."No." := 'C001';
        Customer.Name := 'Test Customer';
        if Customer.Insert() then;

        Header.Init();
        Header."Type" := Header."Type"::Customer;
        Header."Customer No." := Customer."No.";
        Header."Start Date" := WorkDate();
        Header.Insert(true);
        Header."Posting Group" := PostingGroupCode;
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);
        Header.Get(Header."No.");
    end;


}

codeunit 50106 "Assert"
{
    procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    begin
        if Format(Expected) <> Format(Actual) then
            Error('Assert.AreEqual failed. Expected: %1, Actual: %2. %3', Expected, Actual, Msg);
    end;

    procedure IsTrue(Condition: Boolean; Msg: Text)
    begin
        if not Condition then
            Error('Assert.IsTrue failed. %1', Msg);
    end;

    procedure ExpectedError(ExpectedError: Text)
    var
        LastError: Text;
    begin
        LastError := GetLastErrorText();
        if not LastError.Contains(ExpectedError) then
            Error('Expected error "%1" but got "%2"', ExpectedError, LastError);
    end;
}
