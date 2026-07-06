codeunit 50102 "RBT Elig Engine"
{
    procedure CountEligibleLines(AgreementHeader: Record "RBT Agreement Header"): Integer
    var
        EligibleAmount: Decimal;
        EligibleQty: Decimal;
    begin
        exit(ScanEligibleLines(AgreementHeader, AgreementHeader."Start Date", AgreementHeader."End Date", EligibleAmount, EligibleQty, false));
    end;

    procedure CalcEligibleAmount(AgreementHeader: Record "RBT Agreement Header"; var EligibleAmount: Decimal; var EligibleQty: Decimal)
    begin
        EligibleAmount := 0;
        EligibleQty := 0;
        ScanEligibleLines(AgreementHeader, AgreementHeader."Start Date", AgreementHeader."End Date", EligibleAmount, EligibleQty, true);
    end;

    procedure CalcEligibleAmount(AgreementHeader: Record "RBT Agreement Header"; var EligibleAmount: Decimal; var EligibleQty: Decimal; FromDate: Date; ToDate: Date)
    var
        EffectiveFrom, EffectiveTo : Date;
    begin
        IntersectDates(AgreementHeader, FromDate, ToDate, EffectiveFrom, EffectiveTo);
        ScanEligibleLines(AgreementHeader, EffectiveFrom, EffectiveTo, EligibleAmount, EligibleQty, true);
    end;

    procedure CalcEligibleAmount(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; var EligibleAmount: Decimal; var EligibleQty: Decimal; FromDate: Date; ToDate: Date)
    var
        EffectiveFrom, EffectiveTo : Date;
        EligibleCount: Integer;
    begin
        IntersectDates(AgreementHeader, FromDate, ToDate, EffectiveFrom, EffectiveTo);
        AgreementHeader.TestField(Status, AgreementHeader.Status::Active);

        case AgreementHeader."Type" of
            AgreementHeader."Type"::Vendor:
                ScanPurchInvLine(AgreementHeader, Rule, EffectiveFrom, EffectiveTo, EligibleAmount, EligibleQty, EligibleCount, true, true);
            AgreementHeader."Type"::Customer:
                ScanSalesInvLine(AgreementHeader, Rule, EffectiveFrom, EffectiveTo, EligibleAmount, EligibleQty, EligibleCount, true, true);
        end;
    end;

    procedure GetEligibleLines(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; FromDate: Date; ToDate: Date; var TempPurchLine: Record "Purch. Inv. Line" temporary; var TempSalesLine: Record "Sales Invoice Line" temporary)
    var
        EffectiveFrom, EffectiveTo : Date;
        DummyAmt: Decimal;
        DummyQty: Decimal;
        DummyCount: Integer;
    begin
        IntersectDates(AgreementHeader, FromDate, ToDate, EffectiveFrom, EffectiveTo);
        AgreementHeader.TestField(Status, AgreementHeader.Status::Active);

        TempPurchLine.Reset();
        TempPurchLine.DeleteAll();
        TempSalesLine.Reset();
        TempSalesLine.DeleteAll();

        case AgreementHeader."Type" of
            AgreementHeader."Type"::Vendor:
                ScanPurchInvLineToTemp(AgreementHeader, Rule, EffectiveFrom, EffectiveTo, TempPurchLine);
            AgreementHeader."Type"::Customer:
                ScanSalesInvLineToTemp(AgreementHeader, Rule, EffectiveFrom, EffectiveTo, TempSalesLine);
        end;
    end;

    local procedure IntersectDates(AgreementHeader: Record "RBT Agreement Header"; FromDate: Date; ToDate: Date; var EffectiveFrom: Date; var EffectiveTo: Date)
    begin
        EffectiveFrom := AgreementHeader."Start Date";
        if (FromDate <> 0D) and ((EffectiveFrom = 0D) or (FromDate > EffectiveFrom)) then
            EffectiveFrom := FromDate;

        EffectiveTo := AgreementHeader."End Date";
        if (ToDate <> 0D) and ((EffectiveTo = 0D) or (ToDate < EffectiveTo)) then
            EffectiveTo := ToDate;
    end;

    local procedure ScanEligibleLines(AgreementHeader: Record "RBT Agreement Header"; FromDate: Date; ToDate: Date; var EligibleAmount: Decimal; var EligibleQty: Decimal; Aggregate: Boolean): Integer
    var
        Rule: Record "RBT Rebate Rule";
        EligibleCount: Integer;
        HasAnyRule: Boolean;
    begin
        AgreementHeader.TestField(Status, AgreementHeader.Status::Active);
        EligibleCount := 0;

        Rule.SetRange("Agreement No.", AgreementHeader."No.");
        HasAnyRule := Rule.FindSet();

        case AgreementHeader."Type" of
            AgreementHeader."Type"::Vendor:
                begin
                    if HasAnyRule then
                        repeat
                            ScanPurchInvLine(AgreementHeader, Rule, FromDate, ToDate, EligibleAmount, EligibleQty, EligibleCount, Aggregate, true);
                        until Rule.Next() = 0
                    else
                        ScanPurchInvLine(AgreementHeader, Rule, FromDate, ToDate, EligibleAmount, EligibleQty, EligibleCount, Aggregate, false);
                end;
            AgreementHeader."Type"::Customer:
                begin
                    if HasAnyRule then
                        repeat
                            ScanSalesInvLine(AgreementHeader, Rule, FromDate, ToDate, EligibleAmount, EligibleQty, EligibleCount, Aggregate, true);
                        until Rule.Next() = 0
                    else
                        ScanSalesInvLine(AgreementHeader, Rule, FromDate, ToDate, EligibleAmount, EligibleQty, EligibleCount, Aggregate, false);
                end;
        end;
        exit(EligibleCount);
    end;

    local procedure ScanPurchInvLine(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; FromDate: Date; ToDate: Date; var EligibleAmount: Decimal; var EligibleQty: Decimal; var EligibleCount: Integer; Aggregate: Boolean; ApplyRule: Boolean)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        IsEligible: Boolean;
        SourceRecordRef: RecordRef;
    begin
        PurchInvLine.SetLoadFields("Document No.", "Line No.", "No.", "Buy-from Vendor No.", "Posting Date", "Line Amount", Quantity, Type);
        PurchInvLine.SetRange("Buy-from Vendor No.", AgreementHeader."Vendor No.");
        PurchInvLine.SetRange("Posting Date", FromDate, ToDate);

        if ApplyRule then ApplyRuleFilters(Rule, PurchInvLine);

        if PurchInvLine.FindSet() then
            repeat
                IsEligible := true;
                SourceRecordRef.GetTable(PurchInvLine);
                OnAfterCheckEligibility(AgreementHeader, SourceRecordRef, IsEligible);
                if IsEligible then begin
                    EligibleCount += 1;
                    if Aggregate then begin
                        EligibleAmount += PurchInvLine."Line Amount";
                        EligibleQty += PurchInvLine.Quantity;
                    end;
                end;
            until PurchInvLine.Next() = 0;
    end;

    local procedure ScanPurchInvLineToTemp(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; FromDate: Date; ToDate: Date; var TempPurchLine: Record "Purch. Inv. Line" temporary)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        IsEligible: Boolean;
        SourceRecordRef: RecordRef;
    begin
        PurchInvLine.SetLoadFields("Document No.", "Line No.", "No.", "Buy-from Vendor No.", "Posting Date", "Line Amount", Quantity, Type);
        PurchInvLine.SetRange("Buy-from Vendor No.", AgreementHeader."Vendor No.");
        PurchInvLine.SetRange("Posting Date", FromDate, ToDate);

        ApplyRuleFilters(Rule, PurchInvLine);

        if PurchInvLine.FindSet() then
            repeat
                IsEligible := true;
                SourceRecordRef.GetTable(PurchInvLine);
                OnAfterCheckEligibility(AgreementHeader, SourceRecordRef, IsEligible);
                if IsEligible then begin
                    TempPurchLine := PurchInvLine;
                    TempPurchLine.Insert();
                end;
            until PurchInvLine.Next() = 0;
    end;

    local procedure ScanSalesInvLine(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; FromDate: Date; ToDate: Date; var EligibleAmount: Decimal; var EligibleQty: Decimal; var EligibleCount: Integer; Aggregate: Boolean; ApplyRule: Boolean)
    var
        SalesInvLine: Record "Sales Invoice Line";
        IsEligible: Boolean;
        SourceRecordRef: RecordRef;
    begin
        SalesInvLine.SetLoadFields("Document No.", "Line No.", "No.", "Sell-to Customer No.", "Posting Date", "Line Amount", Quantity, Type);
        SalesInvLine.SetRange("Sell-to Customer No.", AgreementHeader."Customer No.");
        SalesInvLine.SetRange("Posting Date", FromDate, ToDate);

        if ApplyRule then ApplyRuleFiltersSales(Rule, SalesInvLine);

        if SalesInvLine.FindSet() then
            repeat
                IsEligible := true;
                SourceRecordRef.GetTable(SalesInvLine);
                OnAfterCheckEligibility(AgreementHeader, SourceRecordRef, IsEligible);
                if IsEligible then begin
                    EligibleCount += 1;
                    if Aggregate then begin
                        EligibleAmount += SalesInvLine."Line Amount";
                        EligibleQty += SalesInvLine.Quantity;
                    end;
                end;
            until SalesInvLine.Next() = 0;
    end;

    local procedure ScanSalesInvLineToTemp(AgreementHeader: Record "RBT Agreement Header"; Rule: Record "RBT Rebate Rule"; FromDate: Date; ToDate: Date; var TempSalesLine: Record "Sales Invoice Line" temporary)
    var
        SalesInvLine: Record "Sales Invoice Line";
        IsEligible: Boolean;
        SourceRecordRef: RecordRef;
    begin
        SalesInvLine.SetLoadFields("Document No.", "Line No.", "No.", "Sell-to Customer No.", "Posting Date", "Line Amount", Quantity, Type);
        SalesInvLine.SetRange("Sell-to Customer No.", AgreementHeader."Customer No.");
        SalesInvLine.SetRange("Posting Date", FromDate, ToDate);

        ApplyRuleFiltersSales(Rule, SalesInvLine);

        if SalesInvLine.FindSet() then
            repeat
                IsEligible := true;
                SourceRecordRef.GetTable(SalesInvLine);
                OnAfterCheckEligibility(AgreementHeader, SourceRecordRef, IsEligible);
                if IsEligible then begin
                    TempSalesLine := SalesInvLine;
                    TempSalesLine.Insert();
                end;
            until SalesInvLine.Next() = 0;
    end;

    local procedure ApplyRuleFilters(Rule: Record "RBT Rebate Rule"; var PurchInvLine: Record "Purch. Inv. Line")
    var
        InclusionText, ExclusionText : Text;
    begin
        InclusionText := Rule.GetInclusionCriteria();
        ExclusionText := Rule.GetExclusionCriteria();
        if InclusionText <> '' then PurchInvLine.SetFilter("No.", InclusionText);
        if ExclusionText <> '' then PurchInvLine.SetFilter("No.", '<>%1', ExclusionText);
    end;

    local procedure ApplyRuleFiltersSales(Rule: Record "RBT Rebate Rule"; var SalesInvLine: Record "Sales Invoice Line")
    var
        InclusionText, ExclusionText : Text;
    begin
        InclusionText := Rule.GetInclusionCriteria();
        ExclusionText := Rule.GetExclusionCriteria();
        if InclusionText <> '' then SalesInvLine.SetFilter("No.", InclusionText);
        if ExclusionText <> '' then SalesInvLine.SetFilter("No.", '<>%1', ExclusionText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEligibility(AgreementHeader: Record "RBT Agreement Header"; SourceRecordRef: RecordRef; var IsEligible: Boolean)
    begin
    end;
}
