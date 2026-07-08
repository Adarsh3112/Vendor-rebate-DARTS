table 50130 "BSB Threshold"
{
    Caption = 'Rebate Threshold';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(2; "Rule No."; Code[20]) { Caption = 'Rule No.'; }
        field(3; "Threshold No."; Integer) { Caption = 'Threshold No.'; }
        field(4; "From Value"; Decimal) { Caption = 'From Value'; }
        field(5; "To Value"; Decimal) { Caption = 'To Value'; }
        field(6; Rate; Decimal) { Caption = 'Rate'; DecimalPlaces = 0 : 5; }
        field(7; Amount; Decimal) { Caption = 'Amount'; }
        field(8; Retroactive; Boolean) { Caption = 'Retroactive'; }
    }

    keys
    {
        key(PK; "Agreement No.", "Rule No.", "Threshold No.") { Clustered = true; }
    }
}
