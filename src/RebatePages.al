page 50100 "Rebate Setup"
{
    PageType = Card;
    SourceTable = "Rebate Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Agreement Nos."; Rec."Agreement Nos.") { ApplicationArea = All; }
                field("Calculation Request Nos."; Rec."Calculation Request Nos.") { ApplicationArea = All; }
                field("Settlement Nos."; Rec."Settlement Nos.") { ApplicationArea = All; }
                field("Integration Secret Ref."; Rec."Integration Secret Ref.") { ApplicationArea = All; }
            }
        }
    }
}

page 50101 "Rebate Posting Setup"
{
    PageType = List;
    SourceTable = "Rebate Posting Setup";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field("Expense Account No."; Rec."Expense Account No.") { ApplicationArea = All; }
                field("Liability Account No."; Rec."Liability Account No.") { ApplicationArea = All; }
                field("Settlement Output"; Rec."Settlement Output") { ApplicationArea = All; }
            }
        }
    }
}

page 50102 "Rebate Agreement List"
{
    PageType = List;
    SourceTable = "Rebate Agreement Header";
    CardPageId = "Rebate Agreement Card";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field("Active Version No."; Rec."Active Version No.") { ApplicationArea = All; }
            }
        }
    }
}

page 50103 "Rebate Agreement Card"
{
    PageType = Card;
    SourceTable = "Rebate Agreement Header";
    ApplicationArea = All;
    UsageCategory = Documents;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Price Group"; Rec."Customer Price Group") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Settlement Method"; Rec."Settlement Method") { ApplicationArea = All; }
                field("Country/Region Code"; Rec."Country/Region Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code") { ApplicationArea = All; }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code") { ApplicationArea = All; }
                field("Region Code"; Rec."Region Code") { ApplicationArea = All; }
                field("Department Code"; Rec."Department Code") { ApplicationArea = All; }
                field("Active Version No."; Rec."Active Version No.") { ApplicationArea = All; Editable = false; }
            }
            part(Lines; "Rebate Agreement Lines") { ApplicationArea = All; SubPageLink = "Agreement No." = field("No."); }
            part(Rules; "Rebate Rules") { ApplicationArea = All; SubPageLink = "Agreement No." = field("No."); }
        }
    }

    actions
    {
        area(processing)
        {
            action(Submit)
            {
                ApplicationArea = All;
                Image = SendApprovalRequest;
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "Rebate Agreement Mgt.";
                begin
                    AgreementMgt.Submit(Rec);
                end;
            }
            action(Approve)
            {
                ApplicationArea = All;
                Image = Approve;
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "Rebate Agreement Mgt.";
                begin
                    AgreementMgt.Approve(Rec);
                end;
            }
            action(Activate)
            {
                ApplicationArea = All;
                Image = ReleaseDoc;
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "Rebate Agreement Mgt.";
                begin
                    AgreementMgt.Activate(Rec);
                end;
            }
            action(CreateRevision)
            {
                ApplicationArea = All;
                Image = Edit;
                trigger OnAction()
                var
                    AgreementMgt: Codeunit "Rebate Agreement Mgt.";
                begin
                    AgreementMgt.CreateRevision(Rec);
                end;
            }
            action(Versions)
            {
                ApplicationArea = All;
                Image = Versions;
                RunObject = page "Rebate Agreement Versions";
                RunPageLink = "Agreement No." = field("No.");
            }
        }
    }
}

page 50104 "Rebate Agreement Lines"
{
    PageType = ListPart;
    SourceTable = "Rebate Agreement Line";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Item Category Code"; Rec."Item Category Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field(Include; Rec.Include) { ApplicationArea = All; }
                field("Dimension 1 Code"; Rec."Dimension 1 Code") { ApplicationArea = All; }
                field("Dimension 2 Code"; Rec."Dimension 2 Code") { ApplicationArea = All; }
            }
        }
    }
}

page 50105 "Rebate Agreement Versions"
{
    PageType = List;
    SourceTable = "Rebate Agreement Version";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Version No."; Rec."Version No.") { ApplicationArea = All; }
                field("Agreement Type"; Rec."Agreement Type") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Posting Group"; Rec."Posting Group") { ApplicationArea = All; }
                field("Created DateTime"; Rec."Created DateTime") { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
            }
        }
    }
}

page 50106 "Rebate Rules"
{
    PageType = ListPart;
    SourceTable = "Rebate Rule";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Rule No."; Rec."Rule No.") { ApplicationArea = All; }
                field(Basis; Rec.Basis) { ApplicationArea = All; }
                field("Calculation Method"; Rec."Calculation Method") { ApplicationArea = All; }
                field("Percent"; Rec."Percent") { ApplicationArea = All; }
                field("Fixed Amount"; Rec."Fixed Amount") { ApplicationArea = All; }
                field("Minimum Amount"; Rec."Minimum Amount") { ApplicationArea = All; }
                field("Maximum Amount"; Rec."Maximum Amount") { ApplicationArea = All; }
                field(Priority; Rec.Priority) { ApplicationArea = All; }
                field("Formula Reference"; Rec."Formula Reference") { ApplicationArea = All; }
                field("Excluded Item Category Code"; Rec."Excluded Item Category Code") { ApplicationArea = All; }
            }
        }
    }
}

page 50107 "Rebate Calculation Requests"
{
    PageType = List;
    SourceTable = "Rebate Calculation Request";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Recalculation Mode"; Rec."Recalculation Mode") { ApplicationArea = All; }
                field("Processed Count"; Rec."Processed Count") { ApplicationArea = All; }
                field("Failed Count"; Rec."Failed Count") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RunCalculation)
            {
                ApplicationArea = All;
                Image = Calculate;
                trigger OnAction()
                var
                    CalcEngine: Codeunit "Rebate Calculation Engine";
                    PostingEngine: Codeunit "Rebate Posting Engine";
                begin
                    CalcEngine.RunRequest(Rec);
                    PostingEngine.CreateAccruals(Rec."No.");
                end;
            }
        }
    }
}

page 50108 "Rebate Calculation Entries"
{
    PageType = List;
    SourceTable = "Rebate Calculation Entry";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Agreement Version No."; Rec."Agreement Version No.") { ApplicationArea = All; }
                field("Rule No."; Rec."Rule No.") { ApplicationArea = All; }
                field("Source Type"; Rec."Source Type") { ApplicationArea = All; }
                field("Source Document No."; Rec."Source Document No.") { ApplicationArea = All; }
                field("Source Line No."; Rec."Source Line No.") { ApplicationArea = All; }
                field(Eligible; Rec.Eligible) { ApplicationArea = All; }
                field("Rejection Reason"; Rec."Rejection Reason") { ApplicationArea = All; }
                field("Source Amount"; Rec."Source Amount") { ApplicationArea = All; }
                field("Rebate Amount"; Rec."Rebate Amount") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field(Posted; Rec.Posted) { ApplicationArea = All; }
            }
        }
    }
}

page 50109 "Rebate Accrual Entries"
{
    PageType = List;
    SourceTable = "Rebate Accrual Entry";
    ApplicationArea = All;
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Calculation Entry No."; Rec."Calculation Entry No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Remaining Amount"; Rec."Remaining Amount") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field("Closed by Settlement No."; Rec."Closed by Settlement No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PostOpen)
            {
                ApplicationArea = All;
                Image = Post;
                trigger OnAction()
                var
                    PostingEngine: Codeunit "Rebate Posting Engine";
                begin
                    PostingEngine.PostOpenAccruals(Rec."Agreement No.");
                end;
            }
        }
    }
}

page 50110 "Rebate Settlement List"
{
    PageType = List;
    SourceTable = "Rebate Settlement Header";
    CardPageId = "Rebate Settlement Card";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Output Type"; Rec."Output Type") { ApplicationArea = All; }
            }
        }
    }
}

page 50111 "Rebate Settlement Card"
{
    PageType = Card;
    SourceTable = "Rebate Settlement Header";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; Editable = false; }
                field("Output Type"; Rec."Output Type") { ApplicationArea = All; }
            }
            part(Lines; "Rebate Settlement Lines") { ApplicationArea = All; SubPageLink = "Settlement No." = field("No."); }
        }
    }

    actions
    {
        area(processing)
        {
            action(Approve)
            {
                ApplicationArea = All;
                Image = Approve;
                trigger OnAction()
                var
                    SettlementEngine: Codeunit "Rebate Settlement Engine";
                begin
                    SettlementEngine.Approve(Rec);
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Image = Post;
                trigger OnAction()
                var
                    SettlementEngine: Codeunit "Rebate Settlement Engine";
                begin
                    SettlementEngine.Post(Rec);
                end;
            }
        }
    }
}

page 50112 "Rebate Settlement Lines"
{
    PageType = ListPart;
    SourceTable = "Rebate Settlement Line";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Accrual Entry No."; Rec."Accrual Entry No.") { ApplicationArea = All; }
                field("Original Amount"; Rec."Original Amount") { ApplicationArea = All; }
                field("Settlement Amount"; Rec."Settlement Amount") { ApplicationArea = All; }
                field("Adjustment Reason Code"; Rec."Adjustment Reason Code") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
            }
        }
    }
}

page 50113 "Rebate Audit Entries"
{
    PageType = List;
    SourceTable = "Rebate Audit Entry";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Created DateTime"; Rec."Created DateTime") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field(Action; Rec.Action) { ApplicationArea = All; }
                field("Table ID"; Rec."Table ID") { ApplicationArea = All; }
                field("Record ID Text"; Rec."Record ID Text") { ApplicationArea = All; }
                field("Old Value"; Rec."Old Value") { ApplicationArea = All; }
                field("New Value"; Rec."New Value") { ApplicationArea = All; }
                field("Reason Code"; Rec."Reason Code") { ApplicationArea = All; }
            }
        }
    }
}

page 50114 "Rebate Job Monitor"
{
    PageType = List;
    SourceTable = "Rebate Job Log";
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Chunk No."; Rec."Chunk No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Resume Key"; Rec."Resume Key") { ApplicationArea = All; }
                field("Processed Count"; Rec."Processed Count") { ApplicationArea = All; }
                field("Failed Count"; Rec."Failed Count") { ApplicationArea = All; }
                field("Error Category"; Rec."Error Category") { ApplicationArea = All; }
                field("User Message"; Rec."User Message") { ApplicationArea = All; }
                field("Retry Eligible"; Rec."Retry Eligible") { ApplicationArea = All; }
            }
        }
    }
}

page 50115 "Rebate Integration Logs"
{
    PageType = List;
    SourceTable = "Rebate Integration Log";
    ApplicationArea = All;
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("External Reference ID"; Rec."External Reference ID") { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field(Operation; Rec.Operation) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Error Category"; Rec."Error Category") { ApplicationArea = All; }
                field("User Message"; Rec."User Message") { ApplicationArea = All; }
                field("Retry Eligible"; Rec."Retry Eligible") { ApplicationArea = All; }
                field("Related Record"; Rec."Related Record") { ApplicationArea = All; }
                field("Credential Secret Ref."; Rec."Credential Secret Ref.") { ApplicationArea = All; }
            }
        }
    }
}

page 50116 "Rebate Reconciliation"
{
    PageType = List;
    SourceTable = "Rebate Reconciliation Entry";
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Agreement No."; Rec."Agreement No.") { ApplicationArea = All; }
                field("Calculation Entry No."; Rec."Calculation Entry No.") { ApplicationArea = All; }
                field("Accrual Entry No."; Rec."Accrual Entry No.") { ApplicationArea = All; }
                field("Settlement No."; Rec."Settlement No.") { ApplicationArea = All; }
                field("Calculated Amount"; Rec."Calculated Amount") { ApplicationArea = All; }
                field("Posted Amount"; Rec."Posted Amount") { ApplicationArea = All; }
                field(Variance; Rec.Variance) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
            }
        }
    }
}

page 50117 "Rebate Agreement API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebates';
    APIVersion = 'v1.0';
    EntityName = 'rebateAgreement';
    EntitySetName = 'rebateAgreements';
    SourceTable = "Rebate Agreement Header";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(no; Rec."No.") { Caption = 'no'; }
                field(agreementType; Rec."Agreement Type") { Caption = 'agreementType'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(vendorNo; Rec."Vendor No.") { Caption = 'vendorNo'; }
                field(customerNo; Rec."Customer No.") { Caption = 'customerNo'; }
                field(startingDate; Rec."Starting Date") { Caption = 'startingDate'; }
                field(endingDate; Rec."Ending Date") { Caption = 'endingDate'; }
            }
        }
    }
}

page 50118 "Rebate Calculation API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebates';
    APIVersion = 'v1.0';
    EntityName = 'rebateCalculationRequest';
    EntitySetName = 'rebateCalculationRequests';
    SourceTable = "Rebate Calculation Request";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(no; Rec."No.") { Caption = 'no'; }
                field(agreementNo; Rec."Agreement No.") { Caption = 'agreementNo'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(processedCount; Rec."Processed Count") { Caption = 'processedCount'; }
                field(failedCount; Rec."Failed Count") { Caption = 'failedCount'; }
            }
        }
    }
}

page 50119 "Rebate Settlement API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebates';
    APIVersion = 'v1.0';
    EntityName = 'rebateSettlement';
    EntitySetName = 'rebateSettlements';
    SourceTable = "Rebate Settlement Header";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(no; Rec."No.") { Caption = 'no'; }
                field(agreementNo; Rec."Agreement No.") { Caption = 'agreementNo'; }
                field(status; Rec.Status) { Caption = 'status'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'currencyCode'; }
                field(amount; Rec.Amount) { Caption = 'amount'; }
                field(outputType; Rec."Output Type") { Caption = 'outputType'; }
            }
        }
    }
}

page 50120 "Rebate Audit API"
{
    PageType = API;
    APIPublisher = 'bsbench';
    APIGroup = 'rebates';
    APIVersion = 'v1.0';
    EntityName = 'rebateAuditEntry';
    EntitySetName = 'rebateAuditEntries';
    SourceTable = "Rebate Audit Entry";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(entryNo; Rec."Entry No.") { Caption = 'entryNo'; }
                field(createdDateTime; Rec."Created DateTime") { Caption = 'createdDateTime'; }
                field(userId; Rec."User ID") { Caption = 'userId'; }
                field(action; Rec.Action) { Caption = 'action'; }
                field(tableId; Rec."Table ID") { Caption = 'tableId'; }
                field(recordIdText; Rec."Record ID Text") { Caption = 'recordIdText'; }
                field(oldValue; Rec."Old Value") { Caption = 'oldValue'; }
                field(newValue; Rec."New Value") { Caption = 'newValue'; }
            }
        }
    }
}
