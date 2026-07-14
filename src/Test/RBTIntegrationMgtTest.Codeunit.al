codeunit 50117 "RBT Integration Mgt. Test"
{
    // Test coverage for RBT Integration Mgt. (codeunit 50116) and the RBT Integration
    // Staging table (50108). BC's test runner rolls back the transaction after each
    // test, so each procedure creates and asserts against its own data.

    Subtype = Test;
    TestPermissions = Disabled;

    var
        UniqueSeq: Integer;

    // --------- Inline assertion helpers ---------

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

    local procedure AssertFalse(Condition: Boolean; Msg: Text)
    begin
        AssertTrue(not Condition, Msg);
    end;

    // --------- [Test] procedures ---------

    [Test]
    procedure TestIngestInsertsNewRow()
    var
        Staging: Record "RBT Integration Staging";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        ExternalId: Code[50];
        PayloadText: Text;
        Inserted: Boolean;
    begin
        Initialize();
        ExternalId := UniqueCode50('EXT');
        PayloadText := SampleVendorRebatePayload();

        Inserted := IntegrationMgt.Ingest('SHOPIFY', ExternalId, PayloadText, Staging);

        AssertTrue(Inserted, 'First Ingest for a new (SourceSystem, ExternalID) must return TRUE.');
        AreEqual(Staging.Status::New, Staging.Status, 'New row must be in Status = New.');
        AssertTrue(Staging."Created At" <> 0DT, 'Created At must be stamped on insert.');
        AreEqual('SHOPIFY', Staging."Source System", 'Source System must be persisted.');
        AreEqual(ExternalId, Staging."External ID", 'External ID must be persisted.');
        AreEqual(PayloadText, Staging.GetPayload(), 'Payload text must round-trip through the Blob.');

        AreEqual(1, CountStagingRowsFor('SHOPIFY', ExternalId), 'Exactly one row must exist after a single Ingest.');
    end;

    [Test]
    procedure TestIngestDuplicateExternalIdReturnsExistingRowSilently()
    var
        First: Record "RBT Integration Staging";
        Second: Record "RBT Integration Staging";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        ExternalId: Code[50];
        InsertedFirst: Boolean;
        InsertedSecond: Boolean;
    begin
        Initialize();
        ExternalId := UniqueCode50('EXT');

        InsertedFirst := IntegrationMgt.Ingest('SHOPIFY', ExternalId, SampleVendorRebatePayload(), First);
        AssertTrue(InsertedFirst, 'First Ingest must return TRUE.');

        InsertedSecond := IntegrationMgt.Ingest('SHOPIFY', ExternalId, SampleVendorRebatePayload(), Second);

        AssertFalse(InsertedSecond, 'Second Ingest with the same (SourceSystem, ExternalID) must return FALSE.');
        AreEqual(First."Entry No.", Second."Entry No.", 'Second Ingest must load the existing row.');
        AreEqual(1, CountStagingRowsFor('SHOPIFY', ExternalId), 'No duplicate row must be created.');
    end;

    [Test]
    procedure TestPromoteCreatesRebateAgreement()
    var
        Staging: Record "RBT Integration Staging";
        Agreement: Record "RBT Rebate Agreement";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        AgreementCountBefore: Integer;
        Promoted: Boolean;
    begin
        Initialize();
        AgreementCountBefore := Agreement.Count();

        IntegrationMgt.Ingest('SHOPIFY', UniqueCode50('EXT'), SampleVendorRebatePayload(), Staging);

        Promoted := IntegrationMgt.Promote(Staging);

        AssertTrue(Promoted, 'Promote of a New row with a valid payload must return TRUE.');
        AreEqual(Staging.Status::Processed, Staging.Status, 'Status must be Processed after successful Promote.');
        AssertTrue(Staging."Processed At" <> 0DT, 'Processed At must be stamped after successful Promote.');
        AssertTrue(Staging."Promoted To Agreement No." <> '', 'Promoted To Agreement No. must be populated.');

        AssertTrue(Agreement.Get(Staging."Promoted To Agreement No."),
            'A matching RBT Rebate Agreement must exist for the promoted row.');
        AreEqual(Agreement."Type"::"Vendor Rebate", Agreement."Type",
            'Agreement Type must be Vendor Rebate as supplied by the payload.');
        AreEqual(AgreementCountBefore + 1, Agreement.Count(),
            'Exactly one new Rebate Agreement must be created.');
    end;

    [Test]
    procedure TestPromoteWithInvalidPayloadFlagsErrorAndCreatesNoAgreement()
    var
        Staging: Record "RBT Integration Staging";
        Agreement: Record "RBT Rebate Agreement";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        AgreementCountBefore: Integer;
        Promoted: Boolean;
    begin
        Initialize();
        AgreementCountBefore := Agreement.Count();

        // Payload is missing the mandatory 'type' key.
        IntegrationMgt.Ingest('SHOPIFY', UniqueCode50('EXT'),
            '{"description":"malformed","vendorNo":"V001"}', Staging);

        Promoted := IntegrationMgt.Promote(Staging);

        AssertFalse(Promoted, 'Promote on a malformed payload must return FALSE.');
        Staging.Get(Staging."Entry No.");
        AreEqual(Staging.Status::Error, Staging.Status, 'Status must be Error after a failed Promote.');
        AssertTrue(Staging."Error Message" <> '', 'Error Message must be populated on failure.');
        AreEqual('', Staging."Promoted To Agreement No.", 'Promoted To Agreement No. must remain blank on failure.');
        AreEqual(AgreementCountBefore, Agreement.Count(),
            'No RBT Rebate Agreement must be created when promotion fails.');
    end;

    [Test]
    procedure TestPromoteAlreadyProcessedRowIsNoOp()
    var
        Staging: Record "RBT Integration Staging";
        Agreement: Record "RBT Rebate Agreement";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        FirstAgreementNo: Code[20];
        AgreementCountAfterFirst: Integer;
        SecondPromoted: Boolean;
    begin
        Initialize();
        IntegrationMgt.Ingest('SHOPIFY', UniqueCode50('EXT'), SampleVendorRebatePayload(), Staging);

        AssertTrue(IntegrationMgt.Promote(Staging), 'First Promote must succeed.');
        FirstAgreementNo := Staging."Promoted To Agreement No.";
        AgreementCountAfterFirst := Agreement.Count();

        // Second call must not create a second agreement.
        Staging.Get(Staging."Entry No.");
        SecondPromoted := IntegrationMgt.Promote(Staging);

        AssertFalse(SecondPromoted, 'Promote on an already-Processed row must return FALSE.');
        AreEqual(AgreementCountAfterFirst, Agreement.Count(),
            'A second Promote must not create a duplicate Rebate Agreement.');
        Staging.Get(Staging."Entry No.");
        AreEqual(FirstAgreementNo, Staging."Promoted To Agreement No.",
            'Promoted To Agreement No. must remain unchanged on a no-op Promote.');
    end;

    [Test]
    procedure TestReprocessResetsStatusAndPromotesAgain()
    var
        Staging: Record "RBT Integration Staging";
        Agreement: Record "RBT Rebate Agreement";
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        AgreementCountBefore: Integer;
    begin
        Initialize();
        AgreementCountBefore := Agreement.Count();

        // Ingest a malformed payload so Promote fails and Status flips to Error.
        IntegrationMgt.Ingest('SHOPIFY', UniqueCode50('EXT'),
            '{"description":"first try malformed"}', Staging);
        IntegrationMgt.Promote(Staging);
        Staging.Get(Staging."Entry No.");
        AreEqual(Staging.Status::Error, Staging.Status, 'Precondition: Status must be Error after malformed Promote.');

        // Rewrite the payload with a valid body (using the internal-edit escape hatch)
        // and Reprocess.
        Staging.SetAllowInternalEdit(true);
        Staging.SetPayload(SampleVendorRebatePayload());
        Staging.Modify();
        Staging.SetAllowInternalEdit(false);

        IntegrationMgt.Reprocess(Staging);

        Staging.Get(Staging."Entry No.");
        AreEqual(Staging.Status::Processed, Staging.Status,
            'Reprocess with a valid payload must advance Status from Error to Processed.');
        AssertTrue(Staging."Promoted To Agreement No." <> '',
            'Reprocess must populate Promoted To Agreement No. on success.');
        AreEqual(AgreementCountBefore + 1, Agreement.Count(),
            'Reprocess must create exactly one RBT Rebate Agreement.');
    end;

    // --------- Fixture helpers ---------

    local procedure Initialize()
    var
        RBTInstall: Codeunit "RBT Install";
    begin
        RBTInstall.InitializeSetup();
        UniqueSeq += 1;
    end;

    local procedure SampleVendorRebatePayload(): Text
    begin
        exit('{"description":"Integration Test Agreement","type":"VendorRebate","vendorNo":"","customerNo":"","startDate":"2025-01-01","endDate":"2025-12-31","currencyCode":"","postingGroup":"DEFAULT"}');
    end;

    local procedure UniqueCode50(Prefix: Text): Code[50]
    begin
        UniqueSeq += 1;
        exit(CopyStr('RBT-' + Prefix + '-' + Format(UniqueSeq) + '-' + Format(CurrentDateTime(), 0, '<Hours24><Minutes,2><Seconds,2>'), 1, 50));
    end;

    local procedure CountStagingRowsFor(SourceSystem: Code[20]; ExternalId: Code[50]): Integer
    var
        Staging: Record "RBT Integration Staging";
    begin
        Staging.Reset();
        Staging.SetRange("Source System", SourceSystem);
        Staging.SetRange("External ID", ExternalId);
        exit(Staging.Count());
    end;
}
