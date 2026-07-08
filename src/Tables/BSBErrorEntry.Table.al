table 50123 "BSB Error Entry"
{
    Caption = 'Rebate Error Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; Editable = false; }
        field(2; Category; Enum "BSB Error Category") { Caption = 'Category'; }
        field(3; "User Message"; Text[250]) { Caption = 'User Message'; }
        field(4; "Technical Details"; Text[250]) { Caption = 'Technical Details'; }
        field(5; "Related Record"; Text[100]) { Caption = 'Related Record'; }
        field(6; "Retry Eligible"; Boolean) { Caption = 'Retry Eligible'; }
        field(7; "Date Time"; DateTime) { Caption = 'Date Time'; }
        field(8; "User ID"; Code[50]) { Caption = 'User ID'; }
        field(9; Status; Enum "BSB Process Status") { Caption = 'Status'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByCategory; Category, Status) { }
    }
}
