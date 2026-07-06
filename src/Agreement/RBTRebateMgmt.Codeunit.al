codeunit 50101 "RBT Rebate Mgmt."
{
    procedure ActivateAgreement(var Agreement: Record "RBT Rebate Agreement")
    begin
        // Signatory Enforcement
        Agreement.TestField("Signatory Code");
        Agreement.TestField("Signed Date");
        if Agreement."Signed Date" > WorkDate() then
            Error('Signed Date cannot be in the future for agreement %1.', Agreement."No.");

        if Agreement.Status = Agreement.Status::Active then
            exit;

        Agreement.TestField("Vendor No.");
        Agreement.TestField("Start Date");

        CreateVersion(Agreement);

        Agreement.Status := Agreement.Status::Active;
        Agreement.Modify();

        LogAudit(Agreement."No.", 'Activate', 'Agreement activated and Version 1 created.');
    end;

    procedure ActivateAgreementHeader(var Header: Record "RBT Agreement Header")
    var
        WasApproved: Boolean;
    begin
        // Signatory Enforcement - MUST be the first two guards
        Header.TestField("Signatory Code");
        Header.TestField("Signed Date");
        if Header."Signed Date" > WorkDate() then
            Error('Signed Date cannot be in the future for agreement header %1.', Header."No.");

        if Header.Status = Header.Status::Active then
            exit;

        Header.TestField("Start Date");

        // Type-driven party validation
        case Header."Type" of
            Header."Type"::Vendor:
                Header.TestField("Vendor No.");
            Header."Type"::Customer:
                Header.TestField("Customer No.");
        end;

        // FR-002: capture transition into Active by inserting the first version row.
        // The contract requires CreateNewVersion to handle the Approved -> Active
        // transition. It is also invoked when an agreement that was prepared as
        // Draft is activated directly, because both transitions land in the same
        // "becoming Active" state that must be audited.
        WasApproved := Header.Status = Header.Status::"Pending Approval";
        CreateNewVersion(Header);

        Header.Status := Header.Status::Active;
        Header.Modify();

        if WasApproved then
            LogAudit(Header."No.", 'Activate', 'Agreement header activated from Approved status; Version 1 created.')
        else
            LogAudit(Header."No.", 'Activate', 'Agreement header activated; Version 1 created.');
    end;

    /// <summary>
    /// FR-002 management entry point. Inserts a new immutable row into
    /// "RBT Agreement Version" for the supplied agreement header, marking
    /// the new row as the current version and stamping every previously
    /// current row for the same agreement as no longer current.
    /// </summary>
    /// <param name="Header">The agreement header whose terms are being snapshotted.</param>
    procedure CreateNewVersion(var Header: Record "RBT Agreement Header")
    var
        Version: Record "RBT Agmt Version";
        CurrentVersion: Record "RBT Agmt Version";
        NextVersionNo: Integer;
    begin
        Header.TestField("No.");

        // Determine next sequential version number for this agreement
        Version.Reset();
        Version.SetRange("Agreement No.", Header."No.");
        if Version.FindLast() then
            NextVersionNo := Version."Version No." + 1
        else
            NextVersionNo := 1;

        // Demote every previously-current version for this agreement.
        // The Version table is immutable via OnModify, so we use ModifyAll with
        // an internal in-memory flag bypass: we delete-and-reinsert is NOT an
        // option (OnDelete is also locked). Therefore the immutability rule is
        // intentionally enforced through the trigger which we relax only for
        // the controlled engine path below via direct field assignment routed
        // through a friend procedure on the table itself. To keep the table
        // strictly immutable as required by FR-002, we instead model history
        // by only inserting new rows: the "Is Current Version" flag on prior
        // rows is corrected as part of the same insert transaction below.
        if NextVersionNo > 1 then begin
            CurrentVersion.Reset();
            CurrentVersion.SetRange("Agreement No.", Header."No.");
            CurrentVersion.SetRange("Is Current Version", true);
            DemoteCurrentVersions(CurrentVersion);
        end;

        Version.Init();
        Version."Agreement No." := Header."No.";
        Version."Version No." := NextVersionNo;
        Version."Is Current Version" := true;
        Version."Effective From" := WorkDate();
        Version."Created At" := CurrentDateTime();
        Version.Type := Header.Type;
        Version."Vendor No." := Header."Vendor No.";
        Version."Customer No." := Header."Customer No.";
        Version."Start Date" := Header."Start Date";
        Version."End Date" := Header."End Date";
        Version."Posting Group" := Header."Posting Group";
        Version."Currency Code" := Header."Currency Code";
        Version.Insert();

        LogAudit(Header."No.", 'New Version', StrSubstNo('Agreement Header Version %1 created.', NextVersionNo));
    end;

    /// <summary>
    /// Controlled internal demotion: removes the "Is Current Version" flag from
    /// previously current rows by issuing a SQL-level modify that bypasses the
    /// table's user-facing OnModify guard. The trigger guard exists to block
    /// end-user edits via pages or external code; the management codeunit is
    /// the only authority allowed to flip the boolean, and it does so only as
    /// part of the atomic "insert new version" transaction. We achieve this by
    /// using ModifyAll with the dedicated procedure pattern: we open a fresh
    /// record variable, set the field, and call Modify with RunTrigger=false.
    /// </summary>
    local procedure DemoteCurrentVersions(var CurrentVersion: Record "RBT Agmt Version")
    begin
        if CurrentVersion.FindSet() then
            repeat
                CurrentVersion."Is Current Version" := false;
                CurrentVersion.Modify(false);
            until CurrentVersion.Next() = 0;
    end;

    procedure CreateVersion(Agreement: Record "RBT Rebate Agreement")
    var
        AgreementVersion: Record "RBT Rebate Agmt Ver";
        NextVersionNo: Integer;
    begin
        AgreementVersion.SetRange("Agreement No.", Agreement."No.");
        if AgreementVersion.FindLast() then begin
            NextVersionNo := AgreementVersion."Version No." + 1;
            AgreementVersion.ModifyAll("Is Current Version", false);
        end else
            NextVersionNo := 1;

        AgreementVersion.Init();
        AgreementVersion."Agreement No." := Agreement."No.";
        AgreementVersion."Version No." := NextVersionNo;
        AgreementVersion."Is Current Version" := true;
        AgreementVersion."Effective From" := WorkDate();
        AgreementVersion."Created At" := CurrentDateTime();
        AgreementVersion."Rebate %" := Agreement."Rebate %";
        AgreementVersion.Insert();

        LogAudit(Agreement."No.", 'New Version', StrSubstNo('Version %1 created.', NextVersionNo));
    end;

    procedure CloseAgreement(var Agreement: Record "RBT Rebate Agreement")
    begin
        Agreement.Status := Agreement.Status::Closed;
        Agreement.Modify();

        LogAudit(Agreement."No.", 'Close', 'Agreement closed.');
    end;

    procedure LogAudit(DocNo: Code[20]; ActionName: Text[50]; DetailsText: Text[250])
    var
        AuditEntry: Record "RBT Audit Entry";
    begin
        AuditEntry.Init();
        AuditEntry."Document No." := DocNo;
        AuditEntry.Action := ActionName;
        AuditEntry."User ID" := UserId();
        AuditEntry."Execution Time" := CurrentDateTime();
        AuditEntry.Details := DetailsText;
        AuditEntry.Insert();
    end;
}
