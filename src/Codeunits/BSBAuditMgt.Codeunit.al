codeunit 50300 "BSB Audit Mgt"
{
    procedure Log(ActionText: Text[80]; RecordText: Text[250]; OldValue: Text[250]; NewValue: Text[250]; ReasonCode: Code[20]; SourceReference: Text[100]; Details: Text[250])
    var
        AuditEntry: Record "BSB Audit Entry";
    begin
        AuditEntry.Init();
        AuditEntry."Date Time" := CurrentDateTime();
        AuditEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditEntry."User ID"));
        AuditEntry.Action := ActionText;
        AuditEntry."Record ID Text" := RecordText;
        AuditEntry."Old Value" := OldValue;
        AuditEntry."New Value" := NewValue;
        AuditEntry."Reason Code" := ReasonCode;
        AuditEntry."Source Reference" := SourceReference;
        AuditEntry."Technical Details" := Details;
        AuditEntry.Insert(true);
    end;
}
