permissionset 50101 "RBT Rebate Analyst"
{
    Assignable = true;
    Caption = 'RBT Rebate Analyst';

    // Analyst prepares Calc Requests and runs the Rule Engine, but cannot post accruals to G/L.
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = R,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Rebate Version" = R,
        tabledata "RBT Posting Setup" = R,
        tabledata "RBT Calculation Ledger Entry" = R,
        tabledata "RBT Calc Request" = RIMD,
        tabledata "RBT Settlement Header" = R,
        tabledata "RBT Settlement Line" = R,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Job Chunk" = RIMD,
        tabledata "RBT Integration Staging" = R,
        codeunit "RBT Rule Engine" = X,
        codeunit "RBT Rebate Version Mgt." = X,
        codeunit "RBT Rebate Agreement Approval" = X,
        codeunit "RBT Settlement Engine" = X,
        codeunit "RBT Audit Mgt." = X,
        codeunit "RBT Job Dispatcher" = X,
        codeunit "RBT Job Chunk Worker" = X,
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
