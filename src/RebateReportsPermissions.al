report 50100 "Rebate Accrual Summary"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Accrual; "Rebate Accrual Entry")
        {
            column(Agreement_No_; "Agreement No.") { }
            column(Currency_Code; "Currency Code") { }
            column(Status; Status) { }
            column(Amount; Amount) { }
            column(Remaining_Amount; "Remaining Amount") { }
        }
    }
}

report 50101 "Rebate Settlement Statement"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Header; "Rebate Settlement Header")
        {
            column(No_; "No.") { }
            column(Agreement_No_; "Agreement No.") { }
            column(Status; Status) { }
            column(Amount; Amount) { }
            dataitem(Line; "Rebate Settlement Line")
            {
                DataItemLink = "Settlement No." = field("No.");
                column(Accrual_Entry_No_; "Accrual Entry No.") { }
                column(Settlement_Amount; "Settlement Amount") { }
            }
        }
    }
}

report 50102 "Rebate Reconciliation Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Reconciliation; "Rebate Reconciliation Entry")
        {
            column(Agreement_No_; "Agreement No.") { }
            column(Calculation_Entry_No_; "Calculation Entry No.") { }
            column(Accrual_Entry_No_; "Accrual Entry No.") { }
            column(Calculated_Amount; "Calculated Amount") { }
            column(Posted_Amount; "Posted Amount") { }
            column(Variance; Variance) { }
        }
    }
}

report 50103 "Rebate Exception Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(CalcEntry; "Rebate Calculation Entry")
        {
            DataItemTableView = where(Eligible = const(false));
            column(Entry_No_; "Entry No.") { }
            column(Request_No_; "Request No.") { }
            column(Agreement_No_; "Agreement No.") { }
            column(Rejection_Reason; "Rejection Reason") { }
            column(Source_Key; "Source Key") { }
        }
    }
}

report 50104 "Rebate Audit Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Audit; "Rebate Audit Entry")
        {
            column(Entry_No_; "Entry No.") { }
            column(Created_DateTime; "Created DateTime") { }
            column(User_ID; "User ID") { }
            column(Action; Action) { }
            column(Table_ID; "Table ID") { }
            column(Record_ID_Text; "Record ID Text") { }
            column(Old_Value; "Old Value") { }
            column(New_Value; "New Value") { }
        }
    }
}

report 50105 "Rebate Accrual Detail"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Accrual; "Rebate Accrual Entry")
        {
            column(Entry_No_; "Entry No.") { }
            column(Calculation_Entry_No_; "Calculation Entry No.") { }
            column(Agreement_No_; "Agreement No.") { }
            column(Agreement_Version_No_; "Agreement Version No.") { }
            column(Entry_Type; "Entry Type") { }
            column(Status; Status) { }
            column(Amount; Amount) { }
            column(Remaining_Amount; "Remaining Amount") { }
            column(Currency_Code; "Currency Code") { }
            column(Posting_Date; "Posting Date") { }
        }
    }
}

report 50106 "Rebate Agreement Profitability"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(CalcEntry; "Rebate Calculation Entry")
        {
            column(Agreement_No_; "Agreement No.") { }
            column(Agreement_Version_No_; "Agreement Version No.") { }
            column(Source_Amount; "Source Amount") { }
            column(Rebate_Amount; "Rebate Amount") { }
            column(Amount_LCY; "Amount (LCY)") { }
            column(Currency_Code; "Currency Code") { }
            column(Eligible; Eligible) { }
        }
    }
}

permissionset 50100 "REBATE VIEWER"
{
    Assignable = true;
    Permissions =
        tabledata "Rebate Agreement Header" = R,
        tabledata "Rebate Agreement Line" = R,
        tabledata "Rebate Agreement Version" = R,
        tabledata "Rebate Rule" = R,
        tabledata "Rebate Calculation Entry" = R,
        tabledata "Rebate Accrual Entry" = R,
        tabledata "Rebate Settlement Header" = R,
        tabledata "Rebate Settlement Line" = R,
        tabledata "Rebate Audit Entry" = R,
        tabledata "Rebate Reconciliation Entry" = R;
}

permissionset 50101 "REBATE ANALYST"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE VIEWER";
    Permissions =
        tabledata "Rebate Calculation Request" = RIMD,
        tabledata "Rebate Settlement Header" = RIMD,
        tabledata "Rebate Settlement Line" = RIMD,
        tabledata "Rebate Calculation Entry" = RIMD,
        tabledata "Rebate Accrual Entry" = RIMD,
        codeunit "Rebate Calculation Engine" = X,
        codeunit "Rebate Settlement Engine" = X;
}

permissionset 50102 "REBATE MANAGER"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE ANALYST";
    Permissions =
        tabledata "Rebate Agreement Header" = RIMD,
        tabledata "Rebate Agreement Line" = RIMD,
        tabledata "Rebate Agreement Version" = RIM,
        tabledata "Rebate Rule" = RIMD,
        tabledata "Rebate Threshold" = RIMD,
        codeunit "Rebate Agreement Mgt." = X,
        codeunit "Rebate Rule Validator" = X;
}

permissionset 50103 "REBATE APPROVER"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE VIEWER";
    Permissions =
        codeunit "Rebate Agreement Mgt." = X,
        codeunit "Rebate Settlement Engine" = X,
        codeunit "Rebate Recalculation Engine" = X;
}

permissionset 50104 "REBATE POSTER"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE VIEWER";
    Permissions =
        tabledata "Rebate Accrual Entry" = RIMD,
        codeunit "Rebate Posting Engine" = X;
}

permissionset 50105 "REBATE ADMIN"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE MANAGER";
    Permissions =
        tabledata "Rebate Setup" = RIMD,
        tabledata "Rebate Posting Setup" = RIMD,
        tabledata "Rebate Integration Log" = RIMD,
        tabledata "Rebate Job Log" = RIMD,
        codeunit "Rebate Integration Mgt." = X,
        codeunit "Rebate Job Dispatcher" = X;
}

permissionset 50106 "REBATE AUDITOR"
{
    Assignable = true;
    IncludedPermissionSets = "REBATE VIEWER";
    Permissions =
        report "Rebate Audit Report" = X,
        report "Rebate Reconciliation Report" = X;
}
