page 50243 "BSB Audit Export API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'auditExport';
    EntitySetName = 'auditExports';
    SourceTable = "BSB Audit Entry";
    DelayedInsert = true;
    ODataKeyFields = "Entry No.";
    Caption = 'Rebate Audit Export API';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(entryNo; Rec."Entry No.") { Caption = 'entryNo'; }
                field(dateTime; Rec."Date Time") { Caption = 'dateTime'; }
                field(userId; Rec."User ID") { Caption = 'userId'; }
                field(action; Rec.Action) { Caption = 'action'; }
                field(recordIdText; Rec."Record ID Text") { Caption = 'recordIdText'; }
                field(oldValue; Rec."Old Value") { Caption = 'oldValue'; }
                field(newValue; Rec."New Value") { Caption = 'newValue'; }
                field(reasonCode; Rec."Reason Code") { Caption = 'reasonCode'; }
            }
        }
    }
}
