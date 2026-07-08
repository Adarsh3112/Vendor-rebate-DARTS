table 50131 "BSB Calc Request"
{
    Caption = 'Rebate Calculation Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20]) { Caption = 'Request No.'; }
        field(2; "Request Type"; Enum "BSB Request Type") { Caption = 'Request Type'; }
        field(3; Status; Enum "BSB Process Status") { Caption = 'Status'; }
        field(4; "Company Scope"; Text[100]) { Caption = 'Company Scope'; }
        field(5; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(6; "Party No."; Code[20]) { Caption = 'Party No.'; }
        field(7; "Date From"; Date) { Caption = 'Date From'; }
        field(8; "Date To"; Date) { Caption = 'Date To'; }
        field(9; "Recalc Mode"; Boolean) { Caption = 'Recalc Mode'; }
        field(10; "Requested By"; Code[50]) { Caption = 'Requested By'; }
        field(11; "Started At"; DateTime) { Caption = 'Started At'; }
        field(12; "Completed At"; DateTime) { Caption = 'Completed At'; }
        field(13; "Retry Count"; Integer) { Caption = 'Retry Count'; }
        field(14; "Idempotency Key"; Code[100]) { Caption = 'Idempotency Key'; }
    }

    keys
    {
        key(PK; "Request No.") { Clustered = true; }
        key(Idempotency; "Idempotency Key") { }
    }
}
