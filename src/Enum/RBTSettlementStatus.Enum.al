enum 50105 "RBT Settlement Status"
{
    Extensible = true;
    Caption = 'RBT Settlement Status';

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; Pending)
    {
        Caption = 'Pending';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Posted)
    {
        Caption = 'Posted';
    }
}
