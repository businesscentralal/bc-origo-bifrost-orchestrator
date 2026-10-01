/// <summary>
/// Implements the Orchestrator.Entry.Run message type: executes an orchestrator entry
/// immediately as a one-time foreground run.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035555 "SE Run Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    /// <returns>True; this message type is always enabled.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    /// <returns>Zero; this message type is not bound to a table.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    /// <returns>Description text.</returns>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Execute a orchestrator entry immediately as a one-time run.', Comment = 'is-IS=Keyra Ã¡Ã¦tlunarfÃ¦rslu strax Ã­ eitt skipti.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'run entry, execute entry, run scheduled entry, execute job queue entry, run now', Comment = 'is-IS=keyra færslu, framkvæma færslu, keyra áætlaða færslu, framkvæma vinnsluröðarfærslu, keyra núna';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Run an orchestrator entry once immediately. Irreversible. Use Orchestrator.Entry.Restart to requeue a failed entry instead.', Comment = 'is-IS=Keyra áætlunarfærslu einu sinni strax. Óafturkræft. Notaðu Orchestrator.Entry.Restart til að setja bilaða færslu aftur í bið.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Scheduled Entry SystemId, supplied in data.id or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.ScheduledEntryTarget();
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'SystemId, or ID, of the Scheduled Entry ori. Required unless subject carries it.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success when the job completed, Error when it failed.');
        Parts.AddResponseField(Fields, 'id', 'string', 'SystemId of the Scheduled Entry ori.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Whether the entry is blocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Job queue entry executed. on Success; the run''s error text on Error.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddScheduledEntryErrors(Errors);
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Effect := Parts.CommittingEffect('Runs the entry''s job once through a one-time Job Queue Entry and commits, on the success and on the error path.', false);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Entry.Restart', 'Use this when the entry failed and should be requeued instead of run in the foreground.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Run an entry', '{"type":"Orchestrator.Entry.Run","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","blocked":false,"message":"Job queue entry executed."}');
        Parts.Example(Examples, 'A run that fails', '{"type":"Orchestrator.Entry.Run","subject":"<systemId>"}', '{"status":"Error","id":"<systemId>","blocked":false,"message":"<error text>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Runs one orchestrator entry immediately in the caller session. The recurring schedule is retained.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The entry runs headlessly, with no confirmation dialog, through a one-time non-recurring copy of its Job Queue Entry; the entry''s own schedule and Job Queue Entry are left alone. A failed run is not an error answer: the response has status Error and the run''s error text in message.';
        exit(true);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    /// <returns>Outbound direction.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRun(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
