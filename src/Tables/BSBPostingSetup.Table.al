table 50121 "BSB Posting Setup"
{
    Caption = 'Rebate Posting Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Posting Group"; Code[20]) { Caption = 'Posting Group'; }
        field(2; "Agreement Type"; Enum "BSB Agreement Type") { Caption = 'Agreement Type'; }
        field(3; "Accrual Account"; Code[20]) { Caption = 'Accrual Account'; }
        field(4; "Offset Account"; Code[20]) { Caption = 'Offset Account'; }
        field(5; "Settlement Account"; Code[20]) { Caption = 'Settlement Account'; }
        field(6; "Dimension Policy"; Code[20]) { Caption = 'Dimension Policy'; }
        field(7; "Currency Policy"; Code[20]) { Caption = 'Currency Policy'; }
        field(8; "Allow Reversal"; Boolean) { Caption = 'Allow Reversal'; InitValue = true; }
        field(9; "Last Modified By"; Code[50]) { Caption = 'Last Modified By'; Editable = false; }
        field(10; "Last Modified At"; DateTime) { Caption = 'Last Modified At'; Editable = false; }
    }

    keys
    {
        key(PK; "Posting Group", "Agreement Type") { Clustered = true; }
    }

    trigger OnModify()
    begin
        "Last Modified By" := CopyStr(UserId(), 1, MaxStrLen("Last Modified By"));
        "Last Modified At" := CurrentDateTime();
    end;
}
