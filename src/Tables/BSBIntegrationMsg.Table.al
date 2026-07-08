table 50124 "BSB Integration Msg"
{
    Caption = 'Rebate Integration Message';
    DataClassification = CustomerContent;
    DrillDownPageId = "BSB Integration Log";
    LookupPageId = "BSB Integration Log";

    fields
    {
        field(1; "Message No."; Integer) { Caption = 'Message No.'; AutoIncrement = true; Editable = false; }
        field(2; Direction; Enum "BSB Msg Direction") { Caption = 'Direction'; }
        field(3; "Message Type"; Code[30]) { Caption = 'Message Type'; }
        field(4; "External Ref. ID"; Code[80]) { Caption = 'External Ref. ID'; }
        field(5; Status; Enum "BSB Process Status") { Caption = 'Status'; }
        field(6; "Related Record"; Text[100]) { Caption = 'Related Record'; }
        field(7; "Request Payload"; Text[250]) { Caption = 'Request Payload'; }
        field(8; "Response Payload"; Text[250]) { Caption = 'Response Payload'; }
        field(9; "Retry Count"; Integer) { Caption = 'Retry Count'; }
        field(10; "Last Error"; Text[250]) { Caption = 'Last Error'; }
        field(11; "Created At"; DateTime) { Caption = 'Created At'; }
        field(12; "Completed At"; DateTime) { Caption = 'Completed At'; }
    }

    keys
    {
        key(PK; "Message No.") { Clustered = true; }
        key(External; Direction, "Message Type", "External Ref. ID") { }
    }
}
