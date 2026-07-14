permissionset 50105 "RBT Rebate Approver"
{
    Assignable = true;
    Caption = 'RBT Rebate Approver';

    // Approver reviews agreements and settlements and issues approve/reject decisions.
    // Read access to master data, modify access to agreements (to flip approval status
    // through the standard Approvals framework), and execute on the Approval codeunit.
    // No posting rights — approval and posting are strictly segregated.
    // Enum entries are intentionally excluded (AL platform rule: enums are not valid
    // in the Permissions block; access flows transitively through tables and pages).
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = RIM,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Rebate Version" = R,
        tabledata "RBT Posting Setup" = R,
        tabledata "RBT Calculation Ledger Entry" = R,
        tabledata "RBT Calc Request" = RIM,
        tabledata "RBT Settlement Header" = RIM,
        tabledata "RBT Settlement Line" = R,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Job Chunk" = R,
        tabledata "RBT Integration Staging" = R,
        codeunit "RBT Rebate Agreement Approval" = X,
        codeunit "RBT Audit Mgt." = X,
        codeunit "RBT Rebate Version Mgt." = X,
        codeunit "RBT Job Dispatcher" = X,
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
