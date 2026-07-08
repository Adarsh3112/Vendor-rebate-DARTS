page 50240 "BSB Agr Import API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'agreementImport';
    EntitySetName = 'agreementImports';
    SourceTable = "BSB Agreement";
    DelayedInsert = true;
    ODataKeyFields = "No.";
    Caption = 'Rebate Agreement Import API';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no; Rec."No.") { Caption = 'no'; }
                field(agreementType; Rec."Agreement Type") { Caption = 'agreementType'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(vendorNo; Rec."Vendor No.") { Caption = 'vendorNo'; }
                field(customerNo; Rec."Customer No.") { Caption = 'customerNo'; }
                field(validFrom; Rec."Valid From") { Caption = 'validFrom'; }
                field(validTo; Rec."Valid To") { Caption = 'validTo'; }
                field(postingGroup; Rec."Posting Group") { Caption = 'postingGroup'; }
            }
        }
    }
}
