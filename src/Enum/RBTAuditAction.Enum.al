enum 50107 "RBT Audit Action"
{
    // Action codes recorded in the RBT Audit Entry table.
    // The trail captures both business-critical status changes on rebate agreements
    // and financial posting events. Additional codes may be appended - never renumber existing values.
    Extensible = true;
    Caption = 'RBT Audit Action';

    value(0; "Status Change")
    {
        Caption = 'Status Change';
    }
    value(1; "Sent For Approval")
    {
        Caption = 'Sent For Approval';
    }
    value(2; "Approval Cancelled")
    {
        Caption = 'Approval Cancelled';
    }
    value(3; Approved)
    {
        Caption = 'Approved';
    }
    value(4; Activated)
    {
        Caption = 'Activated';
    }
    value(5; "Accrual Posted")
    {
        Caption = 'Accrual Posted';
    }
    value(6; "Settlement Posted")
    {
        Caption = 'Settlement Posted';
    }
}
