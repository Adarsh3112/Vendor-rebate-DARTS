enum 50101 "RBT Agreement Status"
{
    Extensible = true;
    Caption = 'RBT Agreement Status';

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; Approved)
    {
        Caption = 'Approved';
    }
    value(2; Active)
    {
        Caption = 'Active';
    }
    value(3; Closed)
    {
        Caption = 'Closed';
    }
    value(4; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
}
