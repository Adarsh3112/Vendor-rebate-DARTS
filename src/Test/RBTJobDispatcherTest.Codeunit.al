codeunit 50115 "RBT Job Dispatcher Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Test coverage for RBT Job Dispatcher (codeunit 50104).
    //
    // Every test builds an activated Vendor Rebate agreement, seeds a small
    // number of Purch. Inv. Lines that match the agreement window, forces the
    // dispatcher to use a tiny chunk size (via SetDefaultChunkSize) so many
    // chunks are produced from a small fixture, and then exercises one
    // dispatcher entry point per test:
    //   - PlanChunks produces the expected number of chunks.
    //   - ProcessAllChunks marks every chunk Completed and populates
    //     Calculation Ledger Entries idempotently.
    //   - A poisoned agreement (Status flipped to Draft after plan) fails
    //     every chunk with Error Message populated.
    //   - RetryFailedChunks flips Failed chunks back to Pending, increments
    //     Retry Count, and re-runs them to Completed after the root cause is
    //     resolved.
    //   - Re-running a Completed job is idempotent - no additional ledger
    //     entries are inserted.

    var
        UniqueSeq: Integer;
        NextPurchDocSuffix: Integer;

    local procedure AreEqual(Expected: Variant; Actual: Variant; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1. Expected: %2. Actual: %3.', Comment = '%1 = assertion message, %2 = expected value, %3 = actual value';
    begin
        if Format(Expected) <> Format(Actual) then
            Error(AssertionFailedErr, Msg, Format(Expected), Format(Actual));
    end;

    local procedure IsTrue(Condition: Boolean; Msg: Text)
    var
        AssertionFailedErr: Label 'Assertion failed: %1.', Comment = '%1 = assertion message';
    begin
        if not Condition then
            Error(AssertionFailedErr, Msg);
    end;

    local procedure Initialize()
    var
        RBTInstall: Codeunit "RBT Install";
    begin
        RBTInstall.InitializeSetup();
        NextPurchDocSuffix := 0;
    end;

    // ========================================================================
    // Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestPlanChunksProducesExpectedNumberOfChunks()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        JobChunk: Record "RBT Job Chunk";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VendorNo: Code[20];
        ItemNo: Code[20];
        i: Integer;
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5);
        for i := 1 to 5 do
            InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);

        Dispatcher.PlanChunks(CalcRequest, 2);

        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        AreEqual(3, JobChunk.Count(), 'PlanChunks(5 lines, size 2) should produce 3 chunks: 2+2+1.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestProcessAllChunksMarksEveryChunkCompleted()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        JobChunk: Record "RBT Job Chunk";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VendorNo: Code[20];
        ItemNo: Code[20];
        i: Integer;
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 10);
        for i := 1 to 3 do
            InsertPurchInvLineForItem(Agreement, ItemNo, 200, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);
        Dispatcher.PlanChunks(CalcRequest, 1);
        Dispatcher.ProcessAllChunks(CalcRequest);

        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetFilter(Status, '<>%1', JobChunk.Status::Completed);
        AreEqual(0, JobChunk.Count(), 'Every chunk should be Completed after ProcessAllChunks.');

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        AreEqual(3, LedgerEntry.Count(), 'Exactly one ledger entry per source line should be produced.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestFailedChunkLogsErrorMessage()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        JobChunk: Record "RBT Job Chunk";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FailedCount: Integer;
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5);
        InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());
        InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);
        Dispatcher.PlanChunks(CalcRequest, 1);

        // Poison the agreement: dropping every version row causes the Rule Engine
        // to raise NoCurrentVersionErr when it attempts to resolve the current version.
        PoisonAgreement(Agreement);

        Dispatcher.ProcessAllChunks(CalcRequest);

        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetRange(Status, JobChunk.Status::Failed);
        FailedCount := JobChunk.Count();
        IsTrue(FailedCount >= 1, 'A poisoned agreement should produce at least one Failed chunk.');

        if JobChunk.FindFirst() then
            IsTrue(JobChunk."Error Message" <> '', 'Failed chunk must carry a non-blank Error Message.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRetryFailedChunksFlipsChunksToPendingAndRerunsToCompleted()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        JobChunk: Record "RBT Job Chunk";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FailedBefore: Integer;
        CompletedAfter: Integer;
        AnyRetriedChunk: Record "RBT Job Chunk";
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5);
        InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());
        InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);
        Dispatcher.PlanChunks(CalcRequest, 1);

        PoisonAgreement(Agreement);
        Dispatcher.ProcessAllChunks(CalcRequest);

        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetRange(Status, JobChunk.Status::Failed);
        FailedBefore := JobChunk.Count();
        IsTrue(FailedBefore >= 1, 'Precondition: at least one Failed chunk is required for a retry test.');

        // Fix the root cause: rebuild the version snapshot so the Rule Engine can succeed.
        Agreement.Find();
        Agreement.Status := Agreement.Status::Draft;
        Agreement.Modify();
        VersionMgt.ActivateAgreement(Agreement);

        Dispatcher.RetryFailedChunks(CalcRequest);

        JobChunk.Reset();
        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetRange(Status, JobChunk.Status::Completed);
        CompletedAfter := JobChunk.Count();
        IsTrue(CompletedAfter >= FailedBefore, 'After retry, previously-failed chunks should be Completed.');

        // Retry Count must reflect at least one retry on the chunks that were retried.
        AnyRetriedChunk.SetRange("Calc Request No.", CalcRequest."No.");
        AnyRetriedChunk.SetFilter("Retry Count", '>%1', 0);
        IsTrue(not AnyRetriedChunk.IsEmpty(), 'At least one chunk should show a Retry Count > 0 after RetryFailedChunks.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRunningCompletedJobIsIdempotent()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        LedgerEntry: Record "RBT Calculation Ledger Entry";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VendorNo: Code[20];
        ItemNo: Code[20];
        LedgerCountFirstRun: Integer;
        LedgerCountSecondRun: Integer;
        i: Integer;
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5);
        for i := 1 to 4 do
            InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);
        Dispatcher.PlanChunks(CalcRequest, 2);
        Dispatcher.ProcessAllChunks(CalcRequest);

        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        LedgerCountFirstRun := LedgerEntry.Count();

        // Second invocation: no Pending or Failed chunks remain, so ProcessAllChunks
        // is a no-op. No additional ledger entries must be produced.
        Dispatcher.ProcessAllChunks(CalcRequest);

        LedgerEntry.Reset();
        LedgerEntry.SetRange("Agreement No.", Agreement."No.");
        LedgerCountSecondRun := LedgerEntry.Count();

        AreEqual(LedgerCountFirstRun, LedgerCountSecondRun, 'Re-running a completed job must not produce additional ledger entries.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCompletedChunkIsImmutable()
    var
        Agreement: Record "RBT Rebate Agreement";
        Rule: Record "RBT Rebate Rule";
        CalcRequest: Record "RBT Calc Request";
        JobChunk: Record "RBT Job Chunk";
        Dispatcher: Codeunit "RBT Job Dispatcher";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        Initialize();
        VendorNo := UniqueCode20('V');
        ItemNo := UniqueCode20('I');
        EnsureVendor(VendorNo);
        EnsureItem(ItemNo);

        CreateActiveVendorAgreement(Agreement, VendorNo, WorkDate() - 30, WorkDate() + 30);
        CreatePercentageRule(Rule, Agreement, 5);
        InsertPurchInvLineForItem(Agreement, ItemNo, 100, WorkDate());

        CreateCalcRequest(CalcRequest, Agreement);
        Dispatcher.PlanChunks(CalcRequest, 1);
        Dispatcher.ProcessAllChunks(CalcRequest);

        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetRange(Status, JobChunk.Status::Completed);
        JobChunk.FindFirst();

        // Direct modification (without SetAllowInternalEdit) must be rejected.
        JobChunk."Error Message" := 'tampered';
        asserterror JobChunk.Modify();
    end;

    // ========================================================================
    // Fixture helpers
    // ========================================================================

    local procedure UniqueCode20(Prefix: Text): Code[20]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq), 1, 20));
    end;

    local procedure EnsureVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit;
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Name := 'RBT JobDisp Test Vendor';
        Vendor.Insert();
    end;

    local procedure EnsureItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit;
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := 'RBT JobDisp Test Item';
        Item.Insert();
    end;

    local procedure CreateActiveVendorAgreement(var Agreement: Record "RBT Rebate Agreement"; VendorNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        VersionMgt: Codeunit "RBT Rebate Version Mgt.";
    begin
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := 'RBT JobDisp Test Agreement';
        Agreement."Type" := Agreement."Type"::"Vendor Rebate";
        Agreement."Vendor No." := VendorNo;
        Agreement."Start Date" := StartDate;
        Agreement."End Date" := EndDate;
        Agreement.Status := Agreement.Status::Draft;
        Agreement.Modify();
        VersionMgt.ActivateAgreement(Agreement);
        Agreement.Find();
    end;

    local procedure CreatePercentageRule(var Rule: Record "RBT Rebate Rule"; var Agreement: Record "RBT Rebate Agreement"; PercentageValue: Decimal)
    begin
        Rule.Init();
        Rule."Agreement No." := Agreement."No.";
        Rule."Line No." := 0;
        Rule.Insert(true);
        Rule.Basis := Rule.Basis::"Purchase Amount";
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule.Percentage := PercentageValue;
        Rule."Item No." := '';
        Rule."Item Category" := '';
        Rule."Location Code" := '';
        Rule.Modify();
    end;

    local procedure CreateCalcRequest(var CalcRequest: Record "RBT Calc Request"; var Agreement: Record "RBT Rebate Agreement")
    begin
        CalcRequest.Init();
        CalcRequest."No." := '';
        CalcRequest.Insert(true);
        CalcRequest.Description := 'RBT JobDisp Test Calc Request';
        CalcRequest.Validate("Agreement No.", Agreement."No.");
        CalcRequest."Period Start" := Agreement."Start Date";
        CalcRequest."Period End" := Agreement."End Date";
        CalcRequest."Posting Date" := WorkDate();
        CalcRequest.Modify();
    end;

    local procedure InsertPurchInvLineForItem(var Agreement: Record "RBT Rebate Agreement"; ItemNo: Code[20]; LineAmount: Decimal; PostingDate: Date)
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
        PurchInvLine.Insert();
    end;

    local procedure NextTestPurchDocNo(): Code[20]
    begin
        NextPurchDocSuffix += 1;
        exit(CopyStr('RBT-JD-' + Format(NextPurchDocSuffix), 1, 20));
    end;

    local procedure PoisonAgreement(var Agreement: Record "RBT Rebate Agreement")
    var
        Version: Record "RBT Rebate Version";
    begin
        // Flip "Is Current" to false on every version row. The Rule Engine's
        // GetCurrentVersion call then returns false and NoCurrentVersionErr is
        // raised as soon as the dispatcher processes any chunk, giving us a
        // deterministic Failed chunk without disturbing anything else. Version
        // deletes are unconditionally blocked, but Modify is allowed via the
        // internal-edit escape hatch.
        Version.SetRange("Agreement No.", Agreement."No.");
        if Version.FindSet() then
            repeat
                Version.SetAllowInternalEdit(true);
                Version."Is Current" := false;
                Version.Modify();
                Version.SetAllowInternalEdit(false);
            until Version.Next() = 0;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Swallow status/progress messages emitted by the dispatcher and the version manager.
    end;
}
