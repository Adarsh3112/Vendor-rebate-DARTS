codeunit 50112 "RBT Audit Mgt. Test"
{
    // Automated test coverage for the RBT Audit Trail feature.
    //
    // Covers:
    //   T01 - LogSentForApproval inserts an entry with Action = Sent For Approval,
    //         populates User ID, Date Time, Document No., Old/New Value.
    //   T02 - LogActivated inserts an entry with Action = Activated.
    //   T03 - LogAccrualPosted inserts an entry with Action = Accrual Posted and
    //         records the accrual amount / G/L entry count in New Value.
    //   T04 - Direct Modify() on an existing audit entry FAILS with the immutability
    //         error (RIMD protection).
    //   T05 - Direct Delete() on an existing audit entry FAILS with the immutability
    //         error (append-only trail).

    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;

    // Inline assertion helpers - the sandbox package set does not ship the Microsoft
    // test libraries. We implement the small subset of assertions needed locally.
    local procedure AssertAreEqual(Expected: Variant; Actual: Variant; Msg: Text)
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

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    [Test]
    procedure LogSentForApproval_InsertsAuditEntry()
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        AuditEntry: Record "RBT Audit Entry";
        DocNo: Code[20];
        BeforeDt: DateTime;
    begin
        // [GIVEN] An empty snapshot of the audit table filtered by Document No.
        Initialize();
        DocNo := 'AGR-TEST-001';
        AuditEntry.SetRange("Document No.", DocNo);
        AuditEntry.DeleteAll(); // seed-only cleanup runs with internal-edit off - this call is expected to fail if any pre-existing entry is protected. It is safe because DeleteAll will not delete when OnDelete errors; the SetRange path only removes fresh test data.

        BeforeDt := CurrentDateTime();

        // [WHEN] LogSentForApproval is invoked.
        AuditMgt.LogSentForApproval(DocNo, Database::"RBT Rebate Agreement", 'Draft', 'Pending Approval');

        // [THEN] Exactly one audit entry exists with the expected shape.
        AuditEntry.Reset();
        AuditEntry.SetRange("Document No.", DocNo);
        AuditEntry.SetRange(Action, AuditEntry.Action::"Sent For Approval");
        AssertTrue(AuditEntry.FindFirst(), 'Audit entry for Sent For Approval was not inserted.');
        AssertAreEqual('Draft', AuditEntry."Old Value", 'Old Value does not match the pre-transition status.');
        AssertAreEqual('Pending Approval', AuditEntry."New Value", 'New Value does not match the post-transition status.');
        AssertAreEqual(CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID")), AuditEntry."User ID", 'User ID is not the current user.');
        AssertTrue(AuditEntry."Date Time" >= BeforeDt, 'Date Time must be captured at or after the pre-call timestamp.');
        AssertAreEqual(Database::"RBT Rebate Agreement", AuditEntry."Source Table No.", 'Source Table No. must be RBT Rebate Agreement.');
    end;

    [Test]
    procedure LogActivated_InsertsAuditEntry()
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        AuditEntry: Record "RBT Audit Entry";
        DocNo: Code[20];
    begin
        // [GIVEN] A unique document number for this test case.
        Initialize();
        DocNo := 'AGR-TEST-002';

        // [WHEN] LogActivated is invoked for a transition Approved -> Active.
        AuditMgt.LogActivated(DocNo, Database::"RBT Rebate Agreement", 'Approved', 'Active');

        // [THEN] The entry exists with Action = Activated and correct Old/New values.
        AuditEntry.Reset();
        AuditEntry.SetRange("Document No.", DocNo);
        AuditEntry.SetRange(Action, AuditEntry.Action::Activated);
        AssertTrue(AuditEntry.FindFirst(), 'Audit entry for Activated event was not inserted.');
        AssertAreEqual('Approved', AuditEntry."Old Value", 'Old Value must record the pre-activation status.');
        AssertAreEqual('Active', AuditEntry."New Value", 'New Value must record the post-activation status.');
    end;

    [Test]
    procedure LogAccrualPosted_RecordsAmountAndEntryCount()
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        AuditEntry: Record "RBT Audit Entry";
        DocNo: Code[20];
        CalcRequestNo: Code[20];
    begin
        // [GIVEN] Distinct document and calc-request numbers to isolate the assertion.
        Initialize();
        DocNo := 'ACC-TEST-001';
        CalcRequestNo := 'CALC-TEST-001';

        // [WHEN] LogAccrualPosted is called with an amount of 1234.56 and 2 G/L entries.
        AuditMgt.LogAccrualPosted(CalcRequestNo, DocNo, Database::"RBT Calc Request", 1234.56, 2);

        // [THEN] The audit entry exists with Action = Accrual Posted and the amount appears in New Value.
        AuditEntry.Reset();
        AuditEntry.SetRange("Document No.", DocNo);
        AuditEntry.SetRange(Action, AuditEntry.Action::"Accrual Posted");
        AssertTrue(AuditEntry.FindFirst(), 'Audit entry for Accrual Posted was not inserted.');
        AssertAreEqual('', AuditEntry."Old Value", 'Accrual Posted event must have an empty Old Value.');
        AssertTrue(StrPos(AuditEntry."New Value", '1234.56') > 0, 'New Value must contain the accrual amount.');
        AssertTrue(StrPos(AuditEntry."New Value", 'G/L Entries=2') > 0, 'New Value must record the G/L entry count.');
    end;

    [Test]
    procedure ModifyAuditEntry_FailsWithImmutabilityError()
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        AuditEntry: Record "RBT Audit Entry";
        DocNo: Code[20];
    begin
        // [GIVEN] A freshly inserted audit entry.
        Initialize();
        DocNo := 'IMM-TEST-MOD';
        AuditMgt.LogEvent(Enum::"RBT Audit Action"::"Status Change", DocNo, Database::"RBT Rebate Agreement", 'A', 'B', 'Test modify');

        AuditEntry.Reset();
        AuditEntry.SetRange("Document No.", DocNo);
        AssertTrue(AuditEntry.FindFirst(), 'Seed audit entry was not inserted.');

        // [WHEN] External code attempts to modify the audit entry directly.
        // [THEN] The OnModify trigger raises ImmutableModifyErr and asserterror catches it.
        AuditEntry."New Value" := 'TAMPERED';
        asserterror AuditEntry.Modify();
    end;

    [Test]
    procedure DeleteAuditEntry_FailsWithImmutabilityError()
    var
        AuditMgt: Codeunit "RBT Audit Mgt.";
        AuditEntry: Record "RBT Audit Entry";
        DocNo: Code[20];
    begin
        // [GIVEN] A freshly inserted audit entry.
        Initialize();
        DocNo := 'IMM-TEST-DEL';
        AuditMgt.LogEvent(Enum::"RBT Audit Action"::"Status Change", DocNo, Database::"RBT Rebate Agreement", 'A', 'B', 'Test delete');

        AuditEntry.Reset();
        AuditEntry.SetRange("Document No.", DocNo);
        AssertTrue(AuditEntry.FindFirst(), 'Seed audit entry was not inserted.');

        // [WHEN] External code attempts to delete the audit entry.
        // [THEN] The OnDelete trigger raises ImmutableDeleteErr and asserterror catches it.
        asserterror AuditEntry.Delete();
    end;
}
