enum 50100 "Rebate Agreement Type"
{
    Extensible = true;
    value(0; "Vendor Rebate") { Caption = 'Vendor Rebate'; }
    value(1; "Customer Incentive") { Caption = 'Customer Incentive'; }
}

enum 50101 "Rebate Agreement Status"
{
    Extensible = true;
    value(0; Draft) { Caption = 'Draft'; }
    value(1; Submitted) { Caption = 'Submitted'; }
    value(2; Approved) { Caption = 'Approved'; }
    value(3; Active) { Caption = 'Active'; }
    value(4; Suspended) { Caption = 'Suspended'; }
    value(5; Expired) { Caption = 'Expired'; }
    value(6; Rejected) { Caption = 'Rejected'; }
    value(7; Revision) { Caption = 'Revision'; }
}

enum 50102 "Rebate Rule Basis"
{
    Extensible = true;
    value(0; "Purchase Amount") { Caption = 'Purchase Amount'; }
    value(1; "Sales Amount") { Caption = 'Sales Amount'; }
    value(2; Quantity) { Caption = 'Quantity'; }
    value(3; Margin) { Caption = 'Margin'; }
    value(4; "Payment Date") { Caption = 'Payment Date'; }
    value(5; "Invoice Date") { Caption = 'Invoice Date'; }
    value(6; "Shipment Date") { Caption = 'Shipment Date'; }
}

enum 50103 "Rebate Calculation Method"
{
    Extensible = true;
    value(0; Percentage) { Caption = 'Percentage'; }
    value(1; "Fixed Amount") { Caption = 'Fixed Amount'; }
    value(2; "Tiered Percentage") { Caption = 'Tiered Percentage'; }
    value(3; "Slab Amount") { Caption = 'Slab Amount'; }
    value(4; "Formula Reference") { Caption = 'Formula Reference'; }
    value(5; Growth) { Caption = 'Growth'; }
}

enum 50104 "Rebate Request Status"
{
    Extensible = true;
    value(0; Pending) { Caption = 'Pending'; }
    value(1; "In Process") { Caption = 'In Process'; }
    value(2; Completed) { Caption = 'Completed'; }
    value(3; Failed) { Caption = 'Failed'; }
}

enum 50105 "Rebate Entry Status"
{
    Extensible = true;
    value(0; Open) { Caption = 'Open'; }
    value(1; Posted) { Caption = 'Posted'; }
    value(2; Closed) { Caption = 'Closed'; }
    value(3; Reversed) { Caption = 'Reversed'; }
    value(4; Rejected) { Caption = 'Rejected'; }
}

enum 50106 "Rebate Source Type"
{
    Extensible = true;
    value(0; "Purch. Inv. Line") { Caption = 'Purchase Invoice Line'; }
    value(1; "Sales Inv. Line") { Caption = 'Sales Invoice Line'; }
}

enum 50107 "Rebate Settlement Status"
{
    Extensible = true;
    value(0; Open) { Caption = 'Open'; }
    value(1; Approved) { Caption = 'Approved'; }
    value(2; Posted) { Caption = 'Posted'; }
    value(3; Rejected) { Caption = 'Rejected'; }
}

enum 50108 "Rebate Settlement Output"
{
    Extensible = true;
    value(0; "Custom Ledger") { Caption = 'Custom Ledger'; }
    value(1; "Vendor Credit Memo") { Caption = 'Vendor Credit Memo'; }
    value(2; "Customer Credit Memo") { Caption = 'Customer Credit Memo'; }
    value(3; "Journal Entry") { Caption = 'Journal Entry'; }
}

enum 50109 "Rebate Ledger Entry Type"
{
    Extensible = true;
    value(0; Calculation) { Caption = 'Calculation'; }
    value(1; Accrual) { Caption = 'Accrual'; }
    value(2; Reversal) { Caption = 'Reversal'; }
    value(3; Adjustment) { Caption = 'Adjustment'; }
    value(4; Settlement) { Caption = 'Settlement'; }
    value(5; Delta) { Caption = 'Delta'; }
}

enum 50110 "Rebate Error Category"
{
    Extensible = true;
    value(0; Validation) { Caption = 'Validation'; }
    value(1; Configuration) { Caption = 'Configuration'; }
    value(2; Posting) { Caption = 'Posting'; }
    value(3; Integration) { Caption = 'Integration'; }
    value(4; Concurrency) { Caption = 'Concurrency'; }
    value(5; Unexpected) { Caption = 'Unexpected'; }
}

enum 50111 "Rebate Integration Status"
{
    Extensible = true;
    value(0; Pending) { Caption = 'Pending'; }
    value(1; Completed) { Caption = 'Completed'; }
    value(2; Failed) { Caption = 'Failed'; }
}
