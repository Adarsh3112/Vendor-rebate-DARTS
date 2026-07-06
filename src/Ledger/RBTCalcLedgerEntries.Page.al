page 50111 "RBT Calc Ledg Ents"
{
    PageType = List;
    SourceTable = "RBT Calc Ledg Entry";
    Caption = 'RBT Calc Ledg Entries';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    UsageCategory = History;
    ApplicationArea = All;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique entry number for the calculation ledger row.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting date used for the rebate calculation entry.';
                }
                field("Calculation Req. No."; Rec."Calculation Req. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Calculation request that produced this entry.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Agreement under which this entry was calculated.';
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Agreement version that was in force when this entry was calculated.';
                }
                field("Rule No."; Rec."Rule No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rule line that produced this calculation entry.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the source document is a Sales or Purchase invoice.';
                }
                field("Source Trans. No."; Rec."Source Trans. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Original document number (Sales Invoice No. or Purchase Invoice No.) the rebate was calculated on.';
                }
                field("Amount LCY"; Rec."Amount LCY")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate amount converted to the local currency.';
                }
                field("Amount FCY"; Rec."Amount FCY")
                {
                    ApplicationArea = All;
                    ToolTip = 'Rebate amount in the original (foreign) currency.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Currency of the FCY amount.';
                }
                field("Exchange Rate"; Rec."Exchange Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Exchange rate applied when converting FCY to LCY on the posting date.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When the calculation ledger entry was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'User that created the calculation ledger entry.';
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Indicates whether the entry has been turned into a G/L journal pair by the accrual engine.';
                }
                field("Posted At"; Rec."Posted At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Date and time when the entry was posted to the general ledger.';
                }
            }
        }
    }
}
