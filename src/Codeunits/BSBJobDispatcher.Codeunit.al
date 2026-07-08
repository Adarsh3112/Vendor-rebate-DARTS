codeunit 50308 "BSB Job Dispatcher"
{
    procedure CreateChunk(RequestNo: Code[20]; ChunkNo: Integer; SourceFrom: Text[100]; SourceTo: Text[100])
    var
        Chunk: Record "BSB Process Chunk";
    begin
        if Chunk.Get(RequestNo, ChunkNo) then
            exit;
        Chunk.Init();
        Chunk."Request No." := RequestNo;
        Chunk."Chunk No." := ChunkNo;
        Chunk.Status := Chunk.Status::Open;
        Chunk."Source Key From" := SourceFrom;
        Chunk."Source Key To" := SourceTo;
        Chunk.Insert(true);
    end;

    procedure MarkRunning(var Chunk: Record "BSB Process Chunk")
    begin
        if Chunk.Status = Chunk.Status::Completed then
            exit;
        Chunk.Status := Chunk.Status::Running;
        Chunk."Started At" := CurrentDateTime();
        Chunk.Modify(true);
    end;

    procedure MarkCompleted(var Chunk: Record "BSB Process Chunk"; ProcessedCount: Integer)
    begin
        Chunk.Status := Chunk.Status::Completed;
        Chunk."Processed Count" := ProcessedCount;
        Chunk."Completed At" := CurrentDateTime();
        Chunk.Modify(true);
    end;

    procedure MarkFailed(var Chunk: Record "BSB Process Chunk"; ErrorText: Text[250])
    begin
        Chunk.Status := Chunk.Status::Failed;
        Chunk."Error Count" += 1;
        Chunk."Last Error" := ErrorText;
        Chunk.Modify(true);
    end;

    procedure Retry(var Chunk: Record "BSB Process Chunk")
    begin
        if Chunk.Status <> Chunk.Status::Failed then
            exit;
        Chunk."Retry Count" += 1;
        Chunk.Status := Chunk.Status::Open;
        Chunk.Modify(true);
    end;
}
