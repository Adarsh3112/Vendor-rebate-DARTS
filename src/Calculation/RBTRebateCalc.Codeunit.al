codeunit 50104 "RBT Rebate Calc."
{
    TableNo = "RBT Rebate Calc Hdr";

    trigger OnRun()
    begin
        CalculateAndPost(Rec);
    end;

    procedure CalculateAndPost(var CalcHeader: Record "RBT Rebate Calc Hdr")
    var
        Agreement: Record "RBT Rebate Agreement";
        Header: Record "RBT Agreement Header";
        PurchInvLine: Record "Purch. Inv. Line";
        AccrualEngine: Codeunit "RBT Accrual Engine";
        TotalAmount: Decimal;
        RebateAmount: Decimal;
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        UsedNewHeaderPath: Boolean;
    begin
        if CalcHeader."Posting Status" = CalcHeader."Posting Status"::Posted then
            Error('Calculation Request %1 has already been posted.', CalcHeader."No.");

        if Header.Get(CalcHeader."Agreement No.") then begin
            Header.TestField(Status, Header.Status::Active);
            VendorNo := Header."Vendor No.";
            CurrencyCode := Header."Currency Code";
            RebateAmount := CalculateForAgreementHeader(Header, CalcHeader);
            UsedNewHeaderPath := true;
        end else if Agreement.Get(CalcHeader."Agreement No.") then begin
            Agreement.TestField(Status, Agreement.Status::Active);
            VendorNo := Agreement."Vendor No.";
            CurrencyCode := Agreement."Currency Code";

            PurchInvLine.SetRange("Buy-from Vendor No.", VendorNo);
            PurchInvLine.SetRange("Posting Date", CalcHeader."Calc. From Date", CalcHeader."Calc. To Date");
            if PurchInvLine.FindSet() then
                repeat
                    TotalAmount += PurchInvLine."Line Amount";
                until PurchInvLine.Next() = 0;

            RebateAmount := CalculateRebate(Agreement, TotalAmount);
        end else
            Error('Agreement %1 not found.', CalcHeader."Agreement No.");

        CalcHeader."Total Amount" := RebateAmount;
        CalcHeader.Modify();

        // Delegate posting half (F-04) to the dedicated accrual engine. The
        // engine handles per-row idempotency, posting-status update, and
        // the No. of G/L Entries count. The engine requires the modern
        // RBT Agreement Header (with Posting Group) so it is only invoked
        // on the header path; the legacy RBT Rebate Agreement path stays
        // self-contained and flips Posting Status itself to preserve the
        // existing outer-duplicate-guard semantics.
        if UsedNewHeaderPath then begin
            if RebateAmount <> 0 then
                AccrualEngine.Run(CalcHeader);
        end else begin
            CalcHeader."Posting Status" := CalcHeader."Posting Status"::Posted;
            CalcHeader."No. of G/L Entries" := 0;
            CalcHeader.Modify();
        end;
    end;

    procedure CalculateRebate(Agreement: Record "RBT Rebate Agreement"; TotalAmount: Decimal): Decimal
    begin
        case Agreement."Calc. Method" of
            Agreement."Calc. Method"::Flat:
                exit(TotalAmount * Agreement."Rebate %" / 100);
            Agreement."Calc. Method"::Tiered:
                exit(CalculateTiered(Agreement, TotalAmount));
            Agreement."Calc. Method"::Slab:
                exit(CalculateSlab(Agreement, TotalAmount));
            Agreement."Calc. Method"::Growth:
                if TotalAmount > Agreement."Baseline Amount" then
                    exit((TotalAmount - Agreement."Baseline Amount") * Agreement."Rebate %" / 100);
        end;
        exit(0);
    end;

    procedure PostSettlement(var LedgerEntry: Record "RBT Rebate Ledg Ent")
    var
        Agreement: Record "RBT Rebate Agreement";
        Header: Record "RBT Agreement Header";
        Vendor: Record Vendor;
        PostingSetup: Record "RBT Rebate Post Set";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        RebateGroupCode: Code[20];
        SettlementLedgerEntry: Record "RBT Rebate Ledg Ent";
        CurrencyCode: Code[10];
    begin
        LedgerEntry.TestField("Entry Type", 0); // 0 = Accrual
        LedgerEntry.TestField(Amount);

        if Header.Get(LedgerEntry."Agreement No.") then
            CurrencyCode := Header."Currency Code"
        else if Agreement.Get(LedgerEntry."Agreement No.") then
            CurrencyCode := Agreement."Currency Code"
        else
            Error('Agreement %1 not found.', LedgerEntry."Agreement No.");

        Vendor.Get(LedgerEntry."Vendor No.");
        Vendor.TestField(Blocked, Vendor.Blocked::" ");

        RebateGroupCode := Vendor."Vendor Posting Group";
        PostingSetup.GetPostingSetup(RebateGroupCode);
        PostingSetup.TestField("Accrual Account No.");

        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
        PurchaseHeader.Validate("Buy-from Vendor No.", LedgerEntry."Vendor No.");
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader.Insert(true);

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine.Validate("No.", PostingSetup."Accrual Account No.");
        PurchaseLine.Description := StrSubstNo('Rebate Settlement for Agreement %1', LedgerEntry."Agreement No.");
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", LedgerEntry.Amount);
        PurchaseLine.Insert();

        PurchPost.Run(PurchaseHeader);

        SettlementLedgerEntry.Init();
        SettlementLedgerEntry."Agreement No." := LedgerEntry."Agreement No.";
        SettlementLedgerEntry."Vendor No." := LedgerEntry."Vendor No.";
        SettlementLedgerEntry."Posting Date" := WorkDate();
        SettlementLedgerEntry."Document No." := PurchaseHeader."Last Posting No.";
        SettlementLedgerEntry.Amount := -LedgerEntry.Amount;
        SettlementLedgerEntry."Currency Code" := CurrencyCode;
        SettlementLedgerEntry."Amount (LCY)" := -LedgerEntry."Amount (LCY)";
        SettlementLedgerEntry."Entry Type" := 1; // 1 = Settlement
        SettlementLedgerEntry.Insert();
    end;

    local procedure CalculateTiered(Agreement: Record "RBT Rebate Agreement"; TotalAmount: Decimal): Decimal
    var
        Tier: Record "RBT Rebate Tier";
        NextTier: Record "RBT Rebate Tier";
        RebateAmount, RemainingAmount, PreviousMin, AmountInTier : Decimal;
    begin
        Tier.SetRange("Agreement No.", Agreement."No.");
        Tier.SetCurrentKey("Minimum Amount");
        if not Tier.FindSet() then exit(0);

        RemainingAmount := TotalAmount;
        PreviousMin := 0;

        repeat
            if RemainingAmount <= 0 then break;
            if TotalAmount < Tier."Minimum Amount" then break;

            NextTier := Tier;
            if NextTier.Next() <> 0 then
                AmountInTier := NextTier."Minimum Amount" - PreviousMin
            else
                AmountInTier := RemainingAmount;

            if AmountInTier > RemainingAmount then AmountInTier := RemainingAmount;
            RebateAmount += AmountInTier * Tier."Rebate %" / 100;
            RemainingAmount -= AmountInTier;
            PreviousMin := Tier."Minimum Amount" + AmountInTier;
        until Tier.Next() = 0;
        exit(RebateAmount);
    end;

    local procedure CalculateSlab(Agreement: Record "RBT Rebate Agreement"; TotalAmount: Decimal): Decimal
    var
        Tier: Record "RBT Rebate Tier";
    begin
        Tier.SetRange("Agreement No.", Agreement."No.");
        Tier.SetRange("Minimum Amount", 0, TotalAmount);
        if Tier.FindLast() then exit(TotalAmount * Tier."Rebate %" / 100);
        exit(0);
    end;

    local procedure CalculateForAgreementHeader(Header: Record "RBT Agreement Header"; CalcHeader: Record "RBT Rebate Calc Hdr"): Decimal
    var
        Rule: Record "RBT Rebate Rule";
        EligEngine: Codeunit "RBT Elig Engine";
        TempPurchLine: Record "Purch. Inv. Line" temporary;
        TempSalesLine: Record "Sales Invoice Line" temporary;
        TotalRebateAmount: Decimal;
    begin
        Rule.SetRange("Agreement No.", Header."No.");
        if not Rule.FindSet() then exit(0);

        repeat
            EligEngine.GetEligibleLines(Header, Rule, CalcHeader."Calc. From Date", CalcHeader."Calc. To Date", TempPurchLine, TempSalesLine);
            TotalRebateAmount += ProcessEligibleLines(Header, Rule, CalcHeader, TempPurchLine, TempSalesLine);
        until Rule.Next() = 0;

        exit(TotalRebateAmount);
    end;

    local procedure ProcessEligibleLines(Header: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; CalcHeader: Record "RBT Rebate Calc Hdr"; var TempPurchLine: Record "Purch. Inv. Line" temporary; var TempSalesLine: Record "Sales Invoice Line" temporary): Decimal
    var
        RuleTotalRebate: Decimal;
    begin
        if TempPurchLine.FindSet() then
            repeat
                RuleTotalRebate += CalculateAndRecordLine(Header, Rule, CalcHeader, TempPurchLine."Line Amount", TempPurchLine."Document No.", 0); // 0 = Purchase
            until TempPurchLine.Next() = 0;

        if TempSalesLine.FindSet() then
            repeat
                RuleTotalRebate += CalculateAndRecordLine(Header, Rule, CalcHeader, TempSalesLine."Line Amount", TempSalesLine."Document No.", 1); // 1 = Sales
            until TempSalesLine.Next() = 0;

        exit(RuleTotalRebate);
    end;

    local procedure CalculateAndRecordLine(Header: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; CalcHeader: Record "RBT Rebate Calc Hdr"; LineAmount: Decimal; SourceNo: Code[20]; SourceType: Option): Decimal
    var
        CalcLedgEntry: Record "RBT Calc Ledg Entry";
        PrevCalcLedgEntry: Record "RBT Calc Ledg Entry";
        NewRebateAmt, ExistingRebateAmt, DeltaAmt : Decimal;
        CurrentVersionNo: Integer;
    begin
        CurrentVersionNo := GetCurrentVersionNo(Header."No.");
        
        case Rule."Calculation Method" of
            Rule."Calculation Method"::Percentage:
                NewRebateAmt := LineAmount * Rule.Value / 100;
            Rule."Calculation Method"::"Fixed Amount":
                NewRebateAmt := Rule.Value;
        end;

        PrevCalcLedgEntry.SetRange("Agreement No.", Header."No.");
        PrevCalcLedgEntry.SetRange("Source Type", SourceType);
        PrevCalcLedgEntry.SetRange("Source Trans. No.", SourceNo);
        PrevCalcLedgEntry.SetRange("Rule No.", Rule."Rule No.");
        
        if PrevCalcLedgEntry.FindSet() then
            repeat
                ExistingRebateAmt += PrevCalcLedgEntry."Amount FCY";
            until PrevCalcLedgEntry.Next() = 0;

        DeltaAmt := NewRebateAmt - ExistingRebateAmt;

        if DeltaAmt <> 0 then begin
            CalcLedgEntry.Init();
            CalcLedgEntry."Agreement No." := Header."No.";
            CalcLedgEntry."Version No." := CurrentVersionNo;
            CalcLedgEntry."Rule No." := Rule."Rule No.";
            CalcLedgEntry."Source Trans. No." := SourceNo;
            CalcLedgEntry."Source Type" := SourceType;
            CalcLedgEntry."Amount FCY" := DeltaAmt;
            CalcLedgEntry."Amount LCY" := DeltaAmt; 
            CalcLedgEntry."Exchange Rate" := 1;
            CalcLedgEntry."Currency Code" := Header."Currency Code";
            CalcLedgEntry."Posting Date" := CalcHeader."Calc. To Date";
            CalcLedgEntry."Calculation Req. No." := CalcHeader."No.";
            if PrevCalcLedgEntry.FindLast() then
                CalcLedgEntry."Corrects Entry No." := PrevCalcLedgEntry."Entry No.";
            CalcLedgEntry.Insert();
        end;

        exit(DeltaAmt);
    end;

    local procedure GetCurrentVersionNo(AgreementNo: Code[20]): Integer
    var
        Version: Record "RBT Agmt Version";
    begin
        Version.SetRange("Agreement No.", AgreementNo);
        Version.SetRange("Is Current Version", true);
        if Version.FindFirst() then exit(Version."Version No.");
        exit(1);
    end;

}
