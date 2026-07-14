codeunit 50111 "RBT Audit Mgt."
{
    // Centralized write API for the RBT Audit Entry immutable trail.
    //
    // Business rule: the trail is triggered by
    //   (a) Agreement Status changes  -> LogStatusChange
    //   (b) Financial posting events  -> LogAccrualPosted / LogSettlementPosted
    //   (c) Any other business-critical event -> LogEvent (generic fallback)
    //
    // Every insert flows through InsertAudit(), which toggles the immutable table's
    // internal-edit escape hatch around the Insert() call and then turns it off.
    // The Entry No. field is AutoIncrement so no explicit numbering is needed.

    Access = Public;

    /// <summary>
    /// Records a status change on a rebate agreement or any other document.
    /// Old/new value are formatted enum labels or codes and truncated to 250 chars.
    /// </summary>
    procedure LogStatusChange(DocumentNo: Code[20]; SourceTableId: Integer; OldValue: Text; NewValue: Text; Description: Text)
    begin
        InsertAudit(Enum::"RBT Audit Action"::"Status Change", DocumentNo, SourceTableId, OldValue, NewValue, Description);
    end;

    /// <summary>
    /// Records the "Sent For Approval" event on a rebate agreement.
    /// </summary>
    procedure LogSentForApproval(DocumentNo: Code[20]; SourceTableId: Integer; OldStatus: Text; NewStatus: Text)
    var
        DescLbl: Label 'Rebate Agreement %1 sent for approval.', Comment = '%1 = Agreement No.';
    begin
        InsertAudit(Enum::"RBT Audit Action"::"Sent For Approval", DocumentNo, SourceTableId, OldStatus, NewStatus, StrSubstNo(DescLbl, DocumentNo));
    end;

    /// <summary>
    /// Records cancellation of an approval request.
    /// </summary>
    procedure LogApprovalCancelled(DocumentNo: Code[20]; SourceTableId: Integer; OldStatus: Text; NewStatus: Text)
    var
        DescLbl: Label 'Approval request cancelled on Rebate Agreement %1.', Comment = '%1 = Agreement No.';
    begin
        InsertAudit(Enum::"RBT Audit Action"::"Approval Cancelled", DocumentNo, SourceTableId, OldStatus, NewStatus, StrSubstNo(DescLbl, DocumentNo));
    end;

    /// <summary>
    /// Records an approval decision (Pending Approval -> Approved).
    /// </summary>
    procedure LogApproved(DocumentNo: Code[20]; SourceTableId: Integer; OldStatus: Text; NewStatus: Text)
    var
        DescLbl: Label 'Rebate Agreement %1 approved.', Comment = '%1 = Agreement No.';
    begin
        InsertAudit(Enum::"RBT Audit Action"::Approved, DocumentNo, SourceTableId, OldStatus, NewStatus, StrSubstNo(DescLbl, DocumentNo));
    end;

    /// <summary>
    /// Records activation (Approved/Draft -> Active) - creates the Version 1 snapshot.
    /// </summary>
    procedure LogActivated(DocumentNo: Code[20]; SourceTableId: Integer; OldStatus: Text; NewStatus: Text)
    var
        DescLbl: Label 'Rebate Agreement %1 activated. Version 1 created.', Comment = '%1 = Agreement No.';
    begin
        InsertAudit(Enum::"RBT Audit Action"::Activated, DocumentNo, SourceTableId, OldStatus, NewStatus, StrSubstNo(DescLbl, DocumentNo));
    end;

    /// <summary>
    /// Records a posted accrual event. New Value carries the accrual amount and G/L entry count.
    /// </summary>
    procedure LogAccrualPosted(CalcRequestNo: Code[20]; DocumentNo: Code[20]; SourceTableId: Integer; AccrualAmount: Decimal; GLEntryCount: Integer)
    var
        NewValueLbl: Label 'Amount=%1; G/L Entries=%2', Locked = true;
        DescLbl: Label 'Accrual posted for Calc Request %1 (Document %2).', Comment = '%1 = Calc Request No., %2 = Document No.';
        NewValueTxt: Text;
    begin
        NewValueTxt := StrSubstNo(NewValueLbl, Format(AccrualAmount, 0, 9), GLEntryCount);
        InsertAudit(Enum::"RBT Audit Action"::"Accrual Posted", DocumentNo, SourceTableId, '', NewValueTxt, StrSubstNo(DescLbl, CalcRequestNo, DocumentNo));
    end;

    /// <summary>
    /// Records a posted settlement event. Used by the settlement engine.
    /// </summary>
    procedure LogSettlementPosted(SettlementNo: Code[20]; DocumentNo: Code[20]; SourceTableId: Integer; SettlementAmount: Decimal)
    var
        NewValueLbl: Label 'Amount=%1', Locked = true;
        DescLbl: Label 'Settlement %1 posted (Document %2).', Comment = '%1 = Settlement No., %2 = Document No.';
    begin
        InsertAudit(Enum::"RBT Audit Action"::"Settlement Posted", DocumentNo, SourceTableId, '', StrSubstNo(NewValueLbl, Format(SettlementAmount, 0, 9)), StrSubstNo(DescLbl, SettlementNo, DocumentNo));
    end;

    /// <summary>
    /// Generic event logger for actions that do not fit the specialised procedures.
    /// </summary>
    procedure LogEvent(Action: Enum "RBT Audit Action"; DocumentNo: Code[20]; SourceTableId: Integer; OldValue: Text; NewValue: Text; Description: Text)
    begin
        InsertAudit(Action, DocumentNo, SourceTableId, OldValue, NewValue, Description);
    end;

    local procedure InsertAudit(Action: Enum "RBT Audit Action"; DocumentNo: Code[20]; SourceTableId: Integer; OldValue: Text; NewValue: Text; Description: Text)
    var
        AuditEntry: Record "RBT Audit Entry";
    begin
        // The audit table's AllowInternalEdit escape hatch is left OFF for the Insert path -
        // OnInsert() is not blocked, only OnModify/OnDelete are. This means external code
        // cannot Modify() the record after our Insert() completes.
        AuditEntry.Init();
        AuditEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID"));
        AuditEntry."Date Time" := CurrentDateTime();
        AuditEntry.Action := Action;
        AuditEntry."Document No." := DocumentNo;
        AuditEntry."Source Table No." := SourceTableId;
        AuditEntry."Old Value" := CopyStr(OldValue, 1, MaxStrLen(AuditEntry."Old Value"));
        AuditEntry."New Value" := CopyStr(NewValue, 1, MaxStrLen(AuditEntry."New Value"));
        AuditEntry.Description := CopyStr(Description, 1, MaxStrLen(AuditEntry.Description));
        AuditEntry.Insert(false);
    end;
}
