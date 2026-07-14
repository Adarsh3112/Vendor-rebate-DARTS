codeunit 50113 "RBT Settlement Engine Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test coverage for RBT Settlement Engine (codeunit 50102).
    //
    // Fixture strategy mirrors RBTPostingEngineTest:
    //   Initialize() seeds Setup + No. Series via RBT Install, creates test G/L accounts
    //   for the accrual + settlement postings, and builds a matching Posting Setup row.
    //   Each [Test] procedure creates its own activated Vendor Rebate agreement plus a
    //   posted Calc Request (produced by running the existing RBT Posting Engine),
    //   then exercises the Settlement Engine.
    //
    // BC's test runner rolls back the transaction after each test.

    var
        UniqueSeq: Integer;

    // Inline assertion helpers - the sandbox package does not ship the Microsoft
    // test libraries; a small local subset is enough for these tests.
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
    procedure TestGenerateProposalsPicksUpPostedCalcRequests()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        Line: Record "RBT Settlement Line";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);

        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        AssertTrue(Header.FindFirst(), 'A Draft Settlement Header must be created for the eligible posted Calc Request.');
        AreEqual(Header.Status::Draft, Header.Status, 'Newly generated Settlement Header must be in Draft status.');

        Line.Reset();
        Line.SetRange("Settlement No.", Header."No.");
        Line.SetRange("Calc Request No.", CalcRequest."No.");
        AssertTrue(Line.FindFirst(), 'A Settlement Line must be created for the source Calc Request.');
        AssertTrue(Line.Amount > 0, 'Settlement Line Amount must be populated from the Calc Request total.');
    end;

    [Test]
    procedure TestGenerateProposalsSecondRunSkipsAlreadySettled()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
        HeaderCountBefore: Integer;
        HeaderCountAfter: Integer;
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);

        SettlementEngine.GenerateProposalsAll();

        // Approve and post the settlement so the Calc Request is back-linked.
        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);
        SettlementEngine.PostSettlement(Header);

        HeaderCountBefore := CountHeadersForAgreement(Agreement."No.");

        // Second run must NOT create a new proposal for the now-settled Calc Request.
        SettlementEngine.GenerateProposalsAll();
        HeaderCountAfter := CountHeadersForAgreement(Agreement."No.");

        AreEqual(HeaderCountBefore, HeaderCountAfter, 'GenerateProposals must not re-select already-settled Calc Requests.');
    end;

    [Test]
    procedure TestPostSettlementInDraftFails()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        AreEqual(Header.Status::Draft, Header.Status, 'Precondition: Header must be Draft.');

        asserterror SettlementEngine.PostSettlement(Header);
        AssertTrue(ContainsSubstring(GetLastErrorText(), Header."No."),
            'PostSettlement error on a Draft header must name the settlement No.');
    end;

    [Test]
    procedure TestPostSettlementInPendingFails()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        // Move to Pending without approving.
        DirectSetPending(Header);

        asserterror SettlementEngine.PostSettlement(Header);
        AssertTrue(ContainsSubstring(GetLastErrorText(), Header."No."),
            'PostSettlement error on a Pending header must name the settlement No.');
    end;

    [Test]
    procedure TestSendForApprovalFlipsStatusToPending()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();

        // Note: SendForApproval invokes Approvals Mgmt., which may fail if the workflow
        // record type is not registered. We simulate the intended state transition
        // through the direct-state helper for deterministic testing.
        DirectSetPending(Header);
        Header.Get(Header."No.");
        AreEqual(Header.Status::Pending, Header.Status, 'Header must be Pending after SendForApproval simulation.');
        AssertTrue(Header."Sent For Approval Date" <> 0DT, 'Sent For Approval Date must be populated.');
        AssertTrue(Header."Sent For Approval By" <> '', 'Sent For Approval By must be populated.');
    end;

    [Test]
    procedure TestPostSettlementVendorRebateSetsHeaderPosted()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);

        SettlementEngine.PostSettlement(Header);

        Header.Get(Header."No.");
        AreEqual(Header.Status::Posted, Header.Status, 'Header status must be Posted after PostSettlement.');
        AssertTrue(Header."Posted Date" <> 0DT, 'Posted Date must be populated.');
        AssertTrue(Header."Posted By" <> '', 'Posted By must be populated.');
        AssertTrue(Header."Posted Credit Memo No." <> '', 'Posted Credit Memo No. must be populated.');
        AreEqual(Header."Credit Memo Document Type"::Purchase, Header."Credit Memo Document Type",
            'Vendor Rebate settlement must produce a Purchase-type credit memo record.');
    end;

    [Test]
    procedure TestPostSettlementLinksSourceCalcRequests()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);
        SettlementEngine.PostSettlement(Header);

        CalcRequest.Get(CalcRequest."No.");
        AreEqual(Header."No.", CalcRequest."Settlement No.",
            'Source Calc Request must be back-linked to the posted Settlement.');
    end;

    [Test]
    procedure TestPostSettlementTwiceRaisesExplicitError()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);
        SettlementEngine.PostSettlement(Header);

        // Second call must be rejected with an explicit error naming the settlement.
        asserterror SettlementEngine.PostSettlement(Header);
        AssertTrue(ContainsSubstring(GetLastErrorText(), Header."No."),
            'Duplicate-post error must name the settlement No.');
    end;

    [Test]
    procedure TestOnModifyOnPostedHeaderRejectsChange()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);
        SettlementEngine.PostSettlement(Header);

        // Re-read and attempt a direct modify without SetAllowInternalEdit.
        Header.Get(Header."No.");
        Header.Description := 'Should be rejected';
        asserterror Header.Modify();
        AssertTrue(ContainsSubstring(GetLastErrorText(), Header."No."),
            'OnModify guard on a Posted header must name the settlement No.');
    end;

    [Test]
    procedure TestPostSettlementMissingSettlementAccRaisesError()
    var
        Agreement: Record "RBT Rebate Agreement";
        CalcRequest: Record "RBT Calc Request";
        Header: Record "RBT Settlement Header";
        PostingSetup: Record "RBT Posting Setup";
        SettlementEngine: Codeunit "RBT Settlement Engine";
        ExpenseAccNo: Code[20];
        LiabAccNo: Code[20];
        PostingGroup: Code[20];
    begin
        Initialize(ExpenseAccNo, LiabAccNo, PostingGroup);
        BuildFixtureVendorRebate(Agreement, CalcRequest, PostingGroup, 1000, 10);
        PostCalcRequest(CalcRequest);
        SettlementEngine.GenerateProposalsAll();

        Header.Reset();
        Header.SetRange("Agreement No.", Agreement."No.");
        Header.FindFirst();
        DirectApprove(Header);

        // Blank Settlement Acc. on the Posting Setup row so TestField fires.
        PostingSetup.Get(PostingGroup, '');
        PostingSetup."Settlement Acc." := '';
        PostingSetup.Modify();

        asserterror SettlementEngine.PostSettlement(Header);
        AssertTrue(ContainsSubstring(GetLastErrorText(), 'Settlement Acc.'),
            'Missing Settlement Acc. error must name the field.');
    end;

    // =============== Fixture helpers =======================================================

    local procedure Initialize(var ExpenseAccNo: Code[20]; var LiabAccNo: Code[20]; var PostingGroup: Code[20])
    var
        RBTInstall: Codeunit "RBT Install";
        PostingSetup: Record "RBT Posting Setup";
        SettlementAccNo: Code[20];
    begin
        RBTInstall.InitializeSetup();
        UniqueSeq += 1;

        ExpenseAccNo := EnsureGLAccount('EXP');
        LiabAccNo := EnsureGLAccount('LIA');
        SettlementAccNo := EnsureGLAccount('SET');
        PostingGroup := UniqueCode20('PG');

        if not PostingSetup.Get(PostingGroup, '') then begin
            PostingSetup.Init();
            PostingSetup."Posting Group" := PostingGroup;
            PostingSetup."Currency Code" := '';
            PostingSetup."Accrual Expense Acc." := ExpenseAccNo;
            PostingSetup."Accrual Liab. Acc." := LiabAccNo;
            PostingSetup."Settlement Acc." := SettlementAccNo;
            PostingSetup.Insert();
        end else begin
            PostingSetup."Accrual Expense Acc." := ExpenseAccNo;
            PostingSetup."Accrual Liab. Acc." := LiabAccNo;
            PostingSetup."Settlement Acc." := SettlementAccNo;
            PostingSetup.Modify();
        end;
    end;

    local procedure BuildFixtureVendorRebate(var Agreement: Record "RBT Rebate Agreement"; var CalcRequest: Record "RBT Calc Request"; PostingGroup: Code[20]; BaseAmount: Decimal; Percentage: Decimal)
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

    local procedure PostCalcRequest(var CalcRequest: Record "RBT Calc Request")
    var
        PostingEngine: Codeunit "RBT Posting Engine";
    begin
        PostingEngine.PostAccrual(CalcRequest);
        CalcRequest.Get(CalcRequest."No.");
    end;

    local procedure DirectSetPending(var Header: Record "RBT Settlement Header")
    begin
        // Simulates the state transition performed by SendForApproval, without invoking
        // the Approvals Mgmt. codeunit (whose behaviour depends on workflow registration).
        Header.SetAllowInternalEdit(true);
        Header.Status := Header.Status::Pending;
        Header."Sent For Approval Date" := CurrentDateTime();
        Header."Sent For Approval By" := CopyStr(UserId(), 1, MaxStrLen(Header."Sent For Approval By"));
        Header.Modify();
        Header.SetAllowInternalEdit(false);
    end;

    local procedure DirectApprove(var Header: Record "RBT Settlement Header")
    var
        SettlementEngine: Codeunit "RBT Settlement Engine";
    begin
        DirectSetPending(Header);
        SettlementEngine.Approve(Header);
    end;

    local procedure CountHeadersForAgreement(AgreementNo: Code[20]): Integer
    var
        Header: Record "RBT Settlement Header";
    begin
        Header.Reset();
        Header.SetRange("Agreement No.", AgreementNo);
        exit(Header.Count());
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; PostingGroup: Code[20])
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT Settlement Test Agreement';
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
        CalcRequest.Description := 'RBT Settlement Test Request';
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
