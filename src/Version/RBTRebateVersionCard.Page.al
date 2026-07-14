page 50106 "RBT Rebate Version Card"
{
    Caption = 'Rebate Version';
    PageType = Card;
    SourceTable = "RBT Rebate Version";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Identification)
            {
                Caption = 'Identification';

                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rebate agreement this version belongs to.';
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequential version number for the agreement.';
                }
                field("Is Current"; Rec."Is Current")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is the currently active version.';
                }
            }
            group(Effectivity)
            {
                Caption = 'Effectivity';

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
            }
            group(Snapshot)
            {
                Caption = 'Snapshot';

                field("Agreement Status Snapshot"; Rec."Agreement Status Snapshot")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the agreement at the moment this version was created.';
                }
                field("Description Snapshot"; Rec."Description Snapshot")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the agreement at the moment this version was created.';
                }
                field("Start Date Snapshot"; Rec."Start Date Snapshot")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Start Date recorded in this version.';
                }
                field("End Date Snapshot"; Rec."End Date Snapshot")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the End Date recorded in this version.';
                }
            }
        }
    }
}
