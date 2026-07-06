codeunit 50100 "RBT Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InitializeRebateSetup();
        InitializeDefaultPostingSetup();
    end;

    local procedure InitializeRebateSetup()
    var
        RebateSetup: Record "RBT Rebate Setup";
        Modified: Boolean;
    begin
        if not RebateSetup.Get() then begin
            RebateSetup.Init();
            RebateSetup."Primary Key" := '';
            RebateSetup.Insert();
        end;

        InitializeNoSeries('RBT-AGR', 'Rebate Agreements', 'RBT-AGR-0001');
        InitializeNoSeries('RBT-SETL', 'Rebate Settlements', 'RBT-SETL-0001');
        InitializeNoSeries('RBT-CALC', 'Rebate Calculations', 'RBT-CALC-0001');
        InitializeNoSeries('RBT-AUD', 'Rebate Audit Entries', 'RBT-AUD-0001');

        Modified := false;
        if RebateSetup."Agreement Nos." = '' then begin
            RebateSetup."Agreement Nos." := 'RBT-AGR';
            Modified := true;
        end;
        if RebateSetup."Settlement Nos." = '' then begin
            RebateSetup."Settlement Nos." := 'RBT-SETL';
            Modified := true;
        end;
        if RebateSetup."Calculation Nos." = '' then begin
            RebateSetup."Calculation Nos." := 'RBT-CALC';
            Modified := true;
        end;
        if RebateSetup."Audit Nos." = '' then begin
            RebateSetup."Audit Nos." := 'RBT-AUD';
            Modified := true;
        end;
        if Modified then
            RebateSetup.Modify();
    end;

    local procedure InitializeNoSeries(SeriesCode: Code[20]; SeriesDescription: Text[100]; StartingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(SeriesCode) then
            exit;

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := SeriesDescription;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert();
    end;

    /// <summary>
    /// Seeds the blank-Rebate-Group-Code fallback row in RBT Rebate Posting Setup.
    /// The accounts on this row are left blank intentionally - administrators must populate
    /// the G/L accounts on the Rebate Posting Setup page before the first accrual run.
    /// The presence of the blank-code row enables the GetPostingSetup() fallback path.
    /// Idempotent: guarded by Get() so re-install does not duplicate or error.
    /// </summary>
    local procedure InitializeDefaultPostingSetup()
    var
        PostingSetup: Record "RBT Rebate Post Set";
    begin
        if PostingSetup.Get('') then
            exit;

        PostingSetup.Init();
        PostingSetup."Rebate Group Code" := '';
        PostingSetup.Insert();
    end;
}
