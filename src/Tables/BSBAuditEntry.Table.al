table 50122 "BSB Audit Entry"
{
    Caption = 'Rebate Audit Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Audit Entries";
    LookupPageId = "BSB Audit Entries";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; Editable = false; }
        field(2; "Date Time"; DateTime) { Caption = 'Date Time'; Editable = false; }
        field(3; "User ID"; Code[50]) { Caption = 'User ID'; Editable = false; }
        field(4; Action; Text[80]) { Caption = 'Action'; Editable = false; }
        field(5; "Record ID Text"; Text[250]) { Caption = 'Record ID Text'; Editable = false; }
        field(6; "Old Value"; Text[250]) { Caption = 'Old Value'; Editable = false; }
        field(7; "New Value"; Text[250]) { Caption = 'New Value'; Editable = false; }
        field(8; "Reason Code"; Code[20]) { Caption = 'Reason Code'; Editable = false; }
        field(9; "Source Reference"; Text[100]) { Caption = 'Source Reference'; Editable = false; }
        field(10; "Technical Details"; Text[250]) { Caption = 'Technical Details'; Editable = false; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByDate; "Date Time") { }
    }
}
