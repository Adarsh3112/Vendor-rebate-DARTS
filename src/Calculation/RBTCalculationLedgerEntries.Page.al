page 50107 "RBT Calc Ledger Entries"
{
    Caption = 'Rebate Calculation Ledger Entries';
    PageType = List;
    SourceTable = "RBT Calculation Ledger Entry";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique auto-assigned entry number for this calculation ledger row.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this entry is an Original calculation produced by the Rule Engine or an Adjustment produced by the Retroactive Recalc Engine.';
                }
                field("Corrects Entry No."; Rec."Corrects Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'For Adjustment entries, points to the original Entry No. whose amount is being corrected. Zero for Original entries.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date copied from the source invoice line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the source line came from a posted Sales Invoice or a posted Purchase Invoice.';
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the posted source document.';
                }
                field("Source Document Line No."; Rec."Source Document Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number on the source posted document.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rebate agreement this entry was produced for.';
                }
                field("Agreement Version No."; Rec."Agreement Version No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the agreement version that was current when this entry was calculated.';
                }
                field("Rule Line No."; Rec."Rule Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rebate rule line that produced this entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item filter that matched on the rule (blank if no item filter).';
                }
                field("Item Category"; Rec."Item Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item category filter that matched on the rule (blank if no category filter).';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location filter that matched on the rule (blank if no location filter).';
                }
                field("Calculation Method"; Rec."Calculation Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the entry was computed with the Percentage or Fixed calculation method.';
                }
                field("Base Amount"; Rec."Base Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base amount from the source invoice line used in the calculation.';
                }
                field(Percentage; Rec.Percentage)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage rate applied when Calculation Method is Percentage.';
                }
                field("Fixed Amount"; Rec."Fixed Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fixed amount applied when Calculation Method is Fixed.';
                }
                field("Calculated Amount"; Rec."Calculated Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rebate amount produced by this ledger entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the calculated amount, copied from the agreement.';
                }
            }
        }
    }
}
