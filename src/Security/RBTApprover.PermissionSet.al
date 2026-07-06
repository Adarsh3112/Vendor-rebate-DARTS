permissionset 50105 "RBT-APPROVER"
{
    Assignable = true;
    Caption = 'RBT-APPROVER';

    // Approver: read everything, modify Status-bearing documents to approve or
    // reject. Allowed to invoke the management codeunits that perform the
    // status transitions, but not the G/L posting engines.
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = RM,
        tabledata "RBT Rebate Agmt Ver" = R,
        tabledata "RBT Rebate Ledg Ent" = R,
        tabledata "RBT Rebate Post Set" = R,
        tabledata "RBT Rebate Calc Hdr" = R,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Rebate Tier" = R,
        tabledata "RBT Agreement Header" = RM,
        tabledata "RBT Agmt Version" = R,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Calc Ledg Entry" = R,
        tabledata "RBT Settlement Header" = RM,
        tabledata "RBT Settlement Line" = R,
        table "RBT Rebate Setup" = X,
        table "RBT Rebate Agreement" = X,
        table "RBT Rebate Agmt Ver" = X,
        table "RBT Rebate Ledg Ent" = X,
        table "RBT Rebate Post Set" = X,
        table "RBT Rebate Calc Hdr" = X,
        table "RBT Audit Entry" = X,
        table "RBT Rebate Tier" = X,
        table "RBT Agreement Header" = X,
        table "RBT Agmt Version" = X,
        table "RBT Rebate Rule" = X,
        table "RBT Calc Ledg Entry" = X,
        table "RBT Settlement Header" = X,
        table "RBT Settlement Line" = X,
        page "RBT Rebate Agmt Card" = X,
        page "RBT Rebate Agmt Vers" = X,
        page "RBT Rebate Ledg Ents" = X,
        page "RBT Agmt Versions" = X,
        page "RBT Settlement Card" = X,
        page "RBT Settlement Lines" = X,
        page "RBT Settlement List" = X,
        codeunit "RBT Rebate Mgmt." = X,
        codeunit "RBT Settlement Mgmt." = X;
}
