permissionset 50103 "RBT-ANALYST"
{
    Assignable = true;
    Caption = 'RBT-ANALYST';

    // Analyst: draft and maintain agreements, run calculation engine,
    // read ledger and audit entries. No posting and no settlement.
    Permissions =
        tabledata "RBT Rebate Setup" = R,
        tabledata "RBT Rebate Agreement" = RIM,
        tabledata "RBT Rebate Agmt Ver" = R,
        tabledata "RBT Rebate Ledg Ent" = R,
        tabledata "RBT Rebate Post Set" = R,
        tabledata "RBT Rebate Calc Hdr" = RIM,
        tabledata "RBT Audit Entry" = R,
        tabledata "RBT Rebate Tier" = RIMD,
        tabledata "RBT Agreement Header" = RIM,
        tabledata "RBT Agmt Version" = R,
        tabledata "RBT Rebate Rule" = RIMD,
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
        page "RBT Rebate Agmt Card" = X,
        page "RBT Rebate Agmt Vers" = X,
        page "RBT Rebate Ledg Ents" = X,
        page "RBT Rebate Calc Card" = X,
        page "RBT Agmt Versions" = X,
        page "RBT Rebate Rules" = X,
        page "RBT Rebate Rule Sub" = X,
        page "RBT Rebate Tier Sub" = X,
        page "RBT Calc Ledg Ents" = X,
        page "RBT Settlement List" = X,
        codeunit "RBT Elig Engine" = X,
        codeunit "RBT Rebate Calc." = X;
}
