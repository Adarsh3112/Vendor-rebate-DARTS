codeunit 50116 "RBT Integration Mgt."
{
    // Management codeunit for the Integration Framework staging pipeline.
    //
    // Public procedures:
    //   Ingest    - silent-acknowledge idempotent insert keyed on (Source System, External ID)
    //   Promote   - parses the payload and creates one RBT Rebate Agreement, wrapped in
    //               a Codeunit.Run error-trap so a failure rolls back the agreement insert
    //               and captures the error text into the staging row.
    //   Reprocess - clears Error Message + Status back to New, then calls Promote.
    //
    // OnRun runs Promote's raw side-effecting body so it can be invoked via Codeunit.Run
    // with automatic transactional rollback on failure.

    TableNo = "RBT Integration Staging";

    trigger OnRun()
    begin
        DoPromote(Rec);
    end;

    var
        MissingRequiredFieldErr: Label 'On staging row %1, the payload is missing required field "%2".', Comment = '%1 = Entry No.; %2 = field name';
        UnknownAgreementTypeErr: Label 'On staging row %1, agreement type "%2" is not recognised. Allowed values: VendorRebate, CustomerIncentive.', Comment = '%1 = Entry No.; %2 = supplied type token';
        InvalidDateErr: Label 'On staging row %1, field "%2" is not a valid ISO date (yyyy-MM-dd).', Comment = '%1 = Entry No.; %2 = field name';

    /// <summary>
    /// Idempotent ingest. When (Source System, External ID) already exists, loads the
    /// existing row into StagingRec and returns FALSE. When no row exists, inserts a
    /// new one with Status = New and returns TRUE.
    /// </summary>
    procedure Ingest(SourceSystem: Code[20]; ExternalID: Code[50]; PayloadText: Text; var StagingRec: Record "RBT Integration Staging"): Boolean
    var
        Existing: Record "RBT Integration Staging";
    begin
        Existing.SetCurrentKey("Source System", "External ID");
        Existing.SetRange("Source System", SourceSystem);
        Existing.SetRange("External ID", ExternalID);
        if Existing.FindFirst() then begin
            StagingRec := Existing;
            exit(false);
        end;

        StagingRec.Init();
        StagingRec."Entry No." := 0;
        StagingRec."Source System" := SourceSystem;
        StagingRec."External ID" := ExternalID;
        StagingRec.Status := StagingRec.Status::New;
        StagingRec."Created At" := CurrentDateTime();
        StagingRec.Insert(true);
        StagingRec.SetPayload(PayloadText);
        StagingRec.SetAllowInternalEdit(true);
        StagingRec.Modify();
        StagingRec.SetAllowInternalEdit(false);
        exit(true);
    end;

    /// <summary>
    /// Promotes a staging row into an RBT Rebate Agreement. Returns TRUE on success,
    /// FALSE if the row is not eligible (already processed, or non-New status) or if
    /// promotion failed. On failure, Status is set to Error and Error Message is
    /// populated; the underlying agreement insert is rolled back through the
    /// Codeunit.Run error-trap boundary.
    /// </summary>
    procedure Promote(var StagingRec: Record "RBT Integration Staging"): Boolean
    var
        Handler: Codeunit "RBT Integration Mgt.";
        LastError: Text;
    begin
        // Guard - only New rows without an existing promoted agreement are eligible.
        if StagingRec.Status <> StagingRec.Status::New then
            exit(false);
        if StagingRec."Promoted To Agreement No." <> '' then
            exit(false);

        // Flip Status to Processing so an interrupted run leaves a diagnosable state.
        StagingRec.SetAllowInternalEdit(true);
        StagingRec.Status := StagingRec.Status::Processing;
        StagingRec.Modify();
        StagingRec.SetAllowInternalEdit(false);

        Commit();

        // Run the raw promotion body through Codeunit.Run - any error inside DoPromote
        // rolls back the RBT Rebate Agreement insert and any staging mutation
        // performed inside the OnRun boundary.
        Clear(Handler);
        if Handler.Run(StagingRec) then begin
            // Re-read the staging row - OnRun stamped success fields.
            StagingRec.Get(StagingRec."Entry No.");
            exit(true);
        end;

        LastError := GetLastErrorText();
        if LastError = '' then
            LastError := 'Unknown promotion failure.';

        StagingRec.Get(StagingRec."Entry No.");
        StagingRec.SetAllowInternalEdit(true);
        StagingRec.Status := StagingRec.Status::Error;
        StagingRec."Error Message" := CopyStr(LastError, 1, MaxStrLen(StagingRec."Error Message"));
        StagingRec."Processed At" := CurrentDateTime();
        StagingRec.Modify();
        StagingRec.SetAllowInternalEdit(false);
        exit(false);
    end;

    /// <summary>
    /// Resets the staging row to New (clearing any previous error) and re-runs Promote.
    /// </summary>
    procedure Reprocess(var StagingRec: Record "RBT Integration Staging")
    begin
        if StagingRec."Promoted To Agreement No." <> '' then
            exit;
        StagingRec.SetAllowInternalEdit(true);
        StagingRec.Status := StagingRec.Status::New;
        StagingRec."Error Message" := '';
        StagingRec."Processed At" := 0DT;
        StagingRec.Modify();
        StagingRec.SetAllowInternalEdit(false);
        Promote(StagingRec);
    end;

    /// <summary>
    /// Raw promotion body - parses the payload and creates the Rebate Agreement.
    /// Executed inside the Codeunit.Run boundary of Promote so any error rolls back.
    /// </summary>
    local procedure DoPromote(var StagingRec: Record "RBT Integration Staging")
    var
        Agreement: Record "RBT Rebate Agreement";
        PayloadText: Text;
        DescriptionValue: Text;
        TypeToken: Text;
        VendorNoValue: Code[20];
        CustomerNoValue: Code[20];
        StartDateValue: Date;
        EndDateValue: Date;
        CurrencyCodeValue: Code[10];
        PostingGroupValue: Code[20];
        AgreementType: Enum "RBT Agreement Type";
    begin
        PayloadText := StagingRec.GetPayload();

        // Mandatory fields.
        TypeToken := ExtractRequiredField(StagingRec, PayloadText, 'type');
        AgreementType := ParseAgreementType(StagingRec, TypeToken);

        DescriptionValue := ExtractOptionalField(PayloadText, 'description');
        VendorNoValue := CopyStr(ExtractOptionalField(PayloadText, 'vendorNo'), 1, MaxStrLen(VendorNoValue));
        CustomerNoValue := CopyStr(ExtractOptionalField(PayloadText, 'customerNo'), 1, MaxStrLen(CustomerNoValue));
        CurrencyCodeValue := CopyStr(ExtractOptionalField(PayloadText, 'currencyCode'), 1, MaxStrLen(CurrencyCodeValue));
        PostingGroupValue := CopyStr(ExtractOptionalField(PayloadText, 'postingGroup'), 1, MaxStrLen(PostingGroupValue));

        StartDateValue := ParseIsoDate(StagingRec, ExtractOptionalField(PayloadText, 'startDate'), 'startDate');
        EndDateValue := ParseIsoDate(StagingRec, ExtractOptionalField(PayloadText, 'endDate'), 'endDate');

        // Create the Rebate Agreement. OnInsert(true) draws the No. from RBT-AGR.
        Agreement.Init();
        Agreement."No." := '';
        Agreement.Insert(true);
        Agreement.Description := CopyStr(DescriptionValue, 1, MaxStrLen(Agreement.Description));
        Agreement."Type" := AgreementType;
        if VendorNoValue <> '' then
            Agreement."Vendor No." := VendorNoValue;
        if CustomerNoValue <> '' then
            Agreement."Customer No." := CustomerNoValue;
        if StartDateValue <> 0D then
            Agreement."Start Date" := StartDateValue;
        if EndDateValue <> 0D then
            Agreement."End Date" := EndDateValue;
        if CurrencyCodeValue <> '' then
            Agreement."Currency Code" := CurrencyCodeValue;
        if PostingGroupValue <> '' then
            Agreement."Posting Group" := PostingGroupValue;
        Agreement.Modify();

        // Stamp the staging row.
        StagingRec.SetAllowInternalEdit(true);
        StagingRec.Status := StagingRec.Status::Processed;
        StagingRec."Processed At" := CurrentDateTime();
        StagingRec."Promoted To Agreement No." := Agreement."No.";
        StagingRec."Error Message" := '';
        StagingRec.Modify();
        StagingRec.SetAllowInternalEdit(false);
    end;

    local procedure ExtractRequiredField(var StagingRec: Record "RBT Integration Staging"; PayloadText: Text; FieldName: Text): Text
    var
        Value: Text;
    begin
        Value := ExtractOptionalField(PayloadText, FieldName);
        if Value = '' then
            Error(MissingRequiredFieldErr, StagingRec."Entry No.", FieldName);
        exit(Value);
    end;

    /// <summary>
    /// Extract the value for a key from a JSON-lite key:value payload. Supports both
    /// double-quoted JSON ("key": "value") and simple key=value line-oriented text.
    /// Returns '' if the key is not present.
    /// </summary>
    local procedure ExtractOptionalField(PayloadText: Text; FieldName: Text): Text
    var
        SearchToken: Text;
        StartPos: Integer;
        EndPos: Integer;
        Chunk: Text;
        Value: Text;
    begin
        if PayloadText = '' then
            exit('');

        // Try JSON-style: "FieldName": "value"
        SearchToken := '"' + FieldName + '"';
        StartPos := StrPos(PayloadText, SearchToken);
        if StartPos > 0 then begin
            Chunk := CopyStr(PayloadText, StartPos + StrLen(SearchToken));
            // Skip whitespace + colon.
            StartPos := StrPos(Chunk, ':');
            if StartPos = 0 then
                exit('');
            Chunk := CopyStr(Chunk, StartPos + 1);
            Chunk := TrimLeft(Chunk);
            if CopyStr(Chunk, 1, 1) = '"' then begin
                Chunk := CopyStr(Chunk, 2);
                EndPos := StrPos(Chunk, '"');
                if EndPos = 0 then
                    exit('');
                Value := CopyStr(Chunk, 1, EndPos - 1);
                exit(Value);
            end;
            // Unquoted numeric/token value - up to comma, brace, or newline.
            EndPos := FindFirstDelimiter(Chunk);
            if EndPos = 0 then
                exit(TrimBoth(Chunk));
            exit(TrimBoth(CopyStr(Chunk, 1, EndPos - 1)));
        end;

        // Fallback line-oriented: FieldName=value
        SearchToken := FieldName + '=';
        StartPos := StrPos(PayloadText, SearchToken);
        if StartPos > 0 then begin
            Chunk := CopyStr(PayloadText, StartPos + StrLen(SearchToken));
            EndPos := FindFirstDelimiter(Chunk);
            if EndPos = 0 then
                exit(TrimBoth(Chunk));
            exit(TrimBoth(CopyStr(Chunk, 1, EndPos - 1)));
        end;

        exit('');
    end;

    local procedure FindFirstDelimiter(Source: Text): Integer
    var
        Positions: array[4] of Integer;
        Result: Integer;
        i: Integer;
    begin
        Positions[1] := StrPos(Source, ',');
        Positions[2] := StrPos(Source, '}');
        Positions[3] := StrPos(Source, ';');
        Positions[4] := StrPos(Source, '\n');
        Result := 0;
        for i := 1 to ArrayLen(Positions) do
            if Positions[i] > 0 then
                if (Result = 0) or (Positions[i] < Result) then
                    Result := Positions[i];
        exit(Result);
    end;

    local procedure TrimLeft(Source: Text): Text
    begin
        while (StrLen(Source) > 0) and (CopyStr(Source, 1, 1) in [' ', ':']) do
            Source := CopyStr(Source, 2);
        exit(Source);
    end;

    local procedure TrimBoth(Source: Text): Text
    begin
        while (StrLen(Source) > 0) and (CopyStr(Source, 1, 1) = ' ') do
            Source := CopyStr(Source, 2);
        while (StrLen(Source) > 0) and (CopyStr(Source, StrLen(Source), 1) = ' ') do
            Source := CopyStr(Source, 1, StrLen(Source) - 1);
        exit(Source);
    end;

    local procedure ParseAgreementType(var StagingRec: Record "RBT Integration Staging"; Token: Text): Enum "RBT Agreement Type"
    var
        Result: Enum "RBT Agreement Type";
        UpperToken: Text;
    begin
        UpperToken := UpperCase(Token);
        // Normalise by stripping spaces so "Vendor Rebate" and "VendorRebate" both work.
        UpperToken := DelChr(UpperToken, '=', ' ');
        case UpperToken of
            'VENDORREBATE', 'VENDOR', 'REBATE':
                Result := Result::"Vendor Rebate";
            'CUSTOMERINCENTIVE', 'CUSTOMER', 'INCENTIVE':
                Result := Result::"Customer Incentive";
            else
                Error(UnknownAgreementTypeErr, StagingRec."Entry No.", Token);
        end;
        exit(Result);
    end;

    local procedure ParseIsoDate(var StagingRec: Record "RBT Integration Staging"; Token: Text; FieldName: Text): Date
    var
        Result: Date;
        YearPart: Integer;
        MonthPart: Integer;
        DayPart: Integer;
    begin
        if Token = '' then
            exit(0D);
        if StrLen(Token) < 10 then
            Error(InvalidDateErr, StagingRec."Entry No.", FieldName);
        if not Evaluate(YearPart, CopyStr(Token, 1, 4)) then
            Error(InvalidDateErr, StagingRec."Entry No.", FieldName);
        if not Evaluate(MonthPart, CopyStr(Token, 6, 2)) then
            Error(InvalidDateErr, StagingRec."Entry No.", FieldName);
        if not Evaluate(DayPart, CopyStr(Token, 9, 2)) then
            Error(InvalidDateErr, StagingRec."Entry No.", FieldName);
        Result := DMY2Date(DayPart, MonthPart, YearPart);
        exit(Result);
    end;
}
