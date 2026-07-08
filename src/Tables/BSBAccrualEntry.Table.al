table 50133 "BSB Accrual Entry"
{
    Caption = 'Rebate Accrual Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Accrual Entries";
    LookupPageId = "BSB Accrual Entries";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; Editable = false; }
        field(2; "Calc Entry No."; Integer) { Caption = 'Calc Entry No.'; }
        field(3; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(4; "Version No."; Integer) { Caption = 'Version No.'; }
        field(5; Company; Text[30]) { Caption = 'Company'; }
        field(6; "Party Type"; Enum "BSB Agreement Type") { Caption = 'Party Type'; }
        field(7; "Party No."; Code[20]) { Caption = 'Party No.'; }
        field(8; Period; Code[20]) { Caption = 'Period'; }
        field(9; Amount; Decimal) { Caption = 'Amount'; }
        field(10; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(11; "Exchange Rate"; Decimal) { Caption = 'Exchange Rate'; DecimalPlaces = 0 : 8; }
        field(12; Status; Enum "BSB Entry Status") { Caption = 'Status'; }
        field(13; "Posting Ref."; Code[50]) { Caption = 'Posting Ref.'; }
        field(14; "Reversal Ref."; Code[50]) { Caption = 'Reversal Ref.'; }
        field(15; "Open Amount"; Decimal) { Caption = 'Open Amount'; }
        field(16; "Idempotency Key"; Code[100]) { Caption = 'Idempotency Key'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByAgreement; "Agreement No.", Period, Status) { }
        key(Idempotency; "Idempotency Key") { }
    }
}
