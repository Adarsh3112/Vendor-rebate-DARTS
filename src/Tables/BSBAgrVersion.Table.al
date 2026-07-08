table 50128 "BSB Agr Version"
{
    Caption = 'Rebate Agreement Version';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Agr Versions";
    LookupPageId = "BSB Agr Versions";

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "BSB Agreement"; }
        field(2; "Version No."; Integer) { Caption = 'Version No.'; }
        field(3; "Effective Date"; Date) { Caption = 'Effective Date'; }
        field(4; "Created At"; DateTime) { Caption = 'Created At'; Editable = false; }
        field(5; "Created By"; Code[50]) { Caption = 'Created By'; Editable = false; }
        field(6; "Change Reason"; Code[20]) { Caption = 'Change Reason'; }
        field(7; "Term Summary"; Text[250]) { Caption = 'Term Summary'; }
        field(8; Status; Enum "BSB Agreement Status") { Caption = 'Status'; }
        field(9; "Used In Calc."; Boolean) { Caption = 'Used In Calc.'; Editable = false; }
    }

    keys
    {
        key(PK; "Agreement No.", "Version No.") { Clustered = true; }
    }
}
