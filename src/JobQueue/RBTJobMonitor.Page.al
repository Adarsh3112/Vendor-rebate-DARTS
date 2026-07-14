page 50114 "RBT Job Monitor"
{
    // Operator dashboard for background rebate calculation jobs.
    //
    // Presents each Calc Request together with its aggregate chunk progress:
    //   Total Chunks / Completed Chunks / Failed Chunks (FlowFields on the Calc
    //   Request table). Failed chunks are exposed via the embedded RBT Job
    //   Chunks part where they can be retried inline; the header actions expose
    //   the batch-level operations Start Background Job, Process Now, and
    //   Retry All Failed.
    //
    // The page is a Card page (single Calc Request in focus at a time) and is
    // registered under UsageCategory = Tasks so it is discoverable via Tell Me.

    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "RBT Calc Request";
    Caption = 'RBT Job Monitor';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(Job)
            {
                Caption = 'Job';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Calc Request whose background job is being monitored.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Free-text description of the calculation batch.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Rebate Agreement whose source lines are being evaluated.';
                }
                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Posting status of the Calc Request. The background job is only relevant while status is Open.';
                }
            }
            group(Progress)
            {
                Caption = 'Progress';

                field("Total Chunks"; Rec."Total Chunks")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Total number of chunks planned for this Calc Request. Zero until the job has been planned.';
                }
                field("Completed Chunks"; Rec."Completed Chunks")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Number of chunks that completed without error.';
                }
                field("Failed Chunks"; Rec."Failed Chunks")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = HasFailedChunks;
                    ToolTip = 'Number of chunks currently in Failed status. Use Retry Failed Chunks to reprocess them.';
                }
            }
            part(Chunks; "RBT Job Chunks")
            {
                ApplicationArea = All;
                Caption = 'Chunks';
                SubPageLink = "Calc Request No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StartBackgroundJob)
            {
                ApplicationArea = All;
                Caption = 'Start Background Job';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Schedules a Job Queue Entry that processes this Calc Request in the background.';

                trigger OnAction()
                var
                    Dispatcher: Codeunit "RBT Job Dispatcher";
                begin
                    Dispatcher.ScheduleJob(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ProcessNow)
            {
                ApplicationArea = All;
                Caption = 'Process Now';
                Image = ExecuteBatch;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Processes every pending or failed chunk inline in the current session. Long-running - prefer Start Background Job for large runs.';

                trigger OnAction()
                var
                    Dispatcher: Codeunit "RBT Job Dispatcher";
                begin
                    Dispatcher.ProcessAllChunks(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RetryFailed)
            {
                ApplicationArea = All;
                Caption = 'Retry Failed Chunks';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Flips every Failed chunk back to Pending and re-runs it.';
                Enabled = HasFailedChunks;

                trigger OnAction()
                var
                    Dispatcher: Codeunit "RBT Job Dispatcher";
                begin
                    Dispatcher.RetryFailedChunks(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PlanChunks)
            {
                ApplicationArea = All;
                Caption = 'Plan Chunks';
                Image = SuggestLines;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Slices the source lines into chunks using the default chunk size, without running them.';

                trigger OnAction()
                var
                    Dispatcher: Codeunit "RBT Job Dispatcher";
                begin
                    Dispatcher.PlanChunksDefault(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        HasFailedChunks: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Total Chunks", "Completed Chunks", "Failed Chunks");
        HasFailedChunks := Rec."Failed Chunks" > 0;
    end;
}
