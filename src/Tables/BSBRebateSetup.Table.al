table 50120 "BSB Rebate Setup"
{
    Caption = 'Rebate Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(2; "Agreement Nos."; Code[20]) { Caption = 'Agreement Nos.'; }
        field(3; "Calc Request Nos."; Code[20]) { Caption = 'Calc Request Nos.'; }
        field(4; "Settlement Nos."; Code[20]) { Caption = 'Settlement Nos.'; }
        field(5; "Default Chunk Size"; Integer) { Caption = 'Default Chunk Size'; InitValue = 10000; }
        field(6; "Auto Post Accruals"; Boolean) { Caption = 'Auto Post Accruals'; }
        field(7; "Audit Required"; Boolean) { Caption = 'Audit Required'; InitValue = true; }
        field(8; "Default Reason Code"; Code[20]) { Caption = 'Default Reason Code'; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
