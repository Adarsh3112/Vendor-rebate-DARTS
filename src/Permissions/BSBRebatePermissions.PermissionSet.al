permissionset 50500 "BSB Rebate Viewer"
{
    Assignable = true;
    Caption = 'Rebate Viewer';
    Permissions = tabledata "BSB Rebate Setup" = R,
                  tabledata "BSB Posting Setup" = R,
                  tabledata "BSB Agreement" = R,
                  tabledata "BSB Agreement Line" = R,
                  tabledata "BSB Agr Version" = R,
                  tabledata "BSB Rebate Rule" = R,
                  tabledata "BSB Threshold" = R,
                  tabledata "BSB Calc Entry" = R,
                  tabledata "BSB Accrual Entry" = R,
                  tabledata "BSB Settlement Hdr" = R,
                  tabledata "BSB Settlement Line" = R,
                  tabledata "BSB Audit Entry" = R;
}

permissionset 50501 "BSB Rebate Analyst"
{
    Assignable = true;
    Caption = 'Rebate Analyst';
    IncludedPermissionSets = "BSB Rebate Viewer";
    Permissions = tabledata "BSB Calc Request" = RIMD,
                  tabledata "BSB Calc Entry" = RIMD,
                  tabledata "BSB Accrual Entry" = RIMD,
                  tabledata "BSB Process Chunk" = RIMD,
                  tabledata "BSB Error Entry" = RIMD;
}

permissionset 50502 "BSB Rebate Manager"
{
    Assignable = true;
    Caption = 'Rebate Manager';
    IncludedPermissionSets = "BSB Rebate Analyst";
    Permissions = tabledata "BSB Agreement" = RIMD,
                  tabledata "BSB Agreement Line" = RIMD,
                  tabledata "BSB Agr Version" = RIMD,
                  tabledata "BSB Rebate Rule" = RIMD,
                  tabledata "BSB Threshold" = RIMD;
}

permissionset 50503 "BSB Rebate Approver"
{
    Assignable = true;
    Caption = 'Rebate Approver';
    IncludedPermissionSets = "BSB Rebate Viewer";
    Permissions = tabledata "BSB Agreement" = RM,
                  tabledata "BSB Settlement Hdr" = RM,
                  tabledata "BSB Audit Entry" = RI;
}

permissionset 50504 "BSB Rebate Poster"
{
    Assignable = true;
    Caption = 'Rebate Poster';
    IncludedPermissionSets = "BSB Rebate Viewer";
    Permissions = tabledata "BSB Accrual Entry" = RM,
                  tabledata "BSB Settlement Hdr" = RM,
                  tabledata "BSB Settlement Line" = RM,
                  tabledata "BSB Recalc Result" = RM,
                  tabledata "BSB Audit Entry" = RI;
}

permissionset 50505 "BSB Rebate Admin"
{
    Assignable = true;
    Caption = 'Rebate Administrator';
    IncludedPermissionSets = "BSB Rebate Manager";
    Permissions = tabledata "BSB Rebate Setup" = RIMD,
                  tabledata "BSB Posting Setup" = RIMD,
                  tabledata "BSB Integration Msg" = RIMD,
                  tabledata "BSB Process Chunk" = RIMD,
                  tabledata "BSB Error Entry" = RIMD;
}

permissionset 50506 "BSB Rebate Auditor"
{
    Assignable = true;
    Caption = 'Rebate Auditor';
    IncludedPermissionSets = "BSB Rebate Viewer";
    Permissions = tabledata "BSB Audit Entry" = R,
                  tabledata "BSB Integration Msg" = R,
                  tabledata "BSB Error Entry" = R;
}

permissionset 50507 "BSB Rebate Integr."
{
    Assignable = true;
    Caption = 'Rebate Integration Support';
    IncludedPermissionSets = "BSB Rebate Viewer";
    Permissions = tabledata "BSB Integration Msg" = RIMD,
                  tabledata "BSB Error Entry" = RIMD,
                  tabledata "BSB Agreement" = RIM,
                  tabledata "BSB Calc Request" = R,
                  tabledata "BSB Settlement Hdr" = R;
}
