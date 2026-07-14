permissionset 50106 "RBT Rebate Auditor"
{
    Assignable = true;
    Caption = 'RBT Rebate Auditor';

    // Auditor has read-only access to every RBT table (including the immutable Audit
    // Entry log) and execute rights on the Audit Mgt. codeunit so the auditor can run
    // read-only inspection routines. The auditor must NEVER be able to modify or delete
    // any record — every tabledata permission is R only, and no posting/settlement/
    // rule-engine codeunit is granted. This is the segregation-of-duties role.
    // Enum entries are intentionally excluded (AL platform rule: enums are not valid
    // in the Permissions block; access flows transitively through tables and pages).
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = R,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Rebate Version" = R,
        tabledata "RBT Posting Setup" = R,
        tabledata "RBT Calculation Ledger Entry" = R,
        tabledata "RBT Calc Request" = R,
        tabledata "RBT Settlement Header" = R,
        tabledata "RBT Settlement Line" = R,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Job Chunk" = R,
        tabledata "RBT Integration Staging" = R,
        codeunit "RBT Audit Mgt." = X,
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
        page "RBT Audit Entries" = X,
        page "RBT Job Monitor" = X,
        page "RBT Job Chunks" = X,
        page "RBT Integration Staging List" = X;
}
