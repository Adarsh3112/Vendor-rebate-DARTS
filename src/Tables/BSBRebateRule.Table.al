table 50129 "BSB Rebate Rule"
{
    Caption = 'Rebate Rule';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "BSB Agreement"; }
        field(2; "Rule No."; Code[20]) { Caption = 'Rule No.'; }
        field(3; "Rule Type"; Code[30]) { Caption = 'Rule Type'; }
        field(4; Basis; Enum "BSB Rule Basis") { Caption = 'Basis'; }
        field(5; "Calc Method"; Enum "BSB Calc Method") { Caption = 'Calc Method'; }
        field(6; Priority; Integer) { Caption = 'Priority'; }
        field(7; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(8; "Effective From"; Date) { Caption = 'Effective From'; }
        field(9; "Effective To"; Date) { Caption = 'Effective To'; }
        field(10; "Include Criteria"; Text[100]) { Caption = 'Include Criteria'; }
        field(11; "Exclude Criteria"; Text[100]) { Caption = 'Exclude Criteria'; }
        field(12; "Formula Ref."; Code[30]) { Caption = 'Formula Ref.'; }
        field(13; Active; Boolean) { Caption = 'Active'; InitValue = true; }
    }

    keys
    {
        key(PK; "Agreement No.", "Rule No.") { Clustered = true; }
        key(ByPriority; "Agreement No.", Priority) { }
    }
}
