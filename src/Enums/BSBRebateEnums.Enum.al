enum 50100 "BSB Agreement Type"
{
    Extensible = true;

    value(0; "Vendor Rebate") { Caption = 'Vendor Rebate'; }
    value(1; "Customer Incentive") { Caption = 'Customer Incentive'; }
}

enum 50101 "BSB Agreement Status"
{
    Extensible = true;

    value(0; Draft) { Caption = 'Draft'; }
    value(1; "Pending Approval") { Caption = 'Pending Approval'; }
    value(2; Approved) { Caption = 'Approved'; }
    value(3; Active) { Caption = 'Active'; }
    value(4; Suspended) { Caption = 'Suspended'; }
    value(5; Expired) { Caption = 'Expired'; }
    value(6; Rejected) { Caption = 'Rejected'; }
}

enum 50102 "BSB Rule Basis"
{
    Extensible = true;

    value(0; "Sales Amount") { Caption = 'Sales Amount'; }
    value(1; "Purchase Amount") { Caption = 'Purchase Amount'; }
    value(2; Quantity) { Caption = 'Quantity'; }
    value(3; Margin) { Caption = 'Margin'; }
    value(4; "Payment Date") { Caption = 'Payment Date'; }
    value(5; "Invoice Date") { Caption = 'Invoice Date'; }
    value(6; "Shipment Date") { Caption = 'Shipment Date'; }
}

enum 50103 "BSB Calc Method"
{
    Extensible = true;

    value(0; "Fixed Amount") { Caption = 'Fixed Amount'; }
    value(1; Percentage) { Caption = 'Percentage'; }
    value(2; "Tiered Percentage") { Caption = 'Tiered Percentage'; }
    value(3; "Slab Amount") { Caption = 'Slab Amount'; }
    value(4; "Formula Reference") { Caption = 'Formula Reference'; }
    value(5; Growth) { Caption = 'Growth'; }
}

enum 50104 "BSB Request Type"
{
    Extensible = true;

    value(0; Calculation) { Caption = 'Calculation'; }
    value(1; Recalculation) { Caption = 'Recalculation'; }
    value(2; Preview) { Caption = 'Preview'; }
}

enum 50105 "BSB Process Status"
{
    Extensible = true;

    value(0; Open) { Caption = 'Open'; }
    value(1; Running) { Caption = 'Running'; }
    value(2; Completed) { Caption = 'Completed'; }
    value(3; Failed) { Caption = 'Failed'; }
    value(4; Cancelled) { Caption = 'Cancelled'; }
    value(5; "Partially Completed") { Caption = 'Partially Completed'; }
}

enum 50106 "BSB Eligibility Status"
{
    Extensible = true;

    value(0; "Not Evaluated") { Caption = 'Not Evaluated'; }
    value(1; Eligible) { Caption = 'Eligible'; }
    value(2; Rejected) { Caption = 'Rejected'; }
}

enum 50107 "BSB Entry Status"
{
    Extensible = true;

    value(0; Open) { Caption = 'Open'; }
    value(1; Posted) { Caption = 'Posted'; }
    value(2; "Partially Settled") { Caption = 'Partially Settled'; }
    value(3; Settled) { Caption = 'Settled'; }
    value(4; Reversed) { Caption = 'Reversed'; }
    value(5; Adjusted) { Caption = 'Adjusted'; }
}

enum 50108 "BSB Approval Status"
{
    Extensible = true;

    value(0; Open) { Caption = 'Open'; }
    value(1; "Pending Approval") { Caption = 'Pending Approval'; }
    value(2; Approved) { Caption = 'Approved'; }
    value(3; Rejected) { Caption = 'Rejected'; }
    value(4; Delegated) { Caption = 'Delegated'; }
    value(5; "Changes Requested") { Caption = 'Changes Requested'; }
}

enum 50109 "BSB Error Category"
{
    Extensible = true;

    value(0; Validation) { Caption = 'Validation'; }
    value(1; Configuration) { Caption = 'Configuration'; }
    value(2; Posting) { Caption = 'Posting'; }
    value(3; Integration) { Caption = 'Integration'; }
    value(4; Concurrency) { Caption = 'Concurrency'; }
    value(5; Unexpected) { Caption = 'Unexpected'; }
}

enum 50110 "BSB Msg Direction"
{
    Extensible = true;

    value(0; Inbound) { Caption = 'Inbound'; }
    value(1; Outbound) { Caption = 'Outbound'; }
}
