table 50135 "BSB Settlement Line"
{
    Caption = 'Rebate Settlement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Settlement No."; Code[20]) { Caption = 'Settlement No.'; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Accrual Entry No."; Integer) { Caption = 'Accrual Entry No.'; }
        field(4; Amount; Decimal) { Caption = 'Amount'; }
        field(5; "Adjustment Amount"; Decimal) { Caption = 'Adjustment Amount'; }
        field(6; "Reason Code"; Code[20]) { Caption = 'Reason Code'; }
        field(7; Closed; Boolean) { Caption = 'Closed'; }
    }

    keys
    {
        key(PK; "Settlement No.", "Line No.") { Clustered = true; }
        key(ByAccrual; "Accrual Entry No.") { }
    }
}
