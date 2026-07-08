codeunit 50301 "BSB Error Handler"
{
    procedure LogError(Category: Enum "BSB Error Category"; UserMessage: Text[250]; TechnicalDetails: Text[250]; RelatedRecord: Text[100]; RetryEligible: Boolean): Integer
    var
        ErrorEntry: Record "BSB Error Entry";
    begin
        ErrorEntry.Init();
        ErrorEntry.Category := Category;
        ErrorEntry."User Message" := UserMessage;
        ErrorEntry."Technical Details" := TechnicalDetails;
        ErrorEntry."Related Record" := RelatedRecord;
        ErrorEntry."Retry Eligible" := RetryEligible;
        ErrorEntry."Date Time" := CurrentDateTime();
        ErrorEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ErrorEntry."User ID"));
        ErrorEntry.Status := ErrorEntry.Status::Open;
        ErrorEntry.Insert(true);
        exit(ErrorEntry."Entry No.");
    end;
}
