table 50134 "BSB Settlement Hdr"
{
    Caption = 'Rebate Settlement Header';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Settlement List";
    LookupPageId = "BSB Settlement List";

    fields
    {
        field(1; "Settlement No."; Code[20]) { Caption = 'Settlement No.'; }
        field(2; Status; Enum "BSB Process Status") { Caption = 'Status'; }
        field(3; Company; Text[30]) { Caption = 'Company'; }
        field(4; "Party Type"; Enum "BSB Agreement Type") { Caption = 'Party Type'; }
        field(5; "Party No."; Code[20]) { Caption = 'Party No.'; }
        field(6; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(7; Period; Code[20]) { Caption = 'Period'; }
        field(8; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(9; "Total Amount"; Decimal) { Caption = 'Total Amount'; }
        field(10; "Adjustment Amount"; Decimal) { Caption = 'Adjustment Amount'; }
        field(11; "Approval Status"; Enum "BSB Approval Status") { Caption = 'Approval Status'; }
        field(12; "Posted"; Boolean) { Caption = 'Posted'; }
        field(13; "External Ref. ID"; Code[80]) { Caption = 'External Ref. ID'; }
    }

    keys
    {
        key(PK; "Settlement No.") { Clustered = true; }
    }
}
