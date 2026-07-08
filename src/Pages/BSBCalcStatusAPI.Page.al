page 50241 "BSB Calc Status API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'calculationStatus';
    EntitySetName = 'calculationStatuses';
    SourceTable = "BSB Calc Request";
    DelayedInsert = true;
    ODataKeyFields = "Request No.";
    Caption = 'Rebate Calculation Status API';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(requestNo; Rec."Request No.") { Caption = 'requestNo'; }
                field(requestType; Rec."Request Type") { Caption = 'requestType'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(agreementNo; Rec."Agreement No.") { Caption = 'agreementNo'; }
                field(startedAt; Rec."Started At") { Caption = 'startedAt'; }
                field(completedAt; Rec."Completed At") { Caption = 'completedAt'; }
            }
        }
    }
}
