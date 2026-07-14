page 50115 "RBT Job Chunks"
{
    // List part rendered inside the RBT Job Monitor showing every chunk of
    // the current Calc Request together with its Error Message and Retry
    // Count. A row-level Retry Chunk action allows the operator to retry a
    // single Failed chunk without touching sibling Completed chunks.

    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "RBT Job Chunk";
    Caption = 'RBT Job Chunks';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Chunk No."; Rec."Chunk No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sequence of the chunk inside its Calc Request.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = IsFailed;
                    ToolTip = 'Current lifecycle status of the chunk.';
                }
                field("Records Processed"; Rec."Records Processed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of source lines the Rule Engine examined for this chunk.';
                }
                field("Entries Created"; Rec."Entries Created")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of Calculation Ledger Entries produced by this chunk.';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many times this chunk has been retried after failure.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Error text captured at the moment the chunk failed. Blank when the chunk has never failed.';
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When the dispatcher last picked this chunk up.';
                }
                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When the chunk finished (successfully or with an error).';
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Lower bound of the source-line window this chunk covers.';
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Upper bound of the source-line window this chunk covers.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryChunk)
            {
                ApplicationArea = All;
                Caption = 'Retry Chunk';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsFailed;
                ToolTip = 'Flips this Failed chunk back to Pending and re-runs it.';

                trigger OnAction()
                var
                    Dispatcher: Codeunit "RBT Job Dispatcher";
                    ChunkToRun: Record "RBT Job Chunk";
                    OnlyFailedRetryableErr: Label 'Chunk %1 cannot be retried while its status is %2. Only Failed chunks can be retried individually.', Comment = '%1 = Chunk No., %2 = current status';
                begin
                    if Rec.Status <> Rec.Status::Failed then
                        Error(OnlyFailedRetryableErr, Rec."Chunk No.", Rec.Status);

                    Rec.SetAllowInternalEdit(true);
                    Rec.Status := Rec.Status::Pending;
                    Rec."Retry Count" := Rec."Retry Count" + 1;
                    Rec."Started At" := 0DT;
                    Rec."Completed At" := 0DT;
                    Rec.Modify();
                    Rec.SetAllowInternalEdit(false);

                    ChunkToRun := Rec;
                    Dispatcher.ProcessSingleChunk(ChunkToRun);

                    if Rec.Find() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        IsFailed: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        IsFailed := Rec.Status = Rec.Status::Failed;
    end;

    trigger OnAfterGetRecord()
    begin
        IsFailed := Rec.Status = Rec.Status::Failed;
    end;
}
