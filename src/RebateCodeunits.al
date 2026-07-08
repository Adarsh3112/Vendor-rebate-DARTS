codeunit 50100 "Rebate Audit Mgt."
{
    procedure Log(Action: Text[100]; TableId: Integer; RecordIdText: Text[250]; OldValue: Text[250]; NewValue: Text[250]; ReasonCode: Code[20])
    var
        AuditEntry: Record "Rebate Audit Entry";
    begin
        AuditEntry.Init();
        AuditEntry."Created DateTime" := CurrentDateTime();
        AuditEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID"));
        AuditEntry.Action := Action;
        AuditEntry."Table ID" := TableId;
        AuditEntry."Record ID Text" := RecordIdText;
        AuditEntry."Old Value" := OldValue;
        AuditEntry."New Value" := NewValue;
        AuditEntry."Reason Code" := ReasonCode;
        AuditEntry.Insert(true);
    end;
}

codeunit 50101 "Rebate Agreement Mgt."
{
    procedure Submit(var Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.TestField(Status, Agreement.Status::Draft);
        ValidateAgreement(Agreement);
        Agreement.Status := Agreement.Status::Submitted;
        Agreement.Modify(true);
        Audit('Agreement Submitted', Agreement, '', Format(Agreement.Status));
    end;

    procedure Approve(var Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.TestField(Status, Agreement.Status::Submitted);
        Agreement.Status := Agreement.Status::Approved;
        Agreement.Modify(true);
        Audit('Agreement Approved', Agreement, '', Format(Agreement.Status));
    end;

    procedure Reject(var Agreement: Record "Rebate Agreement Header"; ReasonCode: Code[20])
    begin
        Agreement.Status := Agreement.Status::Rejected;
        Agreement.Modify(true);
        Audit('Agreement Rejected', Agreement, '', Format(Agreement.Status), ReasonCode);
    end;

    procedure Activate(var Agreement: Record "Rebate Agreement Header")
    var
        PostingSetup: Record "Rebate Posting Setup";
        Version: Record "Rebate Agreement Version";
        RuleValidator: Codeunit "Rebate Rule Validator";
        NextVersion: Integer;
    begin
        Agreement.TestField(Status, Agreement.Status::Approved);
        ValidateAgreement(Agreement);
        PostingSetup.Get(Agreement."Agreement Type", Agreement."Posting Group", Agreement."Currency Code", PostingSetup."Entry Type"::Accrual);
        PostingSetup.TestField("Expense Account No.");
        PostingSetup.TestField("Liability Account No.");
        RuleValidator.ValidateAgreementRules(Agreement."No.");

        Version.SetRange("Agreement No.", Agreement."No.");
        if Version.FindLast() then
            NextVersion := Version."Version No." + 1
        else
            NextVersion := 1;

        Version.Init();
        Version."Agreement No." := Agreement."No.";
        Version."Version No." := NextVersion;
        Version."Agreement Type" := Agreement."Agreement Type";
        Version."Vendor No." := Agreement."Vendor No.";
        Version."Customer No." := Agreement."Customer No.";
        Version."Starting Date" := Agreement."Starting Date";
        Version."Ending Date" := Agreement."Ending Date";
        Version."Currency Code" := Agreement."Currency Code";
        Version."Posting Group" := Agreement."Posting Group";
        Version."Created DateTime" := CurrentDateTime();
        Version."Created By" := CopyStr(UserId(), 1, MaxStrLen(Version."Created By"));
        Version."Source Status" := Agreement.Status;
        Version.Insert(true);

        Agreement."Active Version No." := NextVersion;
        Agreement.Status := Agreement.Status::Active;
        Agreement.Modify(true);
        Audit('Agreement Activated', Agreement, '', Format(NextVersion));
    end;

    procedure Suspend(var Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.TestField(Status, Agreement.Status::Active);
        Agreement.Status := Agreement.Status::Suspended;
        Agreement.Modify(true);
        Audit('Agreement Suspended', Agreement, '', Format(Agreement.Status));
    end;

    procedure Expire(var Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.Status := Agreement.Status::Expired;
        Agreement.Modify(true);
        Audit('Agreement Expired', Agreement, '', Format(Agreement.Status));
    end;

    procedure CreateRevision(var Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.TestField(Status, Agreement.Status::Active);
        Agreement.Status := Agreement.Status::Revision;
        Agreement.Modify(true);
        Audit('Agreement Revision Created', Agreement, '', Format(Agreement.Status));
    end;

    procedure ValidateAgreement(Agreement: Record "Rebate Agreement Header")
    begin
        Agreement.TestField("Starting Date");
        Agreement.TestField("Ending Date");
        Agreement.TestField("Posting Group");
        if Agreement."Ending Date" < Agreement."Starting Date" then
            Error('Ending Date must not be before Starting Date.');
        case Agreement."Agreement Type" of
            Agreement."Agreement Type"::"Vendor Rebate":
                Agreement.TestField("Vendor No.");
            Agreement."Agreement Type"::"Customer Incentive":
                Agreement.TestField("Customer No.");
        end;
    end;

    local procedure Audit(Action: Text[100]; Agreement: Record "Rebate Agreement Header"; OldValue: Text; NewValue: Text)
    begin
        Audit(Action, Agreement, OldValue, NewValue, '');
    end;

    local procedure Audit(Action: Text[100]; Agreement: Record "Rebate Agreement Header"; OldValue: Text; NewValue: Text; ReasonCode: Code[20])
    var
        AuditMgt: Codeunit "Rebate Audit Mgt.";
    begin
        AuditMgt.Log(Action, Database::"Rebate Agreement Header", Agreement."No.", CopyStr(OldValue, 1, 250), CopyStr(NewValue, 1, 250), ReasonCode);
    end;
}

codeunit 50102 "Rebate Rule Validator"
{
    procedure ValidateAgreementRules(AgreementNo: Code[20])
    var
        Rule: Record "Rebate Rule";
        OtherRule: Record "Rebate Rule";
        FoundRule: Boolean;
    begin
        Rule.SetRange("Agreement No.", AgreementNo);
        if Rule.FindSet() then
            repeat
                FoundRule := true;
                Rule.TestField(Basis);
                Rule.TestField("Calculation Method");
                if Rule."Calculation Method" = Rule."Calculation Method"::Percentage then
                    if Rule."Percent" = 0 then
                        Error('Rule %1 must have a percent.', Rule."Rule No.");
                if (Rule."Ending Date" <> 0D) and (Rule."Starting Date" <> 0D) and (Rule."Ending Date" < Rule."Starting Date") then
                    Error('Rule %1 has invalid dates.', Rule."Rule No.");
                OtherRule.SetRange("Agreement No.", AgreementNo);
                OtherRule.SetRange(Priority, Rule.Priority);
                OtherRule.SetFilter("Rule No.", '<>%1', Rule."Rule No.");
                if OtherRule.FindFirst() then
                    Error('Rules %1 and %2 have conflicting priority.', Rule."Rule No.", OtherRule."Rule No.");
            until Rule.Next() = 0;
        if not FoundRule then
            Error('Agreement %1 must have at least one rebate rule.', AgreementNo);
    end;
}

codeunit 50103 "Rebate Calculation Engine"
{
    procedure RunRequest(var Request: Record "Rebate Calculation Request")
    var
        Agreement: Record "Rebate Agreement Header";
        JobDispatcher: Codeunit "Rebate Job Dispatcher";
    begin
        Request.TestField("Agreement No.");
        Agreement.Get(Request."Agreement No.");
        Agreement.TestField(Status, Agreement.Status::Active);
        Request.Status := Request.Status::"In Process";
        Request.Modify(true);
        JobDispatcher.LogChunk(Request."No.", 1, Request.Status::"In Process", '', 0, 0, false, '');

        case Agreement."Agreement Type" of
            Agreement."Agreement Type"::"Vendor Rebate":
                ProcessPurchaseInvoiceLines(Request, Agreement);
            Agreement."Agreement Type"::"Customer Incentive":
                ProcessSalesInvoiceLines(Request, Agreement);
        end;

        Request.Status := Request.Status::Completed;
        Request."Completed DateTime" := CurrentDateTime();
        Request.Modify(true);
        JobDispatcher.LogChunk(Request."No.", 1, Request.Status::Completed, Request."Last Source Key", Request."Processed Count", Request."Failed Count", false, '');
    end;

    procedure ProcessPurchaseInvoiceLines(var Request: Record "Rebate Calculation Request"; Agreement: Record "Rebate Agreement Header")
    var
        PurchLine: Record "Purch. Inv. Line";
    begin
        PurchLine.SetRange("Buy-from Vendor No.", Agreement."Vendor No.");
        PurchLine.SetRange("Posting Date", Request."Starting Date", Request."Ending Date");
        PurchLine.SetLoadFields("Document No.", "Line No.", Type, "No.", "Buy-from Vendor No.", "Posting Date", Amount, Quantity, "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if PurchLine.FindSet() then
            repeat
                EvaluatePurchaseLine(Request, Agreement, PurchLine);
            until PurchLine.Next() = 0;
    end;

    procedure ProcessSalesInvoiceLines(var Request: Record "Rebate Calculation Request"; Agreement: Record "Rebate Agreement Header")
    var
        SalesLine: Record "Sales Invoice Line";
    begin
        SalesLine.SetRange("Sell-to Customer No.", Agreement."Customer No.");
        SalesLine.SetRange("Posting Date", Request."Starting Date", Request."Ending Date");
        SalesLine.SetLoadFields("Document No.", "Line No.", Type, "No.", "Sell-to Customer No.", "Posting Date", Amount, Quantity, "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesLine.FindSet() then
            repeat
                EvaluateSalesLine(Request, Agreement, SalesLine);
            until SalesLine.Next() = 0;
    end;

    local procedure EvaluatePurchaseLine(var Request: Record "Rebate Calculation Request"; Agreement: Record "Rebate Agreement Header"; PurchLine: Record "Purch. Inv. Line")
    var
        Entry: Record "Rebate Calculation Entry";
        Rule: Record "Rebate Rule";
        SourceKey: Text[250];
        RebateAmount: Decimal;
    begin
        SourceKey := CopyStr(StrSubstNo('P|%1|%2', PurchLine."Document No.", PurchLine."Line No."), 1, 250);
        Rule.SetRange("Agreement No.", Agreement."No.");
        Rule.SetCurrentKey("Agreement No.", Priority);
        if Rule.FindSet() then
            repeat
                if not Request."Recalculation Mode" then begin
                    Entry.SetRange("Source Key", SourceKey);
                    Entry.SetRange("Agreement No.", Agreement."No.");
                    Entry.SetRange("Rule No.", Rule."Rule No.");
                    if Entry.FindFirst() then
                        exit;
                end;
                RebateAmount := CalculateAmount(Rule, PurchLine.Amount, PurchLine.Quantity);
                InsertCalcEntry(Request, Agreement, Rule, Entry."Source Type"::"Purch. Inv. Line", PurchLine."Document No.", PurchLine."Line No.", SourceKey, true, '', PurchLine.Amount, PurchLine.Quantity, RebateAmount, Agreement."Currency Code", PurchLine."Posting Date", PurchLine."Dimension Set ID", PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");
                Request."Processed Count" += 1;
                Request."Last Source Key" := SourceKey;
            until Rule.Next() = 0
        else begin
            InsertCalcEntry(Request, Agreement, Rule, Entry."Source Type"::"Purch. Inv. Line", PurchLine."Document No.", PurchLine."Line No.", SourceKey, false, 'No active rule matched.', PurchLine.Amount, PurchLine.Quantity, 0, Agreement."Currency Code", PurchLine."Posting Date", PurchLine."Dimension Set ID", PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");
            Request."Failed Count" += 1;
        end;
        Request.Modify(true);
    end;

    local procedure EvaluateSalesLine(var Request: Record "Rebate Calculation Request"; Agreement: Record "Rebate Agreement Header"; SalesLine: Record "Sales Invoice Line")
    var
        Entry: Record "Rebate Calculation Entry";
        Rule: Record "Rebate Rule";
        SourceKey: Text[250];
        RebateAmount: Decimal;
    begin
        SourceKey := CopyStr(StrSubstNo('S|%1|%2', SalesLine."Document No.", SalesLine."Line No."), 1, 250);
        Rule.SetRange("Agreement No.", Agreement."No.");
        Rule.SetCurrentKey("Agreement No.", Priority);
        if Rule.FindSet() then
            repeat
                RebateAmount := CalculateAmount(Rule, SalesLine.Amount, SalesLine.Quantity);
                InsertCalcEntry(Request, Agreement, Rule, Entry."Source Type"::"Sales Inv. Line", SalesLine."Document No.", SalesLine."Line No.", SourceKey, true, '', SalesLine.Amount, SalesLine.Quantity, RebateAmount, Agreement."Currency Code", SalesLine."Posting Date", SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
                Request."Processed Count" += 1;
                Request."Last Source Key" := SourceKey;
            until Rule.Next() = 0;
        Request.Modify(true);
    end;

    procedure CalculateAmount(Rule: Record "Rebate Rule"; SourceAmount: Decimal; Quantity: Decimal): Decimal
    var
        Threshold: Record "Rebate Threshold";
    begin
        OnBeforeCalculateAmount(Rule, SourceAmount, Quantity);
        case Rule."Calculation Method" of
            Rule."Calculation Method"::Percentage:
                exit(Round(SourceAmount * Rule."Percent" / 100, 0.01));
            Rule."Calculation Method"::"Fixed Amount":
                exit(Rule."Fixed Amount");
            Rule."Calculation Method"::"Tiered Percentage":
                begin
                    Threshold.SetRange("Agreement No.", Rule."Agreement No.");
                    Threshold.SetRange("Rule No.", Rule."Rule No.");
                    Threshold.SetFilter("Minimum Value", '<=%1', SourceAmount);
                    Threshold.SetFilter("Maximum Value", '>=%1|%2', SourceAmount, 0);
                    if Threshold.FindFirst() then
                        exit(Round(SourceAmount * Threshold."Percent" / 100, 0.01));
                end;
            Rule."Calculation Method"::"Slab Amount":
                begin
                    Threshold.SetRange("Agreement No.", Rule."Agreement No.");
                    Threshold.SetRange("Rule No.", Rule."Rule No.");
                    Threshold.SetFilter("Minimum Value", '<=%1', SourceAmount);
                    Threshold.SetFilter("Maximum Value", '>=%1|%2', SourceAmount, 0);
                    if Threshold.FindFirst() then
                        exit(Threshold.Amount);
                end;
            Rule."Calculation Method"::Growth:
                exit(Round(SourceAmount * Rule."Percent" / 100, 0.01));
        end;
        OnAfterCalculateAmount(Rule, SourceAmount, Quantity);
        exit(0);
    end;

    local procedure InsertCalcEntry(var Request: Record "Rebate Calculation Request"; Agreement: Record "Rebate Agreement Header"; Rule: Record "Rebate Rule"; SourceType: Enum "Rebate Source Type"; SourceDocNo: Code[20]; SourceLineNo: Integer; SourceKey: Text[250]; Eligible: Boolean; RejectionReason: Text[250]; SourceAmount: Decimal; Quantity: Decimal; RebateAmount: Decimal; CurrencyCode: Code[10]; RateDate: Date; DimensionSetId: Integer; Dim1: Code[20]; Dim2: Code[20])
    var
        Entry: Record "Rebate Calculation Entry";
    begin
        Entry.Init();
        Entry."Request No." := Request."No.";
        Entry."Agreement No." := Agreement."No.";
        Entry."Agreement Version No." := Agreement."Active Version No.";
        Entry."Rule No." := Rule."Rule No.";
        Entry."Source Type" := SourceType;
        Entry."Source Document No." := SourceDocNo;
        Entry."Source Line No." := SourceLineNo;
        Entry."Source Key" := SourceKey;
        Entry.Eligible := Eligible;
        Entry."Rejection Reason" := RejectionReason;
        Entry."Source Amount" := SourceAmount;
        Entry.Quantity := Quantity;
        Entry."Rebate Amount" := RebateAmount;
        Entry."Currency Code" := CurrencyCode;
        Entry."Exchange Rate" := 1;
        Entry."Exchange Rate Date" := RateDate;
        Entry."Amount (LCY)" := RebateAmount;
        Entry."Dimension Set ID" := DimensionSetId;
        Entry."Global Dimension 1 Code" := Dim1;
        Entry."Global Dimension 2 Code" := Dim2;
        Entry."External Idempotency Key" := CopyStr(StrSubstNo('%1|%2|%3|%4', Request."No.", SourceKey, Agreement."Active Version No.", Rule."Rule No."), 1, 250);
        Entry.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAmount(Rule: Record "Rebate Rule"; SourceAmount: Decimal; Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateAmount(Rule: Record "Rebate Rule"; SourceAmount: Decimal; Quantity: Decimal)
    begin
    end;
}

codeunit 50104 "Rebate Posting Engine"
{
    procedure CreateAccruals(RequestNo: Code[20])
    var
        CalcEntry: Record "Rebate Calculation Entry";
        AccrualEntry: Record "Rebate Accrual Entry";
    begin
        CalcEntry.SetRange("Request No.", RequestNo);
        CalcEntry.SetRange(Eligible, true);
        CalcEntry.SetRange(Posted, false);
        if CalcEntry.FindSet(true) then
            repeat
                AccrualEntry.SetRange("Calculation Entry No.", CalcEntry."Entry No.");
                AccrualEntry.SetRange("Entry Type", AccrualEntry."Entry Type"::Accrual);
                if not AccrualEntry.FindFirst() then begin
                    AccrualEntry.Init();
                    AccrualEntry."Calculation Entry No." := CalcEntry."Entry No.";
                    AccrualEntry."Agreement No." := CalcEntry."Agreement No.";
                    AccrualEntry."Agreement Version No." := CalcEntry."Agreement Version No.";
                    AccrualEntry."Entry Type" := AccrualEntry."Entry Type"::Accrual;
                    AccrualEntry.Status := AccrualEntry.Status::Open;
                    AccrualEntry.Amount := CalcEntry."Rebate Amount";
                    AccrualEntry."Amount (LCY)" := CalcEntry."Amount (LCY)";
                    AccrualEntry."Currency Code" := CalcEntry."Currency Code";
                    AccrualEntry."Posting Date" := WorkDate();
                    AccrualEntry."Dimension Set ID" := CalcEntry."Dimension Set ID";
                    AccrualEntry."Global Dimension 1 Code" := CalcEntry."Global Dimension 1 Code";
                    AccrualEntry."Global Dimension 2 Code" := CalcEntry."Global Dimension 2 Code";
                    AccrualEntry."Remaining Amount" := CalcEntry."Rebate Amount";
                    AccrualEntry."Posting Command Key" := CopyStr(StrSubstNo('ACCRUAL|%1', CalcEntry."Entry No."), 1, 250);
                    AccrualEntry.Insert(true);
                    CalcEntry.Posted := true;
                    CalcEntry.Modify(true);
                end;
            until CalcEntry.Next() = 0;
    end;

    procedure PreviewAccrualPosting(AccrualEntry: Record "Rebate Accrual Entry"; var DebitAccount: Code[20]; var CreditAccount: Code[20]; var Amount: Decimal)
    var
        Agreement: Record "Rebate Agreement Header";
        PostingSetup: Record "Rebate Posting Setup";
    begin
        Agreement.Get(AccrualEntry."Agreement No.");
        PostingSetup.Get(Agreement."Agreement Type", Agreement."Posting Group", AccrualEntry."Currency Code", PostingSetup."Entry Type"::Accrual);
        PostingSetup.TestField("Expense Account No.");
        PostingSetup.TestField("Liability Account No.");
        DebitAccount := PostingSetup."Expense Account No.";
        CreditAccount := PostingSetup."Liability Account No.";
        Amount := AccrualEntry.Amount;
    end;

    procedure PostOpenAccruals(AgreementNo: Code[20])
    var
        AccrualEntry: Record "Rebate Accrual Entry";
    begin
        AccrualEntry.SetRange("Agreement No.", AgreementNo);
        AccrualEntry.SetRange(Status, AccrualEntry.Status::Open);
        AccrualEntry.SetRange("Entry Type", AccrualEntry."Entry Type"::Accrual);
        if AccrualEntry.FindSet(true) then
            repeat
                PostAccrual(AccrualEntry);
            until AccrualEntry.Next() = 0;
    end;

    procedure PostAccrual(var AccrualEntry: Record "Rebate Accrual Entry")
    var
        DebitAccount: Code[20];
        CreditAccount: Code[20];
        Amount: Decimal;
        AuditMgt: Codeunit "Rebate Audit Mgt.";
    begin
        AccrualEntry.TestField(Status, AccrualEntry.Status::Open);
        PreviewAccrualPosting(AccrualEntry, DebitAccount, CreditAccount, Amount);
        AccrualEntry.Status := AccrualEntry.Status::Posted;
        AccrualEntry.Modify(true);
        AuditMgt.Log('Accrual Posted', Database::"Rebate Accrual Entry", Format(AccrualEntry."Entry No."), '', StrSubstNo('%1|%2|%3', DebitAccount, CreditAccount, Amount), '');
    end;

    procedure ReverseAccrual(AccrualEntryNo: Integer; ReasonCode: Code[20])
    var
        SourceAccrual: Record "Rebate Accrual Entry";
        Reversal: Record "Rebate Accrual Entry";
    begin
        SourceAccrual.Get(AccrualEntryNo);
        SourceAccrual.TestField(Status, SourceAccrual.Status::Posted);
        Reversal.Init();
        Reversal.TransferFields(SourceAccrual, false);
        Reversal."Entry Type" := Reversal."Entry Type"::Reversal;
        Reversal.Status := Reversal.Status::Posted;
        Reversal.Amount := -SourceAccrual.Amount;
        Reversal."Amount (LCY)" := -SourceAccrual."Amount (LCY)";
        Reversal."Remaining Amount" := 0;
        Reversal."Original Entry No." := SourceAccrual."Entry No.";
        Reversal."Reason Code" := ReasonCode;
        Reversal.Insert(true);
        SourceAccrual.Status := SourceAccrual.Status::Reversed;
        SourceAccrual.Modify(true);
    end;

    procedure PostAdjustment(OriginalEntryNo: Integer; DeltaAmount: Decimal; ReasonCode: Code[20])
    var
        SourceAccrual: Record "Rebate Accrual Entry";
        Adjustment: Record "Rebate Accrual Entry";
    begin
        SourceAccrual.Get(OriginalEntryNo);
        Adjustment.Init();
        Adjustment.TransferFields(SourceAccrual, false);
        Adjustment."Entry Type" := Adjustment."Entry Type"::Adjustment;
        Adjustment.Status := Adjustment.Status::Posted;
        Adjustment.Amount := DeltaAmount;
        Adjustment."Amount (LCY)" := DeltaAmount;
        Adjustment."Remaining Amount" := 0;
        Adjustment."Original Entry No." := SourceAccrual."Entry No.";
        Adjustment."Reason Code" := ReasonCode;
        Adjustment.Insert(true);
    end;
}

codeunit 50105 "Rebate Settlement Engine"
{
    procedure CreateProposal(AgreementNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]) SettlementNo: Code[20]
    var
        Agreement: Record "Rebate Agreement Header";
        Header: Record "Rebate Settlement Header";
        Accrual: Record "Rebate Accrual Entry";
        Line: Record "Rebate Settlement Line";
        LineNo: Integer;
    begin
        Agreement.Get(AgreementNo);
        Header.Init();
        Header."Agreement No." := AgreementNo;
        Header."Vendor No." := Agreement."Vendor No.";
        Header."Customer No." := Agreement."Customer No.";
        Header."Posting Date" := PostingDate;
        Header."Currency Code" := CurrencyCode;
        Header."Output Type" := Agreement."Settlement Method";
        Header.Insert(true);

        Accrual.SetRange("Agreement No.", AgreementNo);
        Accrual.SetRange(Status, Accrual.Status::Posted);
        Accrual.SetRange("Currency Code", CurrencyCode);
        if Accrual.FindSet() then
            repeat
                LineNo += 10000;
                Line.Init();
                Line."Settlement No." := Header."No.";
                Line."Line No." := LineNo;
                Line."Accrual Entry No." := Accrual."Entry No.";
                Line."Original Amount" := Accrual."Remaining Amount";
                Line."Settlement Amount" := Accrual."Remaining Amount";
                Line."Agreement No." := AgreementNo;
                Line."Currency Code" := CurrencyCode;
                Line.Insert(true);
                Header.Amount += Line."Settlement Amount";
            until Accrual.Next() = 0;
        Header.Modify(true);
        SettlementNo := Header."No.";
    end;

    procedure Approve(var Header: Record "Rebate Settlement Header")
    begin
        Header.TestField(Status, Header.Status::Open);
        Header.Status := Header.Status::Approved;
        Header.Modify(true);
    end;

    procedure Reject(var Header: Record "Rebate Settlement Header")
    begin
        Header.Status := Header.Status::Rejected;
        Header.Modify(true);
    end;

    procedure Post(var Header: Record "Rebate Settlement Header")
    var
        Line: Record "Rebate Settlement Line";
        Accrual: Record "Rebate Accrual Entry";
        SettlementEntry: Record "Rebate Accrual Entry";
    begin
        Header.TestField(Status, Header.Status::Approved);
        Line.SetRange("Settlement No.", Header."No.");
        if Line.FindSet() then
            repeat
                Accrual.Get(Line."Accrual Entry No.");
                Accrual.Status := Accrual.Status::Closed;
                Accrual."Closed by Settlement No." := Header."No.";
                Accrual."Remaining Amount" := Accrual."Remaining Amount" - Line."Settlement Amount";
                Accrual.Modify(true);

                SettlementEntry.Init();
                SettlementEntry.TransferFields(Accrual, false);
                SettlementEntry."Entry Type" := SettlementEntry."Entry Type"::Settlement;
                SettlementEntry.Status := SettlementEntry.Status::Posted;
                SettlementEntry.Amount := -Line."Settlement Amount";
                SettlementEntry."Amount (LCY)" := -Line."Settlement Amount";
                SettlementEntry."Original Entry No." := Accrual."Entry No.";
                SettlementEntry."Closed by Settlement No." := Header."No.";
                SettlementEntry.Insert(true);
            until Line.Next() = 0;
        Header.Status := Header.Status::Posted;
        Header.Modify(true);
    end;
}

codeunit 50106 "Rebate Recalculation Engine"
{
    procedure CreateDelta(OriginalEntryNo: Integer; NewAmount: Decimal)
    var
        Original: Record "Rebate Calculation Entry";
        Delta: Record "Rebate Calculation Entry";
    begin
        Original.Get(OriginalEntryNo);
        Delta.Init();
        Delta.TransferFields(Original, false);
        Delta."Original Entry No." := Original."Entry No.";
        Delta."Old Amount" := Original."Rebate Amount";
        Delta."New Amount" := NewAmount;
        Delta."Delta Amount" := NewAmount - Original."Rebate Amount";
        Delta."Rebate Amount" := Delta."Delta Amount";
        Delta.Posted := false;
        Delta.Insert(true);
    end;

    procedure PostDelta(OriginalAccrualEntryNo: Integer; DeltaAmount: Decimal)
    var
        PostingEngine: Codeunit "Rebate Posting Engine";
    begin
        PostingEngine.PostAdjustment(OriginalAccrualEntryNo, DeltaAmount, 'RECALC');
    end;
}

codeunit 50107 "Rebate Job Dispatcher"
{
    procedure RunCalculation(RequestNo: Code[20])
    var
        Request: Record "Rebate Calculation Request";
        CalcEngine: Codeunit "Rebate Calculation Engine";
    begin
        Request.Get(RequestNo);
        CalcEngine.RunRequest(Request);
    end;

    procedure LogChunk(RequestNo: Code[20]; ChunkNo: Integer; Status: Enum "Rebate Request Status"; ResumeKey: Text[250]; ProcessedCount: Integer; FailedCount: Integer; RetryEligible: Boolean; Message: Text[250])
    var
        JobLog: Record "Rebate Job Log";
    begin
        JobLog.Init();
        JobLog."Request No." := RequestNo;
        JobLog."Chunk No." := ChunkNo;
        JobLog.Status := Status;
        JobLog."Resume Key" := ResumeKey;
        JobLog."Processed Count" := ProcessedCount;
        JobLog."Failed Count" := FailedCount;
        JobLog."Retry Eligible" := RetryEligible;
        JobLog."User Message" := Message;
        JobLog."Created DateTime" := CurrentDateTime();
        JobLog.Insert(true);
    end;
}

codeunit 50108 "Rebate Integration Mgt."
{
    procedure LogInbound(ExternalReferenceId: Code[100]; Operation: Text[100]; RelatedRecord: Text[250])
    begin
        CreateLog(ExternalReferenceId, Operation, RelatedRecord, 0);
    end;

    procedure LogOutbound(ExternalReferenceId: Code[100]; Operation: Text[100]; RelatedRecord: Text[250])
    begin
        CreateLog(ExternalReferenceId, Operation, RelatedRecord, 1);
    end;

    procedure AssertNotDuplicate(ExternalReferenceId: Code[100]; Operation: Text[100])
    var
        IntegrationLog: Record "Rebate Integration Log";
    begin
        IntegrationLog.SetRange("External Reference ID", ExternalReferenceId);
        IntegrationLog.SetRange(Operation, Operation);
        if IntegrationLog.FindFirst() then
            Error('External reference %1 for operation %2 has already been processed.', ExternalReferenceId, Operation);
    end;

    procedure MarkFailed(ExternalReferenceId: Code[100]; Operation: Text[100]; ErrorCategory: Enum "Rebate Error Category"; UserMessage: Text[250]; TechnicalDetails: Text[2048]; RetryEligible: Boolean)
    var
        IntegrationLog: Record "Rebate Integration Log";
    begin
        IntegrationLog.SetRange("External Reference ID", ExternalReferenceId);
        IntegrationLog.SetRange(Operation, Operation);
        if IntegrationLog.FindLast() then begin
            IntegrationLog.Status := IntegrationLog.Status::Failed;
            IntegrationLog."Error Category" := ErrorCategory;
            IntegrationLog."User Message" := UserMessage;
            IntegrationLog."Technical Details" := TechnicalDetails;
            IntegrationLog."Retry Eligible" := RetryEligible;
            IntegrationLog.Modify(true);
        end;
    end;

    local procedure CreateLog(ExternalReferenceId: Code[100]; Operation: Text[100]; RelatedRecord: Text[250]; Direction: Integer)
    var
        IntegrationLog: Record "Rebate Integration Log";
    begin
        AssertNotDuplicate(ExternalReferenceId, Operation);
        IntegrationLog.Init();
        IntegrationLog."External Reference ID" := ExternalReferenceId;
        IntegrationLog.Direction := Direction;
        IntegrationLog.Operation := Operation;
        IntegrationLog.Status := IntegrationLog.Status::Completed;
        IntegrationLog."Related Record" := RelatedRecord;
        IntegrationLog."Created DateTime" := CurrentDateTime();
        IntegrationLog.Insert(true);
    end;
}

codeunit 50109 "Rebate Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        RebateSetup: Record "Rebate Setup";
    begin
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup.Insert(true);
        end;
    end;
}

codeunit 50110 "Rebate Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        RebateSetup: Record "Rebate Setup";
    begin
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup.Insert(true);
        end;
    end;
}

codeunit 50111 "Rebate Tests"
{
    Subtype = Test;

    [Test]
    procedure PercentageCalculationReturnsExpectedAmount()
    var
        Rule: Record "Rebate Rule";
        CalcEngine: Codeunit "Rebate Calculation Engine";
    begin
        Rule."Calculation Method" := Rule."Calculation Method"::Percentage;
        Rule."Percent" := 5;
        if CalcEngine.CalculateAmount(Rule, 1000, 1) <> 50 then
            Error('Percentage calculation failed.');
    end;

    [Test]
    procedure DuplicateIntegrationReferenceIsBlocked()
    var
        IntegrationMgt: Codeunit "Rebate Integration Mgt.";
    begin
        IntegrationMgt.LogInbound('TEST-REF', 'AgreementImport', 'A1');
        asserterror IntegrationMgt.LogInbound('TEST-REF', 'AgreementImport', 'A1');
    end;
}
