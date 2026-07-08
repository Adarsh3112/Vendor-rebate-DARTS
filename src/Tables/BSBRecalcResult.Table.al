table 50136 "BSB Recalc Result"
{
    Caption = 'Rebate Recalculation Result';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Recalc Results";
    LookupPageId = "BSB Recalc Results";

    fields
    {
        field(1; "Result No."; Integer) { Caption = 'Result No.'; AutoIncrement = true; Editable = false; }
        field(2; "Request No."; Code[20]) { Caption = 'Request No.'; }
        field(3; "Original Entry No."; Integer) { Caption = 'Original Entry No.'; }
        field(4; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(5; "Old Version No."; Integer) { Caption = 'Old Version No.'; }
        field(6; "New Version No."; Integer) { Caption = 'New Version No.'; }
        field(7; "Old Amount"; Decimal) { Caption = 'Old Amount'; }
        field(8; "New Amount"; Decimal) { Caption = 'New Amount'; }
        field(9; "Delta Amount"; Decimal) { Caption = 'Delta Amount'; }
        field(10; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(11; "Adjustment Status"; Enum "BSB Entry Status") { Caption = 'Adjustment Status'; }
        field(12; "Posting Ref."; Code[50]) { Caption = 'Posting Ref.'; }
    }

    keys
    {
        key(PK; "Result No.") { Clustered = true; }
        key(ByRequest; "Request No.", "Agreement No.") { }
    }
}
