table 50125 "BSB Process Chunk"
{
    Caption = 'Rebate Processing Chunk';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20]) { Caption = 'Request No.'; }
        field(2; "Chunk No."; Integer) { Caption = 'Chunk No.'; }
        field(3; Status; Enum "BSB Process Status") { Caption = 'Status'; }
        field(4; "Source Key From"; Text[100]) { Caption = 'Source Key From'; }
        field(5; "Source Key To"; Text[100]) { Caption = 'Source Key To'; }
        field(6; "Processed Count"; Integer) { Caption = 'Processed Count'; }
        field(7; "Error Count"; Integer) { Caption = 'Error Count'; }
        field(8; "Retry Count"; Integer) { Caption = 'Retry Count'; }
        field(9; "Started At"; DateTime) { Caption = 'Started At'; }
        field(10; "Completed At"; DateTime) { Caption = 'Completed At'; }
        field(11; "Last Error"; Text[250]) { Caption = 'Last Error'; }
    }

    keys
    {
        key(PK; "Request No.", "Chunk No.") { Clustered = true; }
        key(ByStatus; Status) { }
    }
}
