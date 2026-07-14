permissionset 50100 "RBT Rebate Viewer"
{
    Assignable = true;
    Caption = 'RBT Rebate Viewer';

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
