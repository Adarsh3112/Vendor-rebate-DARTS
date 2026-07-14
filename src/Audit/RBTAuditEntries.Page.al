page 50120 "RBT Audit Entries"
{
    // Read-only list of the immutable RBT Audit Entry table.
    // All CUD flags are false so BC will not offer New / Edit / Delete actions on the
    // page even for users who otherwise hold write permission on the table.

    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'RBT Audit Entries';
    SourceTable = "RBT Audit Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique auto-assigned identifier for the audit entry.';
                }
                field("Date Time"; Rec."Date Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Server timestamp captured at the moment the event was recorded.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'User account that triggered the recorded event.';
                }
                field(Action; Rec.Action)
                {
                    ApplicationArea = All;
                    ToolTip = 'Business action being recorded (Status Change, Accrual Posted, Approval events, etc.).';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Primary document impacted by this event (agreement, calc request, settlement, or posted document number).';
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Value before the change - blank for events that have no prior value (Accrual Posted, Activated).';
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Value after the change, or the posted amount for financial events.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Human-readable summary of the event.';
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Table ID of the primary record impacted, for cross-reference in diagnostics.';
                    Visible = false;
                }
            }
        }
    }
}
