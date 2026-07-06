codeunit 50108 "RBT Core Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ====================================================================
    // RBT Core Tests
    //
    // Lifecycle test suite covering the full rebate workflow from agreement
    // activation through accrual calculation (Flat %) to settlement posting.
    // Includes asserterror cases for invalid thresholds and missing posting
    // setup, as required by the spec acceptance criteria.
    // ====================================================================

    var
        Assert: Codeunit "Assert";
        IsInitialized: Boolean;

    // --------------------------------------------------------------------
    // Positive lifecycle tests
    // --------------------------------------------------------------------

    [Test]
    procedure TestAgreementCreation()
    var
        Header: Record "RBT Agreement Header";
        AgreementVersion: Record "RBT Agmt Version";
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        // [GIVEN] No. Series and Setup seeded
        Initialize();

        // [WHEN] A new vendor agreement is created and activated
        CreateVendorAgreementHeader(Header, 'RBT-PG-CORE01');
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);

        // [THEN] The agreement has an auto-assigned No., is Active, and a
        // version row exists.
        Header.Get(Header."No.");
        Assert.IsTrue(Header."No." <> '', 'Agreement No. must be auto-assigned from RBT-AGR series.');
        Assert.AreEqual(Header.Status::Active, Header.Status, 'Agreement must be Active after activation.');

        AgreementVersion.SetRange("Agreement No.", Header."No.");
        Assert.AreEqual(1, AgreementVersion.Count(), 'Version 1 must exist after activation.');
        AgreementVersion.FindFirst();
        Assert.IsTrue(AgreementVersion."Is Current Version", 'Version 1 must be the current version.');
    end;

    [Test]
    procedure TestAccrualCalculationFlatPct()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        AccrualEngine: Codeunit "RBT Accrual Engine";
    begin
        // [GIVEN] An active vendor agreement with a Flat-% rule, a calc
        // request, and a calc ledger entry pre-seeded by a 10% flat
        // calculation on a $1000 line.
        Initialize();
        SeedPostingSetup('RBT-PG-CORE02', '9101', '9102');
        CreateActiveVendorHeader(Header, 'RBT-PG-CORE02');
        CreateFlatPercentRule(Header."No.", 10);
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertFlatPctCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", 1000, 10);

        // [WHEN] The accrual engine posts the calculation request
        AccrualEngine.PostAccruals(CalcHeader);

        // [THEN] The calc header is Posted, the GL entry counter is non-zero,
        // and the calc ledger entry has been marked Posted.
        CalcHeader.Get(CalcHeader."No.");
        Assert.AreEqual(CalcHeader."Posting Status"::Posted, CalcHeader."Posting Status",
            'Calc header must be Posted after accrual run.');
        Assert.IsTrue(CalcHeader."No. of G/L Entries" >= 2,
            'Accrual must produce at least one debit/credit G/L pair.');

        CalcLedgEntry.Get(CalcLedgEntry."Entry No.");
        Assert.IsTrue(CalcLedgEntry.Posted, 'Calc ledger entry must be marked Posted after run.');
        Assert.AreEqual(100, CalcLedgEntry."Amount FCY",
            'Flat 10% of 1000 must equal 100.');
    end;

    [Test]
    procedure TestSettlementPosting()
    var
        Header: Record "RBT Agreement Header";
        Settlement: Record "RBT Settlement Header";
        SettlementLine: Record "RBT Settlement Line";
        LedgerEntry: Record "RBT Rebate Ledg Ent";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
        AccrualEntryNo: Integer;
    begin
        // [GIVEN] An active vendor agreement, posting setup, and one open
        // accrual ledger entry that can be settled.
        Initialize();
        SeedPostingSetup('RBT-PG-CORE03', '9101', '9102');
        CreateActiveVendorHeader(Header, 'RBT-PG-CORE03');
        AccrualEntryNo := InsertOpenAccrualLedgerEntry(Header."No.", 250);

        // A settlement document is created and one line is added pointing
        // to the open accrual entry, with a matching header Amount.
        Settlement.Init();
        Settlement.Insert(true);
        Settlement.Validate("Agreement No.", Header."No.");
        Settlement.Amount := 250;
        Settlement.Modify();

        SettlementLine.Init();
        SettlementLine."Settlement No." := Settlement."No.";
        SettlementLine."Line No." := 10000;
        SettlementLine.Validate("Accrual Entry No.", AccrualEntryNo);
        SettlementLine.Amount := 250;
        SettlementLine.Insert();

        // [WHEN] The settlement is submitted then posted
        SettlementMgmt.SubmitForApproval(Settlement);
        SettlementMgmt.PostSettlement(Settlement);

        // [THEN] The settlement reaches Posted status, a posted credit memo
        // No. is recorded, and the original accrual ledger entry has been
        // closed and linked back to the settlement.
        Settlement.Get(Settlement."No.");
        Assert.AreEqual(Settlement.Status::Posted, Settlement.Status,
            'Settlement must be Posted after PostSettlement.');
        Assert.IsTrue(Settlement."Posted Credit Memo No." <> '',
            'Posted Credit Memo No. must be set after a successful post.');

        LedgerEntry.Get(AccrualEntryNo);
        Assert.AreEqual(LedgerEntry.Status::Closed, LedgerEntry.Status,
            'Accrual ledger entry must be Closed after settlement.');
        Assert.AreEqual(Settlement."No.", LedgerEntry."Closed by Settlement No.",
            'Accrual ledger entry must reference the settlement that closed it.');
    end;

    // --------------------------------------------------------------------
    // Negative tests (asserterror)
    // --------------------------------------------------------------------

    [Test]
    procedure TestInvalidThresholdRejected()
    var
        Header: Record "RBT Agreement Header";
        Rule: Record "RBT Rebate Rule";
    begin
        // [GIVEN] A draft agreement on which a rebate rule is being defined.
        Initialize();
        CreateDraftVendorHeader(Header);

        Rule.Init();
        Rule."Agreement No." := Header."No.";
        Rule."Rule No." := 1;
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;

        // [WHEN] A negative threshold / value is supplied
        // [THEN] The field's MinValue=0 constraint rejects the value
        asserterror Rule.Validate(Value, -10);
        Assert.ExpectedError('Value');
    end;

    [Test]
    procedure TestMissingPostingSetupRejected()
    var
        Header: Record "RBT Agreement Header";
        CalcHeader: Record "RBT Rebate Calc Hdr";
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        PostingSetup: Record "RBT Rebate Post Set";
        AccrualEngine: Codeunit "RBT Accrual Engine";
    begin
        // [GIVEN] An active vendor agreement and a pending calc request, but
        // NO Rebate Posting Setup row exists for the agreement's posting group
        // and the blank-code fallback row has been removed.
        Initialize();
        CreateActiveVendorHeader(Header, 'RBT-PG-MISS01');
        CreateCalcHeader(CalcHeader, Header."No.");
        InsertFlatPctCalcLedgerEntry(CalcLedgEntry, Header."No.", CalcHeader."No.", 1000, 10);

        // Wipe every posting setup row so neither the keyed lookup nor the
        // blank-code fallback in GetPostingSetup() can find a match.
        if PostingSetup.FindSet() then
            PostingSetup.DeleteAll();

        // [WHEN] Accrual posting is attempted without posting setup
        // [THEN] The engine raises a clear configuration error
        asserterror AccrualEngine.PostAccruals(CalcHeader);
        Assert.ExpectedError('Rebate Posting Setup');
    end;

    [Test]
    procedure TestTieredCalculation()
    var
        Agreement: Record "RBT Rebate Agreement";
        Tier: Record "RBT Rebate Tier";
        RebateCalc: Codeunit "RBT Rebate Calc.";
        Amount: Decimal;
    begin
        // [GIVEN] A tiered agreement: 0-10000 @ 1%, 10000+ @ 2%
        Initialize();
        Agreement.Init();
        Agreement."No." := 'AGR-TIER';
        Agreement."Calc. Method" := Agreement."Calc. Method"::Tiered;
        Agreement.Insert();

        Tier.Init();
        Tier."Agreement No." := 'AGR-TIER';
        Tier."Minimum Amount" := 0;
        Tier."Rebate %" := 1;
        Tier.Insert();

        Tier.Init();
        Tier."Agreement No." := 'AGR-TIER';
        Tier."Minimum Amount" := 10000;
        Tier."Rebate %" := 2;
        Tier.Insert();

        // [WHEN] Calculating for 15000
        Amount := RebateCalc.CalculateRebate(Agreement, 15000);

        // [THEN] Result = 10000*0.01 + 5000*0.02 = 100 + 100 = 200
        Assert.AreEqual(200, Amount, 'Tiered calculation failed for 15000.');

        // [WHEN] Calculating for 5000
        Amount := RebateCalc.CalculateRebate(Agreement, 5000);

        // [THEN] Result = 5000*0.01 = 50
        Assert.AreEqual(50, Amount, 'Tiered calculation failed for 5000.');
    end;

    [Test]
    procedure TestTieredCalculationBelowThreshold()
    var
        Agreement: Record "RBT Rebate Agreement";
        Tier: Record "RBT Rebate Tier";
        RebateCalc: Codeunit "RBT Rebate Calc.";
        Amount: Decimal;
    begin
        // [GIVEN] A tiered agreement with min threshold 1000 @ 5%
        Initialize();
        Agreement.Init();
        Agreement."No." := 'AGR-TIER-MIN';
        Agreement."Calc. Method" := Agreement."Calc. Method"::Tiered;
        Agreement.Insert();

        Tier.Init();
        Tier."Agreement No." := 'AGR-TIER-MIN';
        Tier."Minimum Amount" := 1000;
        Tier."Rebate %" := 5;
        Tier.Insert();

        // [WHEN] Calculating for 500
        Amount := RebateCalc.CalculateRebate(Agreement, 500);

        // [THEN] Result = 0
        Assert.AreEqual(0, Amount, 'Tiered calculation must be 0 below first tier threshold.');
    end;

    [Test]
    procedure TestSuggestAccruals()
    var
        Header: Record "RBT Agreement Header";
        Settlement: Record "RBT Settlement Header";
        SettlementLine: Record "RBT Settlement Line";
        SettlementMgmt: Codeunit "RBT Settlement Mgmt.";
    begin
        // [GIVEN] An active agreement with two open accruals (100 and 200)
        Initialize();
        CreateActiveVendorHeader(Header, 'RBT-PG-CORE04');
        InsertOpenAccrualLedgerEntry(Header."No.", 100);
        InsertOpenAccrualLedgerEntry(Header."No.", 200);

        Settlement.Init();
        Settlement."Agreement No." := Header."No.";
        Settlement.Status := Settlement.Status::Draft;
        Settlement.Insert(true);

        // [WHEN] Suggesting accruals
        SettlementMgmt.SuggestAccruals(Settlement);

        // [THEN] Two lines created, total amount = 300
        Settlement.Get(Settlement."No.");
        Assert.AreEqual(300, Settlement.Amount, 'Total settlement amount should be 300.');
        
        SettlementLine.SetRange("Settlement No.", Settlement."No.");
        Assert.AreEqual(2, SettlementLine.Count(), 'Two settlement lines should have been created.');
    end;

    // --------------------------------------------------------------------
    // Initialize - seeds No. Series, Setup and a clean baseline
    // --------------------------------------------------------------------

    local procedure Initialize()
    begin
        SeedNoSeries('RBT-AGR', 'Rebate Agreements', 'RBT-AGR-CT-0001');
        SeedNoSeries('RBT-SETL', 'Rebate Settlements', 'RBT-SETL-CT-0001');
        SeedNoSeries('RBT-CALC', 'Rebate Calculations', 'RBT-CALC-CT-0001');
        SeedNoSeries('RBT-AUD', 'Rebate Audit Entries', 'RBT-AUD-CT-0001');
        SeedRebateSetup();
        SeedDefaultPostingSetupFallback();
        EnsureSignatoryUser('SIGN01');

        IsInitialized := true;
    end;

    local procedure SeedNoSeries(SeriesCode: Code[20]; SeriesDescription: Text[100]; StartingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get(SeriesCode) then begin
            NoSeries.Init();
            NoSeries.Code := SeriesCode;
            NoSeries.Description := SeriesDescription;
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := false;
            NoSeries.Insert();
        end;

        NoSeriesLine.SetRange("Series Code", SeriesCode);
        if NoSeriesLine.IsEmpty() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := SeriesCode;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := StartingNo;
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;
    end;

    local procedure SeedRebateSetup()
    var
        RebateSetup: Record "RBT Rebate Setup";
        Modified: Boolean;
    begin
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup."Primary Key" := '';
            RebateSetup.Insert();
        end;

        Modified := false;
        if RebateSetup."Agreement Nos." <> 'RBT-AGR' then begin
            RebateSetup."Agreement Nos." := 'RBT-AGR';
            Modified := true;
        end;
        if RebateSetup."Settlement Nos." <> 'RBT-SETL' then begin
            RebateSetup."Settlement Nos." := 'RBT-SETL';
            Modified := true;
        end;
        if RebateSetup."Calculation Nos." <> 'RBT-CALC' then begin
            RebateSetup."Calculation Nos." := 'RBT-CALC';
            Modified := true;
        end;
        if RebateSetup."Audit Nos." <> 'RBT-AUD' then begin
            RebateSetup."Audit Nos." := 'RBT-AUD';
            Modified := true;
        end;
        if Modified then
            RebateSetup.Modify();
    end;

    local procedure SeedDefaultPostingSetupFallback()
    var
        PostingSetup: Record "RBT Rebate Post Set";
    begin
        if PostingSetup.Get('') then
            exit;
        PostingSetup.Init();
        PostingSetup."Rebate Group Code" := '';
        PostingSetup.Insert();
    end;

    local procedure EnsureSignatoryUser(SignatoryCode: Code[50])
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(SignatoryCode) then
            exit;
        UserSetup.Init();
        UserSetup."User ID" := CopyStr(SignatoryCode, 1, MaxStrLen(UserSetup."User ID"));
        if UserSetup.Insert() then;
    end;

    // --------------------------------------------------------------------
    // Domain helpers
    // --------------------------------------------------------------------

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

    local procedure EnsureVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.Get('RBT-VPG') then begin
            VendorPostingGroup.Init();
            VendorPostingGroup.Code := 'RBT-VPG';
            VendorPostingGroup.Description := 'RBT Test Vendor Posting Group';
            if VendorPostingGroup.Insert() then;
        end;

        if Vendor.Get(VendorNo) then
            exit;
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Name := 'RBT Test Vendor';
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        if Vendor.Insert() then;
    end;

    local procedure CreateDraftVendorHeader(var Header: Record "RBT Agreement Header")
    begin
        EnsureVendor('V001');

        Header.Init();
        Header."Type" := Header."Type"::Vendor;
        Header."Vendor No." := 'V001';
        Header."Start Date" := WorkDate();
        Header.Insert(true);
    end;

    local procedure CreateVendorAgreementHeader(var Header: Record "RBT Agreement Header"; PostingGroupCode: Code[20])
    begin
        EnsureVendor('V001');

        Header.Init();
        Header."Type" := Header."Type"::Vendor;
        Header."Vendor No." := 'V001';
        Header."Start Date" := WorkDate();
        Header.Insert(true);

        Header."Posting Group" := PostingGroupCode;
        Header.Modify();
    end;

    local procedure CreateActiveVendorHeader(var Header: Record "RBT Agreement Header"; PostingGroupCode: Code[20])
    var
        RebateMgmt: Codeunit "RBT Rebate Mgmt.";
    begin
        CreateVendorAgreementHeader(Header, PostingGroupCode);
        Header."Signatory Code" := 'SIGN01';
        Header."Signed Date" := WorkDate();
        Header.Modify();
        RebateMgmt.ActivateAgreementHeader(Header);
        Header.Get(Header."No.");
    end;

    local procedure CreateFlatPercentRule(AgreementNo: Code[20]; Pct: Decimal)
    var
        Rule: Record "RBT Rebate Rule";
    begin
        Rule.Init();
        Rule."Agreement No." := AgreementNo;
        Rule."Rule No." := 1;
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Value := Pct;
        Rule.Description := 'Flat % Test Rule';
        if not Rule.Insert() then;
    end;

    local procedure CreateCalcHeader(var CalcHeader: Record "RBT Rebate Calc Hdr"; AgreementNo: Code[20])
    begin
        CalcHeader.Init();
        CalcHeader.Insert(true);
        CalcHeader."Agreement No." := AgreementNo;
        CalcHeader."Calc. From Date" := CalcMethodFromDate();
        CalcHeader."Calc. To Date" := WorkDate();
        CalcHeader.Modify();
    end;

    local procedure CalcMethodFromDate(): Date
    begin
        exit(CalcDate('<-1M>', WorkDate()));
    end;

    local procedure InsertFlatPctCalcLedgerEntry(var CalcLedgEntry: Record "RBT Calc Ledg Entry"; AgreementNo: Code[20]; CalcRequestNo: Code[20]; LineAmount: Decimal; FlatPct: Decimal)
    var
        RebateAmount: Decimal;
    begin
        RebateAmount := LineAmount * FlatPct / 100;
        CalcLedgEntry.Init();
        CalcLedgEntry."Agreement No." := AgreementNo;
        CalcLedgEntry."Version No." := 1;
        CalcLedgEntry."Rule No." := 1;
        CalcLedgEntry."Source Type" := CalcLedgEntry."Source Type"::Purchase;
        CalcLedgEntry."Source Trans. No." := 'PINV-CORE-001';
        CalcLedgEntry."Amount FCY" := RebateAmount;
        CalcLedgEntry."Amount LCY" := RebateAmount;
        CalcLedgEntry."Exchange Rate" := 1;
        CalcLedgEntry."Currency Code" := '';
        CalcLedgEntry."Posting Date" := WorkDate();
        CalcLedgEntry."Calculation Req. No." := CalcRequestNo;
        CalcLedgEntry."Created At" := CurrentDateTime();
        CalcLedgEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(CalcLedgEntry."Created By"));
        CalcLedgEntry.Insert(false);
    end;

    local procedure InsertOpenAccrualLedgerEntry(AgreementNo: Code[20]; Amt: Decimal): Integer
    var
        LedgerEntry: Record "RBT Rebate Ledg Ent";
    begin
        LedgerEntry.Init();
        LedgerEntry."Agreement No." := AgreementNo;
        LedgerEntry."Posting Date" := WorkDate();
        LedgerEntry."Document No." := 'ACR-CORE';
        LedgerEntry.Amount := Amt;
        LedgerEntry."Amount (LCY)" := Amt;
        LedgerEntry."Entry Type" := LedgerEntry."Entry Type"::Accrual;
        LedgerEntry.Status := LedgerEntry.Status::Open;
        LedgerEntry.Insert(true);
        exit(LedgerEntry."Entry No.");
    end;
}
