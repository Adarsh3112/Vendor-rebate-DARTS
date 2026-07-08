codeunit 50311 "BSB Recalc Engine"
{
    procedure Recalculate(var Request: Record "BSB Calc Request")
    var
        CalcEntry: Record "BSB Calc Entry";
        Result: Record "BSB Recalc Result";
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        if not Request."Recalc Mode" then
            Error('Request %1 is not in recalculation mode.', Request."Request No.");
        if Request."Date From" = 0D then
            Error('Recalculation requires a bounded date range.');

        CalcEntry.SetRange("Agreement No.", Request."Agreement No.");
        if CalcEntry.FindSet() then
            repeat
                Result.Init();
                Result."Request No." := Request."Request No.";
                Result."Original Entry No." := CalcEntry."Entry No.";
                Result."Agreement No." := CalcEntry."Agreement No.";
                Result."Old Version No." := CalcEntry."Version No.";
                Result."New Version No." := CalcEntry."Version No." + 1;
                Result."Old Amount" := CalcEntry."Calculated Amount";
                Result."New Amount" := Round(CalcEntry."Calculated Amount" * 1.05, 0.01);
                Result."Delta Amount" := Result."New Amount" - Result."Old Amount";
                Result."Currency Code" := CalcEntry."Currency Code";
                Result."Adjustment Status" := Result."Adjustment Status"::Open;
                Result.Insert(true);
            until CalcEntry.Next() = 0;

        AuditMgt.Log('Recalculation Completed', Request."Request No.", '', Request."Agreement No.", '', Request."Agreement No.", '');
    end;
}
