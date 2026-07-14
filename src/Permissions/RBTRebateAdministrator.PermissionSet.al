permissionset 50104 "RBT Rebate Admin"
{
    Assignable = true;
    Caption = 'RBT Rebate Administrator';

    // Administrator has full RIMD across every RBT table including company-wide Setup,
    // plus execute on the Install codeunit and every domain codeunit.
    // Note: the Audit Entry table is RIMD here so administrators can inspect and,
    // if legally required, prune archived entries via a controlled channel; the table's
    // own OnModify/OnDelete triggers still block edits unless the internal-edit hatch
    // is toggled by RBT Audit Mgt.
    Permissions =
        tabledata "RBT Rebate Setup" = RIMD,
        tabledata "RBT Rebate Agreement" = RIMD,
        tabledata "RBT Rebate Rule" = RIMD,
        tabledata "RBT Rebate Version" = RIMD,
        tabledata "RBT Posting Setup" = RIMD,
        tabledata "RBT Calculation Ledger Entry" = R,
        tabledata "RBT Calc Request" = RIMD,
        tabledata "RBT Settlement Header" = RIMD,
        tabledata "RBT Settlement Line" = RIMD,
        tabledata "RBT Audit Entry" = RIMD,
        tabledata "RBT Job Chunk" = RIMD,
        tabledata "RBT Integration Staging" = RIMD,
        codeunit "RBT Install" = X,
        codeunit "RBT Rule Engine" = X,
        codeunit "RBT Rebate Version Mgt." = X,
        codeunit "RBT Rebate Agreement Approval" = X,
        codeunit "RBT Posting Engine" = X,
        codeunit "RBT Settlement Engine" = X,
        codeunit "RBT Recalc Engine" = X,
        codeunit "RBT Audit Mgt." = X,
        codeunit "RBT Job Dispatcher" = X,
        codeunit "RBT Job Chunk Worker" = X,
        codeunit "RBT Integration Mgt." = X,
        page "RBT Rebate Setup" = X,
        page "RBT Rebate Agreement Card" = X,
        page "RBT Rebate Rules Part" = X,
        page "RBT Rebate Posting Setup" = X,
        page "RBT Calc Ledger Entries" = X,
        page "RBT Rebate Version Card" = X,
        page "RBT Rebate Version List" = X,
        page "RBT Calc Request Card" = X,
        page "RBT Calc Request List" = X,
        page "RBT Settlement Card" = X,
        page "RBT Settlement List" = X,
        page "RBT Settlement Lines" = X,
        page "RBT Recalc Retroactive Dialog" = X,
        page "RBT Audit Entries" = X,
        page "RBT Job Monitor" = X,
        page "RBT Job Chunks" = X,
        page "RBT Integration Staging List" = X,
        page "RBT Integration Staging API" = X;
}
