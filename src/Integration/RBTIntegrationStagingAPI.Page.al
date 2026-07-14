page 50117 "RBT Integration Staging API"
{
    // Sole external ingress endpoint for the Integration Framework. External systems
    // POST payloads to this API page; OnInsertRecord routes through RBT Integration
    // Mgt.Ingest so idempotency by (sourceSystem, externalId) is enforced BC-side.
    // OnModifyRecord returns FALSE - external callers cannot mutate staging rows.
    // The page references only RBT Integration Staging; the RBT Rebate Agreement is
    // reached only via the management codeunit's Promote procedure.

    PageType = API;
    APIPublisher = 'darts';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'integrationStaging';
    EntitySetName = 'integrationStagings';
    SourceTable = "RBT Integration Staging";
    DelayedInsert = true;
    Editable = true;
    ODataKeyFields = SystemId;
    Caption = 'RBT Integration Staging API';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'entryNo';
                    Editable = false;
                }
                field(externalId; Rec."External ID")
                {
                    Caption = 'externalId';
                }
                field(sourceSystem; Rec."Source System")
                {
                    Caption = 'sourceSystem';
                }
                field(status; Rec.Status)
                {
                    Caption = 'status';
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'errorMessage';
                    Editable = false;
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'createdAt';
                    Editable = false;
                }
                field(processedAt; Rec."Processed At")
                {
                    Caption = 'processedAt';
                    Editable = false;
                }
                field(promotedToAgreementNo; Rec."Promoted To Agreement No.")
                {
                    Caption = 'promotedToAgreementNo';
                    Editable = false;
                }
                field(payload; PayloadBuffer)
                {
                    Caption = 'payload';

                    trigger OnValidate()
                    begin
                        PayloadDirty := true;
                    end;
                }
            }
        }
    }

    var
        PayloadBuffer: Text;
        PayloadDirty: Boolean;

    trigger OnAfterGetRecord()
    begin
        PayloadBuffer := Rec.GetPayload();
        PayloadDirty := false;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PayloadBuffer := '';
        PayloadDirty := false;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        IntegrationMgt: Codeunit "RBT Integration Mgt.";
        Existing: Record "RBT Integration Staging";
    begin
        // Silent-acknowledge idempotency. If Ingest returns FALSE the row already exists;
        // load its state into Rec and return FALSE so the API caller receives 200/201 for
        // an existing entity rather than a duplicate-key error.
        if not IntegrationMgt.Ingest(Rec."Source System", Rec."External ID", PayloadBuffer, Existing) then begin
            Rec := Existing;
            exit(false);
        end;
        // Ingest already inserted the row. Load its state into Rec so the response body
        // reflects the newly created entity, and suppress the platform's own insert.
        Rec := Existing;
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        // External callers must not modify existing staging rows. Any state change
        // (Status, Error Message, Processed At, Promoted To Agreement No.) is set
        // by RBT Integration Mgt. only.
        exit(false);
    end;
}
