enum 50104 "RBT Rebate Calc Method"
{
    Extensible = true;
    Caption = 'RBT Rebate Calculation Method';

    value(0; "Fixed Amount")
    {
        Caption = 'Fixed Amount';
    }
    value(1; Percentage)
    {
        Caption = 'Percentage';
    }
    value(2; "Tiered Percentage")
    {
        Caption = 'Tiered Percentage';
    }
    value(3; "Slab Amount")
    {
        Caption = 'Slab Amount';
    }
}
