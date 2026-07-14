page 50116 "RBT Integration Staging List"
{
    // Operator view of the integration staging queue. Read-only across the raw
    // envelope fields (External ID, Source System, Payload); Status/Error Message
    // are populated by RBT Integration Mgt. The Reprocess action resets Error
    // rows and reruns Promote; View Payload shows the raw payload text.

    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RBT Integration Staging";
    Caption = 'RBT Integration Staging';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Auto-generated primary key for this staging row.';
                }
                field("External ID"; Rec."External ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Idempotency key supplied by the external system.';
                }
                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                    ToolTip = 'Name of the external system that supplied this payload.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = IsError;
                    ToolTip = 'Lifecycle status: New, Processing, Processed, Error.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When this row was ingested.';
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When promotion completed (successfully or with an error).';
                }
                field("Promoted To Agreement No."; Rec."Promoted To Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'RBT Rebate Agreement created for this staging row.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Error captured on the last failed promotion attempt. Blank on success.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                ApplicationArea = All;
                Caption = 'Reprocess';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Reset Status to New, clear Error Message, and rerun promotion.';

                trigger OnAction()
                var
                    IntegrationMgt: Codeunit "RBT Integration Mgt.";
                begin
                    IntegrationMgt.Reprocess(Rec);
                    if Rec.Find() then;
                    CurrPage.Update(false);
                end;
            }
            action(ViewPayload)
            {
                ApplicationArea = All;
                Caption = 'View Payload';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Show the raw payload text for this staging row.';

                trigger OnAction()
                var
                    PayloadText: Text;
                    NoPayloadMsg: Label 'This staging row has no payload.';
                begin
                    PayloadText := Rec.GetPayload();
                    if PayloadText = '' then
                        Message(NoPayloadMsg)
                    else
                        Message(PayloadText);
                end;
            }
        }
    }

    var
        IsError: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        IsError := Rec.Status = Rec.Status::Error;
    end;

    trigger OnAfterGetRecord()
    begin
        IsError := Rec.Status = Rec.Status::Error;
    end;
}
