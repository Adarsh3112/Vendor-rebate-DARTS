codeunit 50108 "RBT Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InitializeSetup();
    end;

    procedure InitializeSetup()
    var
        RebateSetup: Record "RBT Rebate Setup";
    begin
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup."Primary Key" := '';
            RebateSetup.Insert();
        end;

        InitializeNoSeries('RBT-AGR', 'Rebate Agreements', 'AGR00001');
        InitializeNoSeries('RBT-ACC', 'Rebate Accruals', 'ACC00001');
        InitializeNoSeries('RBT-SET', 'Rebate Settlements', 'SET00001');
        InitializeNoSeries('RBT-CALC', 'Rebate Calculation Requests', 'CALC00001');
        InitializeNoSeries('RBT-AUD', 'Rebate Audit', 'AUD00001');

        if RebateSetup."Rebate Agreement Nos." = '' then
            RebateSetup."Rebate Agreement Nos." := 'RBT-AGR';
        if RebateSetup."Accrual Nos." = '' then
            RebateSetup."Accrual Nos." := 'RBT-ACC';
        if RebateSetup."Settlement Nos." = '' then
            RebateSetup."Settlement Nos." := 'RBT-SET';
        if RebateSetup."Calculation Request Nos." = '' then
            RebateSetup."Calculation Request Nos." := 'RBT-CALC';
        if RebateSetup."Rebate Audit Nos." = '' then
            RebateSetup."Rebate Audit Nos." := 'RBT-AUD';
        RebateSetup.Modify();

        SeedDefaultPostingSetup();
    end;

    local procedure InitializeNoSeries(SeriesCode: Code[20]; SeriesDescription: Text[100]; StartingNo: Code[20])
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

    local procedure SeedDefaultPostingSetup()
    var
        PostingSetup: Record "RBT Posting Setup";
    begin
        if PostingSetup.Get('DEFAULT', '') then
            exit;
        PostingSetup.Init();
        PostingSetup."Posting Group" := 'DEFAULT';
        PostingSetup."Currency Code" := '';
        PostingSetup.Insert();
    end;
}
