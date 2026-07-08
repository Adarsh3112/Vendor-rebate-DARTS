table 50100 "Rebate Setup"
{
    Caption = 'Rebate Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(2; "Agreement Nos."; Code[20]) { Caption = 'Agreement Nos.'; TableRelation = "No. Series"; }
        field(3; "Calculation Request Nos."; Code[20]) { Caption = 'Calculation Request Nos.'; TableRelation = "No. Series"; }
        field(4; "Settlement Nos."; Code[20]) { Caption = 'Settlement Nos.'; TableRelation = "No. Series"; }
        field(5; "Integration Secret Ref."; Text[250]) { Caption = 'Integration Secret Reference'; ExtendedDatatype = Masked; }
    }

    keys { key(PK; "Primary Key") { Clustered = true; } }
}

table 50101 "Rebate Posting Setup"
{
    Caption = 'Rebate Posting Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement Type"; Enum "Rebate Agreement Type") { Caption = 'Agreement Type'; }
        field(2; "Posting Group"; Code[20]) { Caption = 'Posting Group'; }
        field(3; "Currency Code"; Code[10]) { Caption = 'Currency Code'; TableRelation = Currency; }
        field(4; "Entry Type"; Enum "Rebate Ledger Entry Type") { Caption = 'Entry Type'; }
        field(5; "Expense Account No."; Code[20]) { Caption = 'Expense Account No.'; TableRelation = "G/L Account"; }
        field(6; "Liability Account No."; Code[20]) { Caption = 'Liability Account No.'; TableRelation = "G/L Account"; }
        field(7; "Settlement Output"; Enum "Rebate Settlement Output") { Caption = 'Settlement Output'; }
    }

    keys { key(PK; "Agreement Type", "Posting Group", "Currency Code", "Entry Type") { Clustered = true; } }
}

table 50102 "Rebate Agreement Header"
{
    Caption = 'Rebate Agreement Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; "Agreement Type"; Enum "Rebate Agreement Type") { Caption = 'Agreement Type'; }
        field(3; Status; Enum "Rebate Agreement Status") { Caption = 'Status'; Editable = false; }
        field(4; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; TableRelation = Vendor; }
        field(5; "Customer No."; Code[20]) { Caption = 'Customer No.'; TableRelation = Customer; }
        field(6; "Customer Price Group"; Code[10]) { Caption = 'Customer Price Group'; TableRelation = "Customer Price Group"; }
        field(7; "Starting Date"; Date) { Caption = 'Starting Date'; }
        field(8; "Ending Date"; Date) { Caption = 'Ending Date'; }
        field(9; "Currency Code"; Code[10]) { Caption = 'Currency Code'; TableRelation = Currency; }
        field(10; "Posting Group"; Code[20]) { Caption = 'Posting Group'; }
        field(11; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; TableRelation = "Country/Region"; }
        field(12; "Location Code"; Code[10]) { Caption = 'Location Code'; TableRelation = Location; }
        field(13; "Global Dimension 1 Code"; Code[20]) { Caption = 'Global Dimension 1 Code'; TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1)); }
        field(14; "Global Dimension 2 Code"; Code[20]) { Caption = 'Global Dimension 2 Code'; TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2)); }
        field(15; "Active Version No."; Integer) { Caption = 'Active Version No.'; Editable = false; }
        field(16; "No. Series"; Code[20]) { Caption = 'No. Series'; TableRelation = "No. Series"; }
        field(17; "Settlement Method"; Enum "Rebate Settlement Output") { Caption = 'Settlement Method'; }
        field(18; "Department Code"; Code[20]) { Caption = 'Department Code'; }
        field(19; "Region Code"; Code[20]) { Caption = 'Region Code'; }
        field(20; "Last Modified DateTime"; DateTime) { Caption = 'Last Modified DateTime'; Editable = false; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(TypeStatus; "Agreement Type", Status, "Vendor No.", "Customer No.") { }
    }

    trigger OnInsert()
    var
        RebateSetup: Record "Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.Get();
            RebateSetup.TestField("Agreement Nos.");
            "No. Series" := RebateSetup."Agreement Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        Status := Status::Draft;
        "Last Modified DateTime" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        "Last Modified DateTime" := CurrentDateTime();
    end;
}

table 50103 "Rebate Agreement Line"
{
    Caption = 'Rebate Agreement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "Rebate Agreement Header"; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item; }
        field(4; "Item Category Code"; Code[20]) { Caption = 'Item Category Code'; TableRelation = "Item Category"; }
        field(5; "Location Code"; Code[10]) { Caption = 'Location Code'; TableRelation = Location; }
        field(6; "Include"; Boolean) { Caption = 'Include'; InitValue = true; }
        field(7; "Dimension 1 Code"; Code[20]) { Caption = 'Dimension 1 Code'; }
        field(8; "Dimension 2 Code"; Code[20]) { Caption = 'Dimension 2 Code'; }
    }

    keys { key(PK; "Agreement No.", "Line No.") { Clustered = true; } }
}

table 50104 "Rebate Agreement Version"
{
    Caption = 'Rebate Agreement Version';
    DataClassification = CustomerContent;
    DrillDownPageId = "Rebate Agreement Versions";
    LookupPageId = "Rebate Agreement Versions";

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "Rebate Agreement Header"; }
        field(2; "Version No."; Integer) { Caption = 'Version No.'; }
        field(3; "Agreement Type"; Enum "Rebate Agreement Type") { Caption = 'Agreement Type'; }
        field(4; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; }
        field(5; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(6; "Starting Date"; Date) { Caption = 'Starting Date'; }
        field(7; "Ending Date"; Date) { Caption = 'Ending Date'; }
        field(8; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(9; "Posting Group"; Code[20]) { Caption = 'Posting Group'; }
        field(10; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
        field(11; "Created By"; Code[50]) { Caption = 'Created By'; }
        field(12; "Source Status"; Enum "Rebate Agreement Status") { Caption = 'Source Status'; }
    }

    keys { key(PK; "Agreement No.", "Version No.") { Clustered = true; } }
}

table 50105 "Rebate Rule"
{
    Caption = 'Rebate Rule';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "Rebate Agreement Header"; }
        field(2; "Rule No."; Integer) { Caption = 'Rule No.'; }
        field(3; Basis; Enum "Rebate Rule Basis") { Caption = 'Basis'; }
        field(4; "Calculation Method"; Enum "Rebate Calculation Method") { Caption = 'Calculation Method'; }
        field(5; "Percent"; Decimal) { Caption = 'Percent'; DecimalPlaces = 0 : 5; }
        field(6; "Fixed Amount"; Decimal) { Caption = 'Fixed Amount'; }
        field(7; "Minimum Amount"; Decimal) { Caption = 'Minimum Amount'; }
        field(8; "Maximum Amount"; Decimal) { Caption = 'Maximum Amount'; }
        field(9; "Priority"; Integer) { Caption = 'Priority'; }
        field(10; "Formula Reference"; Code[50]) { Caption = 'Formula Reference'; }
        field(11; "Excluded Item Category Code"; Code[20]) { Caption = 'Excluded Item Category Code'; TableRelation = "Item Category"; }
        field(12; "Starting Date"; Date) { Caption = 'Starting Date'; }
        field(13; "Ending Date"; Date) { Caption = 'Ending Date'; }
    }

    keys
    {
        key(PK; "Agreement No.", "Rule No.") { Clustered = true; }
        key(Priority; "Agreement No.", Priority) { }
    }
}

table 50106 "Rebate Threshold"
{
    Caption = 'Rebate Threshold';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(2; "Rule No."; Integer) { Caption = 'Rule No.'; }
        field(3; "Line No."; Integer) { Caption = 'Line No.'; }
        field(4; "Minimum Value"; Decimal) { Caption = 'Minimum Value'; }
        field(5; "Maximum Value"; Decimal) { Caption = 'Maximum Value'; }
        field(6; "Percent"; Decimal) { Caption = 'Percent'; DecimalPlaces = 0 : 5; }
        field(7; "Amount"; Decimal) { Caption = 'Amount'; }
    }

    keys { key(PK; "Agreement No.", "Rule No.", "Line No.") { Clustered = true; } }
}

table 50107 "Rebate Calculation Request"
{
    Caption = 'Rebate Calculation Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "Rebate Agreement Header"; }
        field(3; "Company Name"; Text[30]) { Caption = 'Company Name'; }
        field(4; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; TableRelation = Vendor; }
        field(5; "Customer No."; Code[20]) { Caption = 'Customer No.'; TableRelation = Customer; }
        field(6; "Starting Date"; Date) { Caption = 'Starting Date'; }
        field(7; "Ending Date"; Date) { Caption = 'Ending Date'; }
        field(8; Status; Enum "Rebate Request Status") { Caption = 'Status'; }
        field(9; "Recalculation Mode"; Boolean) { Caption = 'Recalculation Mode'; }
        field(10; "Processed Count"; Integer) { Caption = 'Processed Count'; }
        field(11; "Failed Count"; Integer) { Caption = 'Failed Count'; }
        field(12; "Last Source Key"; Text[250]) { Caption = 'Last Source Key'; }
        field(13; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
        field(14; "Completed DateTime"; DateTime) { Caption = 'Completed DateTime'; }
        field(15; "No. Series"; Code[20]) { Caption = 'No. Series'; TableRelation = "No. Series"; }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        RebateSetup: Record "Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.Get();
            RebateSetup.TestField("Calculation Request Nos.");
            "No. Series" := RebateSetup."Calculation Request Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        if "Company Name" = '' then
            "Company Name" := CopyStr(CompanyName(), 1, MaxStrLen("Company Name"));
        Status := Status::Pending;
        "Created DateTime" := CurrentDateTime();
    end;
}

table 50108 "Rebate Calculation Entry"
{
    Caption = 'Rebate Calculation Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Request No."; Code[20]) { Caption = 'Request No.'; TableRelation = "Rebate Calculation Request"; }
        field(3; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(4; "Agreement Version No."; Integer) { Caption = 'Agreement Version No.'; }
        field(5; "Rule No."; Integer) { Caption = 'Rule No.'; }
        field(6; "Source Type"; Enum "Rebate Source Type") { Caption = 'Source Type'; }
        field(7; "Source Document No."; Code[20]) { Caption = 'Source Document No.'; }
        field(8; "Source Line No."; Integer) { Caption = 'Source Line No.'; }
        field(9; "Source Key"; Text[250]) { Caption = 'Source Key'; }
        field(10; Eligible; Boolean) { Caption = 'Eligible'; }
        field(11; "Rejection Reason"; Text[250]) { Caption = 'Rejection Reason'; }
        field(12; "Source Amount"; Decimal) { Caption = 'Source Amount'; }
        field(13; Quantity; Decimal) { Caption = 'Quantity'; }
        field(14; "Rebate Amount"; Decimal) { Caption = 'Rebate Amount'; }
        field(15; "Currency Code"; Code[10]) { Caption = 'Currency Code'; TableRelation = Currency; }
        field(16; "Exchange Rate"; Decimal) { Caption = 'Exchange Rate'; DecimalPlaces = 0 : 10; }
        field(17; "Exchange Rate Date"; Date) { Caption = 'Exchange Rate Date'; }
        field(18; "Amount (LCY)"; Decimal) { Caption = 'Amount (LCY)'; }
        field(19; "Dimension Set ID"; Integer) { Caption = 'Dimension Set ID'; }
        field(20; "Global Dimension 1 Code"; Code[20]) { Caption = 'Global Dimension 1 Code'; }
        field(21; "Global Dimension 2 Code"; Code[20]) { Caption = 'Global Dimension 2 Code'; }
        field(22; Posted; Boolean) { Caption = 'Posted'; }
        field(23; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
        field(24; "External Idempotency Key"; Text[250]) { Caption = 'External Idempotency Key'; }
        field(25; "Original Entry No."; Integer) { Caption = 'Original Entry No.'; }
        field(26; "Old Amount"; Decimal) { Caption = 'Old Amount'; }
        field(27; "New Amount"; Decimal) { Caption = 'New Amount'; }
        field(28; "Delta Amount"; Decimal) { Caption = 'Delta Amount'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(SourceKey; "Request No.", "Source Key", "Agreement No.", "Agreement Version No.", "Rule No.") { }
        key(OpenPosting; Posted, Eligible, "Agreement No.") { }
    }

    trigger OnInsert()
    begin
        "Created DateTime" := CurrentDateTime();
    end;
}

table 50109 "Rebate Accrual Entry"
{
    Caption = 'Rebate Accrual Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Calculation Entry No."; Integer) { Caption = 'Calculation Entry No.'; TableRelation = "Rebate Calculation Entry"; }
        field(3; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(4; "Agreement Version No."; Integer) { Caption = 'Agreement Version No.'; }
        field(5; "Entry Type"; Enum "Rebate Ledger Entry Type") { Caption = 'Entry Type'; }
        field(6; Status; Enum "Rebate Entry Status") { Caption = 'Status'; }
        field(7; Amount; Decimal) { Caption = 'Amount'; }
        field(8; "Amount (LCY)"; Decimal) { Caption = 'Amount (LCY)'; }
        field(9; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(10; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(11; "G/L Entry No."; Integer) { Caption = 'G/L Entry No.'; }
        field(12; "Dimension Set ID"; Integer) { Caption = 'Dimension Set ID'; }
        field(13; "Global Dimension 1 Code"; Code[20]) { Caption = 'Global Dimension 1 Code'; }
        field(14; "Global Dimension 2 Code"; Code[20]) { Caption = 'Global Dimension 2 Code'; }
        field(15; "Closed by Settlement No."; Code[20]) { Caption = 'Closed by Settlement No.'; }
        field(16; "Remaining Amount"; Decimal) { Caption = 'Remaining Amount'; }
        field(17; "Original Entry No."; Integer) { Caption = 'Original Entry No.'; }
        field(18; "Posting Command Key"; Text[250]) { Caption = 'Posting Command Key'; }
        field(19; "Reason Code"; Code[20]) { Caption = 'Reason Code'; TableRelation = "Reason Code"; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Open; Status, "Agreement No.", "Currency Code") { }
        key(Command; "Posting Command Key") { }
    }

    trigger OnModify()
    begin
        if xRec.Status in [xRec.Status::Posted, xRec.Status::Closed, xRec.Status::Reversed] then
            if Rec.Status = xRec.Status then
                Error('Posted rebate accrual entries cannot be modified directly.');
    end;
}

table 50110 "Rebate Settlement Header"
{
    Caption = 'Rebate Settlement Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; TableRelation = "Rebate Agreement Header"; }
        field(3; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; TableRelation = Vendor; }
        field(4; "Customer No."; Code[20]) { Caption = 'Customer No.'; TableRelation = Customer; }
        field(5; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(6; Status; Enum "Rebate Settlement Status") { Caption = 'Status'; }
        field(7; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(8; Amount; Decimal) { Caption = 'Amount'; Editable = false; }
        field(9; "Output Type"; Enum "Rebate Settlement Output") { Caption = 'Output Type'; }
        field(10; "No. Series"; Code[20]) { Caption = 'No. Series'; TableRelation = "No. Series"; }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        RebateSetup: Record "Rebate Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            RebateSetup.Get();
            RebateSetup.TestField("Settlement Nos.");
            "No. Series" := RebateSetup."Settlement Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        Status := Status::Open;
    end;
}

table 50111 "Rebate Settlement Line"
{
    Caption = 'Rebate Settlement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Settlement No."; Code[20]) { Caption = 'Settlement No.'; TableRelation = "Rebate Settlement Header"; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Accrual Entry No."; Integer) { Caption = 'Accrual Entry No.'; TableRelation = "Rebate Accrual Entry"; }
        field(4; "Original Amount"; Decimal) { Caption = 'Original Amount'; }
        field(5; "Settlement Amount"; Decimal) { Caption = 'Settlement Amount'; }
        field(6; "Adjustment Reason Code"; Code[20]) { Caption = 'Adjustment Reason Code'; TableRelation = "Reason Code"; }
        field(7; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(8; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
    }

    keys { key(PK; "Settlement No.", "Line No.") { Clustered = true; } }

    trigger OnModify()
    var
        AuditMgt: Codeunit "Rebate Audit Mgt.";
    begin
        if "Settlement Amount" <> xRec."Settlement Amount" then
            AuditMgt.Log('Settlement Line Adjusted', Database::"Rebate Settlement Line", "Settlement No.", Format(xRec."Settlement Amount"), Format("Settlement Amount"), "Adjustment Reason Code");
    end;
}

table 50112 "Rebate Audit Entry"
{
    Caption = 'Rebate Audit Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
        field(3; "User ID"; Code[50]) { Caption = 'User ID'; }
        field(4; Action; Text[100]) { Caption = 'Action'; }
        field(5; "Table ID"; Integer) { Caption = 'Table ID'; }
        field(6; "Record ID Text"; Text[250]) { Caption = 'Record ID Text'; }
        field(7; "Old Value"; Text[250]) { Caption = 'Old Value'; }
        field(8; "New Value"; Text[250]) { Caption = 'New Value'; }
        field(9; "Reason Code"; Code[20]) { Caption = 'Reason Code'; }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }

    trigger OnModify()
    begin
        Error('Audit entries cannot be modified.');
    end;

    trigger OnDelete()
    begin
        Error('Audit entries cannot be deleted.');
    end;
}

table 50113 "Rebate Job Log"
{
    Caption = 'Rebate Job Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Request No."; Code[20]) { Caption = 'Request No.'; }
        field(3; "Chunk No."; Integer) { Caption = 'Chunk No.'; }
        field(4; Status; Enum "Rebate Request Status") { Caption = 'Status'; }
        field(5; "Resume Key"; Text[250]) { Caption = 'Resume Key'; }
        field(6; "Processed Count"; Integer) { Caption = 'Processed Count'; }
        field(7; "Failed Count"; Integer) { Caption = 'Failed Count'; }
        field(8; "Error Category"; Enum "Rebate Error Category") { Caption = 'Error Category'; }
        field(9; "User Message"; Text[250]) { Caption = 'User Message'; }
        field(10; "Technical Details"; Text[2048]) { Caption = 'Technical Details'; }
        field(11; "Retry Eligible"; Boolean) { Caption = 'Retry Eligible'; }
        field(12; "Related Record"; Text[250]) { Caption = 'Related Record'; }
        field(13; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } key(Request; "Request No.", "Chunk No.") { } }
}

table 50114 "Rebate Integration Log"
{
    Caption = 'Rebate Integration Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "External Reference ID"; Code[100]) { Caption = 'External Reference ID'; }
        field(3; Direction; Option) { Caption = 'Direction'; OptionMembers = Inbound,Outbound; }
        field(4; Operation; Text[100]) { Caption = 'Operation'; }
        field(5; Status; Enum "Rebate Integration Status") { Caption = 'Status'; }
        field(6; "Error Category"; Enum "Rebate Error Category") { Caption = 'Error Category'; }
        field(7; "User Message"; Text[250]) { Caption = 'User Message'; }
        field(8; "Technical Details"; Text[2048]) { Caption = 'Technical Details'; }
        field(9; "Retry Eligible"; Boolean) { Caption = 'Retry Eligible'; }
        field(10; "Related Record"; Text[250]) { Caption = 'Related Record'; }
        field(11; "Created DateTime"; DateTime) { Caption = 'Created DateTime'; }
        field(12; "Credential Secret Ref."; Text[250]) { Caption = 'Credential Secret Ref.'; ExtendedDatatype = Masked; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ExternalRef; "External Reference ID", Operation) { }
    }
}

table 50115 "Rebate Reconciliation Entry"
{
    Caption = 'Rebate Reconciliation Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Calculation Entry No."; Integer) { Caption = 'Calculation Entry No.'; }
        field(3; "Accrual Entry No."; Integer) { Caption = 'Accrual Entry No.'; }
        field(4; "Settlement No."; Code[20]) { Caption = 'Settlement No.'; }
        field(5; "G/L Entry No."; Integer) { Caption = 'G/L Entry No.'; }
        field(6; "Calculated Amount"; Decimal) { Caption = 'Calculated Amount'; }
        field(7; "Posted Amount"; Decimal) { Caption = 'Posted Amount'; }
        field(8; Variance; Decimal) { Caption = 'Variance'; }
        field(9; Status; Enum "Rebate Entry Status") { Caption = 'Status'; }
        field(10; "Agreement No."; Code[20]) { Caption = 'Agreement No.'; }
        field(11; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } key(Agreement; "Agreement No.", Status, "Currency Code") { } }
}
