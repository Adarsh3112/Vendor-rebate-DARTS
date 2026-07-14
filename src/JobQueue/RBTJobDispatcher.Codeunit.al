codeunit 50104 "RBT Job Dispatcher"
{
    // Background processing engine for the RBT Rebate Rule Engine.
    //
    // Rationale:
    //   High-volume calculation runs (thousands of Purch. Inv. Lines across many
    //   Active agreements) cannot run in a single transaction: they hold write
    //   locks on "RBT Calculation Ledger Entry" long enough to block normal BC
    //   posting on other companies. This dispatcher slices the work into chunks,
    //   COMMITs after each successful chunk, and records progress and failures
    //   on the RBT Job Chunk table so the operator can watch progress on the
    //   RBT Job Monitor page and retry failed chunks without redoing work that
    //   already succeeded.
    //
    // Job Queue integration:
    //   OnRun() is invoked when the codeunit is scheduled via a Job Queue Entry.
    //   The Job Queue Entry "Record ID to Process" points at the RBT Calc Request
    //   the operator wants processed. If no Record ID is bound (the codeunit was
    //   run bare, e.g. from a test) the dispatcher iterates every Open Calc Request.
    //
    // Public API:
    //   ScheduleJob(CalcRequest)     - inserts a Job Queue Entry pointing at this codeunit.
    //   PlanChunks(CalcRequest, N)   - explicitly slices the work into chunks of size N.
    //   ProcessAllChunks(CalcRequest)- runs (or resumes) every Pending / Failed chunk inline.
    //   ProcessSingleChunk(Chunk)    - runs one chunk; used by test code and by row actions.
    //   RetryFailedChunks(CalcReq)   - flips all Failed chunks back to Pending and re-runs them.
    //
    // Idempotency:
    //   The underlying RBT Rule Engine already guards Calculation Ledger Entry
    //   inserts on (Agreement, Version, Source Type, Source Doc No., Source Line No.).
    //   Re-running a Completed chunk (via manual retry or a resumed job) therefore
    //   never produces duplicate ledger entries.

    TableNo = "RBT Calc Request";

    var
        DefaultChunkSize: Integer;
        JobDescriptionLbl: Label 'RBT Job Dispatcher: Calc Request %1', Comment = '%1 = Calc Request No.';
        NoChunksToRetryMsg: Label 'No failed chunks to retry for Calc Request %1.', Comment = '%1 = Calc Request No.';
        ChunksRetriedMsg: Label '%1 failed chunk(s) queued for retry on Calc Request %2.', Comment = '%1 = number of chunks, %2 = Calc Request No.';
        JobScheduledMsg: Label 'Background job scheduled for Calc Request %1.', Comment = '%1 = Calc Request No.';
        NoOpenChunksMsg: Label 'No pending or failed chunks to process for Calc Request %1.', Comment = '%1 = Calc Request No.';
        JobCompletedMsg: Label 'Background job complete: %1 chunk(s) completed, %2 failed for Calc Request %3.', Comment = '%1 = completed count, %2 = failed count, %3 = Calc Request No.';

    trigger OnRun()
    var
        CalcRequest: Record "RBT Calc Request";
    begin
        // Rec is the RBT Calc Request bound by the Job Queue's "Record ID to Process".
        // When the codeunit is invoked without a bound record we sweep every Open Calc Request.
        if Rec."No." <> '' then begin
            CalcRequest := Rec;
            ProcessAllChunks(CalcRequest);
            exit;
        end;

        CalcRequest.SetRange("Posting Status", CalcRequest."Posting Status"::Open);
        if CalcRequest.FindSet() then
            repeat
                ProcessAllChunks(CalcRequest);
            until CalcRequest.Next() = 0;
    end;

    /// <summary>
    /// Slices the eligible source lines for the Calc Request's Agreement into
    /// chunks of the requested size and inserts one RBT Job Chunk record per
    /// chunk. Existing chunks for the Calc Request are preserved - re-planning
    /// only adds chunks for source lines that are not yet covered by an existing
    /// (Pending, Processing, Completed, or Failed) chunk. This makes PlanChunks
    /// safe to call repeatedly on the same Calc Request.
    /// </summary>
    procedure PlanChunks(var CalcRequest: Record "RBT Calc Request"; ChunkSize: Integer)
    var
        JobChunk: Record "RBT Job Chunk";
        Agreement: Record "RBT Rebate Agreement";
        PurchInvLine: Record "Purch. Inv. Line";
        NextChunkNo: Integer;
        RecCount: Integer;
        ChunkLower: Integer;
        MaxCovered: Integer;
        CurrentEntryNo: Integer;
    begin
        if ChunkSize <= 0 then
            ChunkSize := ResolveDefaultChunkSize();

        if not Agreement.Get(CalcRequest."Agreement No.") then
            exit;

        // Determine the highest "To Entry No." already covered so re-planning is idempotent.
        MaxCovered := HighestCoveredEntryNo(CalcRequest."No.");
        NextChunkNo := HighestChunkNo(CalcRequest."No.") + 1;

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Posting Date", Agreement."Start Date", Agreement."End Date");
        PurchInvLine.SetRange("Buy-from Vendor No.", Agreement."Vendor No.");
        PurchInvLine.SetFilter("Line No.", '>%1', MaxCovered);
        if not PurchInvLine.FindSet() then
            exit;

        RecCount := 0;
        ChunkLower := 0;
        CurrentEntryNo := 0;
        repeat
            CurrentEntryNo := PurchInvLine."Line No.";
            if RecCount = 0 then
                ChunkLower := CurrentEntryNo;
            RecCount += 1;
            if RecCount >= ChunkSize then begin
                InsertChunk(JobChunk, CalcRequest, Agreement, NextChunkNo, ChunkLower, CurrentEntryNo);
                NextChunkNo += 1;
                RecCount := 0;
            end;
        until PurchInvLine.Next() = 0;

        // Flush the trailing partial chunk (source-line count not a multiple of ChunkSize).
        if RecCount > 0 then
            InsertChunk(JobChunk, CalcRequest, Agreement, NextChunkNo, ChunkLower, CurrentEntryNo);
    end;

    /// <summary>
    /// Convenience overload: plans chunks with the default chunk size.
    /// </summary>
    procedure PlanChunksDefault(var CalcRequest: Record "RBT Calc Request")
    begin
        PlanChunks(CalcRequest, ResolveDefaultChunkSize());
    end;

    /// <summary>
    /// Processes every Pending or Failed chunk for the given Calc Request.
    /// If no chunks have been planned yet, PlanChunks is called first so callers
    /// can invoke a single entry point without worrying about setup.
    /// COMMITs after each successful chunk so an interrupted job can resume.
    /// </summary>
    procedure ProcessAllChunks(var CalcRequest: Record "RBT Calc Request")
    var
        JobChunk: Record "RBT Job Chunk";
        CompletedCount: Integer;
        FailedCount: Integer;
    begin
        // If nothing has been planned yet, plan with the default chunk size.
        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        if JobChunk.IsEmpty() then
            PlanChunks(CalcRequest, ResolveDefaultChunkSize());

        JobChunk.Reset();
        JobChunk.SetCurrentKey("Calc Request No.", "Chunk No.");
        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetFilter(Status, '%1|%2', JobChunk.Status::Pending, JobChunk.Status::Failed);
        if not JobChunk.FindSet() then begin
            Message(NoOpenChunksMsg, CalcRequest."No.");
            exit;
        end;

        CompletedCount := 0;
        FailedCount := 0;
        repeat
            ProcessSingleChunk(JobChunk);
            // Reload after the internal-edit toggle so we see the final Status.
            if JobChunk.Find() then
                case JobChunk.Status of
                    JobChunk.Status::Completed:
                        CompletedCount += 1;
                    JobChunk.Status::Failed:
                        FailedCount += 1;
                end;
        until JobChunk.Next() = 0;

        Message(JobCompletedMsg, CompletedCount, FailedCount, CalcRequest."No.");
    end;

    /// <summary>
    /// Executes exactly one chunk. Failure is trapped via Codeunit.Run so a
    /// poisoned chunk marks itself Failed and the caller can continue with the
    /// next chunk. On success the chunk transitions Pending/Failed -> Processing
    /// -> Completed, its counters are stamped, and the transaction is committed
    /// so subsequent chunks execute in fresh, short transactions.
    /// </summary>
    procedure ProcessSingleChunk(var JobChunk: Record "RBT Job Chunk")
    var
        Worker: Codeunit "RBT Job Chunk Worker";
        WorkerChunk: Record "RBT Job Chunk";
        ErrText: Text;
        LedgerCountBefore: Integer;
        LedgerCountAfter: Integer;
    begin
        // A Completed chunk has already contributed its ledger entries; skip.
        if JobChunk.Status = JobChunk.Status::Completed then
            exit;

        LedgerCountBefore := CountLedgerEntriesForAgreement(JobChunk."Agreement No.");

        MarkChunkProcessing(JobChunk);
        Commit();

        // Codeunit.Run traps any error raised inside the worker's OnRun trigger,
        // rolls back the worker's transaction, and returns FALSE. The chunk
        // record edits we made above (Processing / Started At) survive because
        // they were committed before Run.
        WorkerChunk := JobChunk;
        Clear(Worker);
        if Worker.Run(WorkerChunk) then begin
            LedgerCountAfter := CountLedgerEntriesForAgreement(JobChunk."Agreement No.");
            MarkChunkCompleted(JobChunk, LedgerCountAfter - LedgerCountBefore);
            Commit();
        end else begin
            ErrText := GetLastErrorText();
            if ErrText = '' then
                ErrText := 'Unknown error while processing chunk.';
            ClearLastError();
            MarkChunkFailed(JobChunk, ErrText);
            Commit();
        end;
    end;

    /// <summary>
    /// Flips every Failed chunk for the given Calc Request back to Pending,
    /// increments its Retry Count, and re-runs it. Chunks that have never
    /// failed are untouched.
    /// </summary>
    procedure RetryFailedChunks(var CalcRequest: Record "RBT Calc Request")
    var
        JobChunk: Record "RBT Job Chunk";
        RetryCount: Integer;
    begin
        JobChunk.SetRange("Calc Request No.", CalcRequest."No.");
        JobChunk.SetRange(Status, JobChunk.Status::Failed);
        if not JobChunk.FindSet() then begin
            Message(NoChunksToRetryMsg, CalcRequest."No.");
            exit;
        end;

        RetryCount := 0;
        repeat
            RetryCount += 1;
            ResetChunkForRetry(JobChunk);
        until JobChunk.Next() = 0;

        Message(ChunksRetriedMsg, RetryCount, CalcRequest."No.");

        ProcessAllChunks(CalcRequest);
    end;

    /// <summary>
    /// Schedules a Job Queue Entry that will invoke this codeunit against the
    /// given Calc Request. The Job Queue takes over from there and calls the
    /// codeunit's OnRun trigger on a background session.
    /// </summary>
    procedure ScheduleJob(var CalcRequest: Record "RBT Calc Request")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"RBT Job Dispatcher";
        JobQueueEntry."Record ID to Process" := CalcRequest.RecordId();
        JobQueueEntry.Description := CopyStr(StrSubstNo(JobDescriptionLbl, CalcRequest."No."), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 60;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(true);

        Message(JobScheduledMsg, CalcRequest."No.");
    end;

    // ---------------------------------------------------------------------------
    // Chunk lifecycle helpers - all writes go through the internal-edit hatch.
    // ---------------------------------------------------------------------------

    local procedure MarkChunkProcessing(var JobChunk: Record "RBT Job Chunk")
    begin
        JobChunk.SetAllowInternalEdit(true);
        JobChunk.Status := JobChunk.Status::Processing;
        JobChunk."Started At" := CurrentDateTime();
        JobChunk."Error Message" := '';
        JobChunk.Modify();
        JobChunk.SetAllowInternalEdit(false);
    end;

    local procedure MarkChunkCompleted(var JobChunk: Record "RBT Job Chunk"; EntriesCreated: Integer)
    var
        RecordsCounted: Integer;
    begin
        RecordsCounted := CountRecordsInWindow(JobChunk);
        JobChunk.SetAllowInternalEdit(true);
        JobChunk.Status := JobChunk.Status::Completed;
        JobChunk."Completed At" := CurrentDateTime();
        JobChunk."Records Processed" := RecordsCounted;
        if EntriesCreated < 0 then
            EntriesCreated := 0;
        JobChunk."Entries Created" := EntriesCreated;
        JobChunk."Error Message" := '';
        JobChunk.Modify();
        JobChunk.SetAllowInternalEdit(false);
    end;

    local procedure MarkChunkFailed(var JobChunk: Record "RBT Job Chunk"; ErrorText: Text)
    begin
        JobChunk.SetAllowInternalEdit(true);
        JobChunk.Status := JobChunk.Status::Failed;
        JobChunk."Completed At" := CurrentDateTime();
        JobChunk."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(JobChunk."Error Message"));
        JobChunk.Modify();
        JobChunk.SetAllowInternalEdit(false);
    end;

    local procedure ResetChunkForRetry(var JobChunk: Record "RBT Job Chunk")
    begin
        JobChunk.SetAllowInternalEdit(true);
        JobChunk.Status := JobChunk.Status::Pending;
        JobChunk."Retry Count" := JobChunk."Retry Count" + 1;
        JobChunk."Started At" := 0DT;
        JobChunk."Completed At" := 0DT;
        JobChunk.Modify();
        JobChunk.SetAllowInternalEdit(false);
    end;

    local procedure InsertChunk(var JobChunk: Record "RBT Job Chunk"; var CalcRequest: Record "RBT Calc Request"; var Agreement: Record "RBT Rebate Agreement"; ChunkNo: Integer; FromEntryNo: Integer; ToEntryNo: Integer)
    begin
        JobChunk.Init();
        JobChunk."Calc Request No." := CalcRequest."No.";
        JobChunk."Agreement No." := Agreement."No.";
        JobChunk."Chunk No." := ChunkNo;
        JobChunk."From Entry No." := FromEntryNo;
        JobChunk."To Entry No." := ToEntryNo;
        JobChunk.Status := JobChunk.Status::Pending;
        JobChunk.Insert(true);
    end;

    // ---------------------------------------------------------------------------
    // Read helpers
    // ---------------------------------------------------------------------------

    local procedure HighestCoveredEntryNo(CalcRequestNo: Code[20]): Integer
    var
        JobChunk: Record "RBT Job Chunk";
    begin
        JobChunk.SetCurrentKey("Calc Request No.", "Chunk No.");
        JobChunk.SetRange("Calc Request No.", CalcRequestNo);
        if JobChunk.FindLast() then
            exit(JobChunk."To Entry No.");
        exit(0);
    end;

    local procedure HighestChunkNo(CalcRequestNo: Code[20]): Integer
    var
        JobChunk: Record "RBT Job Chunk";
    begin
        JobChunk.SetCurrentKey("Calc Request No.", "Chunk No.");
        JobChunk.SetRange("Calc Request No.", CalcRequestNo);
        if JobChunk.FindLast() then
            exit(JobChunk."Chunk No.");
        exit(0);
    end;

    local procedure CountLedgerEntriesForAgreement(AgreementNo: Code[20]): Integer
    var
        LedgerEntry: Record "RBT Calculation Ledger Entry";
    begin
        LedgerEntry.SetRange("Agreement No.", AgreementNo);
        exit(LedgerEntry.Count());
    end;

    local procedure CountRecordsInWindow(var JobChunk: Record "RBT Job Chunk"): Integer
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Agreement: Record "RBT Rebate Agreement";
    begin
        if not Agreement.Get(JobChunk."Agreement No.") then
            exit(0);
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Posting Date", Agreement."Start Date", Agreement."End Date");
        PurchInvLine.SetRange("Buy-from Vendor No.", Agreement."Vendor No.");
        PurchInvLine.SetRange("Line No.", JobChunk."From Entry No.", JobChunk."To Entry No.");
        exit(PurchInvLine.Count());
    end;

    local procedure ResolveDefaultChunkSize(): Integer
    begin
        if DefaultChunkSize <= 0 then
            DefaultChunkSize := 500;
        exit(DefaultChunkSize);
    end;

    /// <summary>
    /// Overrides the default chunk size (500) used when PlanChunks is called
    /// without an explicit size. Test codeunits use this to force small chunks
    /// against small fixtures.
    /// </summary>
    procedure SetDefaultChunkSize(NewSize: Integer)
    begin
        DefaultChunkSize := NewSize;
    end;
}
