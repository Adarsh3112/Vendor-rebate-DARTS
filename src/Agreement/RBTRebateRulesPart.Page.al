page 50102 "RBT Rebate Rules Part"
{
    Caption = 'Rebate Rules';
    PageType = ListPart;
    SourceTable = "RBT Rebate Rule";
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Rules)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the line number of the rebate rule within the agreement.';
                }
                field(Basis; Rec.Basis)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what the rebate is calculated on: Sales Amount, Purchase Amount, Quantity, or Margin.';
                }
                field("Calculation Method"; Rec."Calculation Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the rebate is calculated: Fixed, Percentage, Tiered, Slab, or Growth.';
                }
                field(Threshold; Rec.Threshold)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum value of the basis that must be reached before the rule applies.';
                }
                field(Percentage; Rec.Percentage)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage used when the Calculation Method is Percentage, Tiered, Slab, or Growth.';
                }
                field("Fixed Amount"; Rec."Fixed Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fixed rebate amount used when the Calculation Method is Fixed.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item to which this rebate rule applies. Leave blank to apply to all items.';
                }
                field("Item Category"; Rec."Item Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item category to which this rebate rule applies. Leave blank to apply to all categories.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location to which this rebate rule applies. Leave blank to apply to all locations.';
                }
            }
        }
    }
}
