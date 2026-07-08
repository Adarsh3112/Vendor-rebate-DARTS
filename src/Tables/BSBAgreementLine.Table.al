table 50127 "BSB Agreement Line"
{
    Caption = 'Rebate Agreement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "BSB Agreement"; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Party Type"; Enum "BSB Agreement Type") { Caption = 'Party Type'; }
        field(4; "Party No."; Code[20]) { Caption = 'Party No.'; }
        field(5; "Item No."; Code[20]) { Caption = 'Item No.'; }
        field(6; "Item Category"; Code[20]) { Caption = 'Item Category'; }
        field(7; "Location Code"; Code[20]) { Caption = 'Location Code'; }
        field(8; "Country Code"; Code[10]) { Caption = 'Country Code'; }
        field(9; "Dimension Filter"; Text[100]) { Caption = 'Dimension Filter'; }
        field(10; "Exclude"; Boolean) { Caption = 'Exclude'; }
        field(11; "Effective From"; Date) { Caption = 'Effective From'; }
        field(12; "Effective To"; Date) { Caption = 'Effective To'; }
    }

    keys
    {
        key(PK; "Agreement No.", "Line No.") { Clustered = true; }
    }
}
