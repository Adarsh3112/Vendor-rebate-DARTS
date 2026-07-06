table 50104 "RBT Rebate Rule"
{
    Caption = 'RBT Rebate Rule';
    DataClassification = CustomerContent;
    LookupPageId = "RBT Rebate Rules";
    DrillDownPageId = "RBT Rebate Rules";

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            NotBlank = true;
            // TableRelation is intentionally omitted to support both RBT Agreement Header and RBT Rebate Agreement
        }
        field(2; "Rule No."; Integer)
        {
            Caption = 'Rule No.';
            MinValue = 1;
        }
        field(10; Basis; Enum "RBT Rebate Basis")
        {
            Caption = 'Basis';
        }
        field(20; "Calculation Method"; Enum "RBT Rebate Calc Method")
        {
            Caption = 'Calculation Method';
        }
        field(30; "Value"; Decimal)
        {
            Caption = 'Value';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(40; "Inclusion Criteria"; Blob)
        {
            Caption = 'Inclusion Criteria';
            SubType = UserDefined;
        }
        field(50; "Exclusion Criteria"; Blob)
        {
            Caption = 'Exclusion Criteria';
            SubType = UserDefined;
        }
        field(60; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Rule No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        AgreementHeader: Record "RBT Agreement Header";
        RebateAgreement: Record "RBT Rebate Agreement";
        IsDraft: Boolean;
        AgreementStatus: Text;
    begin
        TestField("Agreement No.");
        
        if AgreementHeader.Get("Agreement No.") then begin
            IsDraft := AgreementHeader.Status = AgreementHeader.Status::Draft;
            AgreementStatus := Format(AgreementHeader.Status);
        end else if RebateAgreement.Get("Agreement No.") then begin
            IsDraft := RebateAgreement.Status = RebateAgreement.Status::Draft;
            AgreementStatus := Format(RebateAgreement.Status);
        end else
            Error(AgreementMissingErr, "Agreement No.");

        // Auto-assign sequential Rule No. when caller does not provide one.
        if "Rule No." = 0 then
            "Rule No." := NextRuleNo("Agreement No.");

        // Lock structural edits once the parent agreement is non-draft.
        if not IsDraft then
            Error(AgreementNotDraftErr, "Agreement No.", AgreementStatus);
    end;

    trigger OnModify()
    var
        AgreementHeader: Record "RBT Agreement Header";
        RebateAgreement: Record "RBT Rebate Agreement";
        OldRec: Record "RBT Rebate Rule";
        IsDraft: Boolean;
        AgreementStatus: Text;
    begin
        if not OldRec.Get("Agreement No.", "Rule No.") then
            exit;

        if AgreementHeader.Get("Agreement No.") then begin
            IsDraft := AgreementHeader.Status = AgreementHeader.Status::Draft;
            AgreementStatus := Format(AgreementHeader.Status);
        end else if RebateAgreement.Get("Agreement No.") then begin
            IsDraft := RebateAgreement.Status = RebateAgreement.Status::Draft;
            AgreementStatus := Format(RebateAgreement.Status);
        end else
            exit;

        if IsDraft then
            exit;

        // Once the parent agreement leaves Draft, the rule definition is locked
        // for all status values that represent a binding commitment.
        if ("Basis" <> OldRec."Basis") or
           ("Calculation Method" <> OldRec."Calculation Method") or
           ("Value" <> OldRec."Value") then
            Error(LockedErr, "Rule No.", "Agreement No.", AgreementStatus);
    end;

    trigger OnDelete()
    var
        AgreementHeader: Record "RBT Agreement Header";
        RebateAgreement: Record "RBT Rebate Agreement";
        IsDraft: Boolean;
        AgreementStatus: Text;
    begin
        if AgreementHeader.Get("Agreement No.") then begin
            IsDraft := AgreementHeader.Status = AgreementHeader.Status::Draft;
            AgreementStatus := Format(AgreementHeader.Status);
        end else if RebateAgreement.Get("Agreement No.") then begin
            IsDraft := RebateAgreement.Status = RebateAgreement.Status::Draft;
            AgreementStatus := Format(RebateAgreement.Status);
        end else
            exit;

        if not IsDraft then
            Error(DeleteLockedErr, "Rule No.", "Agreement No.", AgreementStatus);
    end;

    var
        AgreementMissingErr: Label 'Agreement %1 does not exist. Create the agreement header before defining rebate rules.';
        AgreementNotDraftErr: Label 'Rebate rules can only be added to agreement %1 while it is in Draft status (current status: %2). Reopen or revise the agreement before adding rules.';
        LockedErr: Label 'Rule %1 on agreement %2 cannot be modified because the agreement status is %3. Reopen the agreement to Draft to revise rules.';
        DeleteLockedErr: Label 'Rule %1 on agreement %2 cannot be deleted because the agreement status is %3. Reopen the agreement to Draft to remove rules.';

    /// <summary>
    /// Returns the next sequential Rule No. for the supplied agreement.
    /// Rule numbering is per-agreement and starts at 1.
    /// </summary>
    procedure NextRuleNo(AgreementNo: Code[20]): Integer
    var
        Rule: Record "RBT Rebate Rule";
    begin
        Rule.SetRange("Agreement No.", AgreementNo);
        if Rule.FindLast() then
            exit(Rule."Rule No." + 1);
        exit(1);
    end;

    /// <summary>
    /// Writes the supplied filter / JSON criteria string into the Inclusion Criteria blob.
    /// </summary>
    procedure SetInclusionCriteria(CriteriaText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Inclusion Criteria");
        "Inclusion Criteria".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(CriteriaText);
        Modify();
    end;

    /// <summary>
    /// Reads the Inclusion Criteria blob into a Text value.
    /// </summary>
    procedure GetInclusionCriteria(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Inclusion Criteria");
        if not "Inclusion Criteria".HasValue() then
            exit('');
        "Inclusion Criteria".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
        exit(Result);
    end;

    /// <summary>
    /// Writes the supplied filter / JSON criteria string into the Exclusion Criteria blob.
    /// </summary>
    procedure SetExclusionCriteria(CriteriaText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Exclusion Criteria");
        "Exclusion Criteria".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(CriteriaText);
        Modify();
    end;

    /// <summary>
    /// Reads the Exclusion Criteria blob into a Text value.
    /// </summary>
    procedure GetExclusionCriteria(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Exclusion Criteria");
        if not "Exclusion Criteria".HasValue() then
            exit('');
        "Exclusion Criteria".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
        exit(Result);
    end;
}
