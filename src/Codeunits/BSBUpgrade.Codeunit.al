codeunit 50313 "BSB Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        AuditMgt: Codeunit "BSB Audit Mgt";
    begin
        AuditMgt.Log('Upgrade Checked', CompanyName(), '', 'Schema preserved', '', CompanyName(), '');
    end;
}
