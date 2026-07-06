permissionset 50106 "RBT-POSTER"
{
    Assignable = true;
    Caption = 'RBT-POSTER';

    // Poster: execution rights on the posting codeunits (Accrual Engine,
    // Rebate Calc, Settlement Mgmt) plus the IM rights on the ledger and
    // calc-header tables those codeunits must write to.
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = R,
        tabledata "RBT Rebate Agmt Ver" = R,
        tabledata "RBT Rebate Ledg Ent" = RIM,
        tabledata "RBT Rebate Post Set" = R,
        tabledata "RBT Rebate Calc Hdr" = RIM,
        tabledata "RBT Audit Entry" = RIM,
        tabledata "RBT Rebate Tier" = R,
        tabledata "RBT Agreement Header" = RM,
        tabledata "RBT Agmt Version" = R,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Calc Ledg Entry" = RIM,
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
        page "RBT Rebate Calc Card" = X,
        page "RBT Rebate Ledg Ents" = X,
        page "RBT Calc Ledg Ents" = X,
        page "RBT Settlement Card" = X,
        page "RBT Settlement List" = X,
        codeunit "RBT Accrual Engine" = X,
        codeunit "RBT Rebate Calc." = X,
        codeunit "RBT Settlement Mgmt." = X;
}
