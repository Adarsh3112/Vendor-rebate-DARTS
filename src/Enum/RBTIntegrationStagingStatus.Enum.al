enum 50109 "RBT Integration Staging Status"
{
    Extensible = true;
    Caption = 'RBT Integration Staging Status';

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Processing)
    {
        Caption = 'Processing';
    }
    value(2; Processed)
    {
        Caption = 'Processed';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}
