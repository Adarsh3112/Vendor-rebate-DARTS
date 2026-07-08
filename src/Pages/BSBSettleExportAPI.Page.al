page 50242 "BSB Settle Export API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'settlementExport';
    EntitySetName = 'settlementExports';
    SourceTable = "BSB Settlement Hdr";
    DelayedInsert = true;
    ODataKeyFields = "Settlement No.";
    Caption = 'Rebate Settlement Export API';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(settlementNo; Rec."Settlement No.") { Caption = 'settlementNo'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(agreementNo; Rec."Agreement No.") { Caption = 'agreementNo'; }
                field(partyNo; Rec."Party No.") { Caption = 'partyNo'; }
                field(totalAmount; Rec."Total Amount") { Caption = 'totalAmount'; }
                field(posted; Rec.Posted) { Caption = 'posted'; }
            }
        }
    }
}
