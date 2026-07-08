table 50126 "BSB Agreement"
{
    Caption = 'Rebate Agreement';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Agreement List";
    LookupPageId = "BSB Agreement List";

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; "Agreement Type"; Enum "BSB Agreement Type") { Caption = 'Agreement Type'; }
        field(3; Status; Enum "BSB Agreement Status") { Caption = 'Status'; }
        field(4; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; }
        field(5; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(6; "Customer Group"; Code[20]) { Caption = 'Customer Group'; }
        field(7; "Valid From"; Date) { Caption = 'Valid From'; }
        field(8; "Valid To"; Date) { Caption = 'Valid To'; }
        field(9; "Country Code"; Code[10]) { Caption = 'Country Code'; }
        field(10; "Location Code"; Code[20]) { Caption = 'Location Code'; }
        field(11; "Dimension Filter"; Text[100]) { Caption = 'Dimension Filter'; }
        field(12; "Settlement Method"; Code[20]) { Caption = 'Settlement Method'; }
        field(13; "Posting Group"; Code[20]) { Caption = 'Posting Group'; }
        field(14; "Current Version"; Integer) { Caption = 'Current Version'; Editable = false; }
        field(15; "Approval Status"; Enum "BSB Approval Status") { Caption = 'Approval Status'; }
        field(16; "Reason Code"; Code[20]) { Caption = 'Reason Code'; }
        field(17; "Last Version At"; DateTime) { Caption = 'Last Version At'; Editable = false; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByStatus; Status, "Agreement Type") { }
    }
}
