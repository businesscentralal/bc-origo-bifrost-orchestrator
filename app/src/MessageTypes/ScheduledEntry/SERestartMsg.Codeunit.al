/// <summary>
/// Implements the Orchestrator.Entry.Restart message type: restarts a failed or held
/// orchestrator entry by re-enqueuing it.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035556 "SE Restart Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Restart a failed or held orchestrator entry.', Comment = 'is-IS=EndurrÃ¦sa Ã¡Ã¦tlunarfÃ¦rslu sem mistÃ³kst eÃ°a er Ã­ biÃ°.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'restart orchestrator entry, retry entry, requeue entry, restart failed schedule', Comment = 'is-IS=endurræsa áætlunarfærslu, reyna færslu aftur, setja færslu aftur í bið, endurræsa bilaða áætlun';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Restart a failed or held orchestrator entry according to its retry policy. Write operation. Use Orchestrator.Entry.Run for a one-time foreground run.', Comment = 'is-IS=Endurræstu bilaða eða stöðvaða áætlunarfærslu samkvæmt endurtekningarstefnu hennar. Skrifaðgerð. Notaðu Orchestrator.Entry.Run fyrir einskiptis keyrslu í forgrunni.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Scheduled Entry SystemId in data.id or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.Target('data.id, subject', 'guid', 'The Scheduled Entry SystemId.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'Scheduled Entry SystemId.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'Scheduled Entry SystemId.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Whether the entry is blocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Restart result.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Scheduled Entry');
        Parts.AddRuntimeError(Errors, 'The entry cannot be restarted.', 'Check its retry policy, blocked state and scheduler setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Requeues the orchestrator entry and applies retry and notification rules.', false, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Entry.Run', 'Use this to run once without changing the recurring schedule.');
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
        Parts.Example(Examples, 'Restart an entry', '{"type":"Orchestrator.Entry.Restart","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","message":"Orchestrator entry restarted."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Restarts a failed or held orchestrator entry by applying its retry policy and notification rules.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'This operation requeues the entry; use Entry.Run when the recurring schedule must remain untouched.';
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
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    /// <param name="Argument">Message argument that receives the help text as response.</param>
    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Entry.Restart'));
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRestart(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
