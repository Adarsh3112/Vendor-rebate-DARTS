codeunit 50114 "RBT Job Chunk Worker"
{
    // Internal worker for the RBT Job Dispatcher.
    //
    // Runs the rule evaluation for exactly one RBT Job Chunk inside its own
    // transaction. The dispatcher invokes this codeunit via Codeunit.Run so
    // that any error raised by the underlying Rule Engine (e.g. missing
    // current version, corrupt source line) is trapped, the worker's
    // transaction is rolled back, and control returns to the dispatcher which
    // marks the chunk Failed and continues with the next chunk.
    //
    // The Rule Engine is already idempotent: re-running it never inserts
    // duplicate Calculation Ledger Entries. Chunk boundaries therefore serve
    // primarily as a transaction-size limiter (lock scope, resume point) and
    // not as a strict partition of the source-line domain.

    TableNo = "RBT Job Chunk";

    trigger OnRun()
    var
        Agreement: Record "RBT Rebate Agreement";
        RuleEngine: Codeunit "RBT Rule Engine";
    begin
        if not Agreement.Get(Rec."Agreement No.") then
            exit;
        if Agreement.Status <> Agreement.Status::Active then
            exit;
        RuleEngine.Run(Agreement."No.");
    end;
}
