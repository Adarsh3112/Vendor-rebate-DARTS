enum 50108 "RBT Job Chunk Status"
{
    // Lifecycle of a single chunk owned by the RBT Job Dispatcher.
    //
    // Pending   -> the chunk has been planned but not yet picked up by the dispatcher.
    // Processing-> the dispatcher is currently executing the chunk (transient).
    // Completed -> the chunk finished without error; its work is persisted to the
    //              Calculation Ledger Entry table and it must never be re-run.
    // Failed    -> the chunk raised an error; the error text is captured on the
    //              chunk record and the Retry Failed action can flip it back to Pending.
    Extensible = true;
    Caption = 'RBT Job Chunk Status';

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Processing)
    {
        Caption = 'Processing';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
}
