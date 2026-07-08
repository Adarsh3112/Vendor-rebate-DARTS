table 50132 "BSB Calc Entry"
{
    Caption = 'Rebate Calculation Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Calc Entries";
    LookupPageId = "BSB Calc Entries";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; Editable = false; }
        field(2; "Request No."; Code[20]) { Caption = 'Request No.'; }
        field(3; "Source Company"; Text[30]) { Caption = 'Source Company'; }
        field(4; "Source Doc. Type"; Code[30]) { Caption = 'Source Doc. Type'; }
        field(5; "Source Doc. No."; Code[20]) { Caption = 'Source Doc. No.'; }
        field(6; "Source Line No."; Integer) { Caption = 'Source Line No.'; }
        field(7; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(8; "Version No."; Integer) { Caption = 'Version No.'; }
        field(9; "Rule No."; Code[20]) { Caption = 'Rule No.'; }
        field(10; "Eligibility Status"; Enum "BSB Eligibility Status") { Caption = 'Eligibility Status'; }
        field(11; Reason; Text[100]) { Caption = 'Reason'; }
        field(12; "Basis Amount"; Decimal) { Caption = 'Basis Amount'; }
        field(13; Quantity; Decimal) { Caption = 'Quantity'; }
        field(14; "Calculated Amount"; Decimal) { Caption = 'Calculated Amount'; }
        field(15; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(16; "Exchange Rate"; Decimal) { Caption = 'Exchange Rate'; DecimalPlaces = 0 : 8; }
        field(17; "Dimension Values"; Text[100]) { Caption = 'Dimension Values'; }
        field(18; "Idempotency Key"; Code[100]) { Caption = 'Idempotency Key'; }
        field(19; Posted; Boolean) { Caption = 'Posted'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Idempotency; "Idempotency Key") { }
        key(ByRequest; "Request No.", "Agreement No.") { }
    }
}
