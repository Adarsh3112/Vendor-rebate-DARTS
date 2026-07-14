page 50103 "RBT Rebate Version List"
{
    Caption = 'Rebate Versions';
    PageType = List;
    SourceTable = "RBT Rebate Version";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    CardPageId = "RBT Rebate Version Card";
    SourceTableView = sorting("Agreement No.", "Version No.") order(ascending);

    layout
    {
        area(content)
        {
            repeater(Versions)
            {
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rebate agreement this version belongs to.';
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequential version number for the agreement. Version 1 is created on first activation.';
                }
                field("Is Current"; Rec."Is Current")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is the currently active version of the agreement.';
                }
                field("Effective From"; Rec."Effective From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which this version is effective.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the timestamp when this version was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created this version.';
                }
                field("Change Description"; Rec."Change Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what changed to produce this version.';
                }
                field("Agreement Status Snapshot"; Rec."Agreement Status Snapshot")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the agreement at the moment this version was created.';
                }
            }
        }
    }
}
