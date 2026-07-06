permissionset 50102 "RBT-VIEWER"
{
    Assignable = true;
    Caption = 'RBT-VIEWER';

    // Read-only access to every RBT table; page access is granted so the user
    // can navigate the UI, but no codeunit execution rights are granted.
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = R,
        tabledata "RBT Rebate Agmt Ver" = R,
        tabledata "RBT Rebate Ledg Ent" = R,
        tabledata "RBT Rebate Post Set" = R,
        tabledata "RBT Rebate Calc Hdr" = R,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Rebate Tier" = R,
        tabledata "RBT Agreement Header" = R,
        tabledata "RBT Agmt Version" = R,
        tabledata "RBT Rebate Rule" = R,
        tabledata "RBT Calc Ledg Entry" = R,
        tabledata "RBT Settlement Header" = R,
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
        page "RBT Rebate Setup" = X,
        page "RBT Rebate Agmt Card" = X,
        page "RBT Rebate Agmt Vers" = X,
        page "RBT Rebate Ledg Ents" = X,
        page "RBT Rebate Post Set" = X,
        page "RBT Rebate Calc Card" = X,
        page "RBT Agmt Versions" = X,
        page "RBT Rebate Rules" = X,
        page "RBT Rebate Rule Sub" = X,
        page "RBT Rebate Tier Sub" = X,
        page "RBT Calc Ledg Ents" = X,
        page "RBT Settlement Card" = X,
        page "RBT Settlement Lines" = X,
        page "RBT Settlement List" = X;
}
