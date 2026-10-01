namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Shared contract chapters for Report, Workspace and ReportLayout messages.
/// Every error these types raise is a plain Error() that the message task answers with code
/// BusinessCentralError and the error text; the shared lookups are described here once.
/// </summary>
codeunit 10035610 "Orch B2 Contract Parts ori"
{
    Access = Internal;

    /// <summary>
    /// The envelope chapter: subject optional, version 1.0, JSON content.
    /// </summary>
    /// <param name="SubjectForms">The forms subject accepts; empty when subject is not used.</param>
    /// <param name="SubjectDescription">What subject identifies.</param>
    /// <param name="DataRequired">True when the call needs data.</param>
    /// <returns>The envelope chapter.</returns>
    internal procedure Envelope(SubjectForms: List of [Text]; SubjectDescription: Text; DataRequired: Boolean) Result: JsonObject
    var
        Subject: JsonObject;
        Forms: JsonArray;
        Form: Text;
    begin
        foreach Form in SubjectForms do
            Forms.Add(Form);
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', SubjectDescription);
        Result.Add('subject', Subject);
        Result.Add('dataRequired', DataRequired);
        Result.Add('version', '1.0');
        Result.Add('contentType', 'text/json');
    end;

    /// <summary>
    /// A target chapter with one entry.
    /// </summary>
    /// <param name="Source">Where the identifier is read.</param>
    /// <param name="Form">What it holds.</param>
    /// <param name="Description">How it is resolved.</param>
    /// <returns>The target chapter.</returns>
    internal procedure Target(Source: Text; Form: Text; Description: Text) Result: JsonArray
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Result.Add(ContractMgt.TargetEntry(Source, Form, Description));
    end;

    /// <summary>
    /// Adds a string parameter that takes one of a fixed list of values.
    /// </summary>
    /// <param name="Parameters">Receives the entry.</param>
    /// <param name="Name">The key under data.</param>
    /// <param name="Required">True when the call fails without it.</param>
    /// <param name="Description">What the parameter does.</param>
    /// <param name="AllowedValues">The accepted values.</param>
    /// <param name="DefaultValue">The value used when the key is left out; empty when there is none.</param>
    internal procedure AddChoiceParameter(var Parameters: JsonArray; Name: Text; Required: Boolean; Description: Text; AllowedValues: List of [Text]; DefaultValue: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Entry: JsonObject;
        Allowed: JsonArray;
        Value: Text;
    begin
        foreach Value in AllowedValues do
            Allowed.Add(Value);
        Entry := ContractMgt.Parameter(Name, 'string', Required, Description);
        if DefaultValue <> '' then
            Entry.Add('default', DefaultValue);
        Entry.Add('allowed', Allowed);
        Parameters.Add(Entry);
    end;

    /// <summary>
    /// Adds a plain Error() of the type: the answer carries code BusinessCentralError and this text.
    /// </summary>
    /// <param name="Errors">Receives the entry.</param>
    /// <param name="ErrorText">The error text, or its pattern.</param>
    /// <param name="When">When the error is returned.</param>
    /// <param name="Fix">What the caller does about it.</param>
    internal procedure AddError(var Errors: JsonArray; ErrorText: Text; When: Text; Fix: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, ErrorText, When, Fix));
    end;

    /// <summary>
    /// Adds an error that Business Central itself raises on the execute path; answered with code
    /// BusinessCentralError and Business Central's own text.
    /// </summary>
    /// <param name="Errors">Receives the entry.</param>
    /// <param name="When">When the error is returned.</param>
    /// <param name="Fix">What the caller does about it.</param>
    internal procedure AddRuntimeError(var Errors: JsonArray; When: Text; Fix: Text)
    begin
        AddError(Errors, 'Business Central''s own error text', When, Fix);
    end;

    /// <summary>
    /// Adds the errors the Report types (Get, SaveAs, Run) answer with when they read reportId and look up the report.
    /// </summary>
    /// <param name="Errors">Receives the entries.</param>
    internal procedure AddReportErrors(var Errors: JsonArray)
    begin
        AddError(Errors, 'Request must include "reportId".', 'data.reportId is missing.', 'Send the report object ID in data.reportId.');
        AddError(Errors, 'Report <reportId> not found.', 'No report with that ID exists in Report Metadata.', 'Find the ID with Orchestrator.Report.List.');
        AddRuntimeError(Errors, 'data.reportId is not a whole number.', 'Send reportId as an integer.');
    end;

    /// <summary>
    /// Adds a field to the response chapter.
    /// </summary>
    /// <param name="Fields">Receives the field.</param>
    /// <param name="Name">The JSON key in the answer.</param>
    /// <param name="JsonType">The JSON type.</param>
    /// <param name="Description">What it holds.</param>
    internal procedure AddResponseField(var Fields: JsonArray; Name: Text; JsonType: Text; Description: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Fields.Add(ContractMgt.ResponseField(Name, JsonType, Description));
    end;

    /// <summary>
    /// Adds an object or array field to the response chapter, with the fields it holds.
    /// </summary>
    /// <param name="Fields">Receives the field.</param>
    /// <param name="Name">The JSON key in the answer.</param>
    /// <param name="JsonType">object or array.</param>
    /// <param name="Description">What it holds.</param>
    /// <param name="Children">The fields of the object, or of each array element.</param>
    internal procedure AddResponseField(var Fields: JsonArray; Name: Text; JsonType: Text; Description: Text; Children: JsonArray)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Entry: JsonObject;
    begin
        Entry := ContractMgt.ResponseField(Name, JsonType, Description);
        Entry.Add('children', Children);
        Fields.Add(Entry);
    end;

    /// <summary>
    /// The response chapter.
    /// </summary>
    /// <param name="Fields">The fields of the Success answer.</param>
    /// <param name="ContentType">The content type of the answer.</param>
    /// <returns>The response chapter.</returns>
    internal procedure Response(Fields: JsonArray; ContentType: Text) Result: JsonObject
    begin
        Result.Add('contentType', ContentType);
        Result.Add('fields', Fields);
    end;

    /// <summary>
    /// The effect chapter.
    /// </summary>
    /// <param name="EffectName">read, write or irreversible.</param>
    /// <param name="Changes">What the type changes.</param>
    /// <param name="Idempotent">True when repeating the call changes nothing more.</param>
    /// <param name="PermissionSet">The permission set gate, or empty.</param>
    /// <param name="Preconditions">What must hold before the call.</param>
    /// <returns>The effect chapter.</returns>
    internal procedure Effect(EffectName: Text; Changes: Text; Idempotent: Boolean; PermissionSet: Text; Preconditions: JsonArray) Result: JsonObject
    begin
        Result.Add('effect', EffectName);
        Result.Add('changes', Changes);
        Result.Add('idempotent', Idempotent);
        if PermissionSet <> '' then
            Result.Add('permissionSet', PermissionSet);
        Result.Add('preconditions', Preconditions);
    end;

    /// <summary>
    /// The effect chapter of a type that commits on its execute path: effect irreversible, and the
    /// changes text says that Orchestrator's Omit Commit guard refuses the type in a rollback chain.
    /// </summary>
    /// <param name="Changes">What the type changes, naming the commit.</param>
    /// <param name="Idempotent">True when repeating the call changes nothing more.</param>
    /// <returns>The effect chapter.</returns>
    internal procedure CommittingEffect(Changes: Text; Idempotent: Boolean): JsonObject
    var
        Preconditions: JsonArray;
    begin
        exit(Effect('irreversible', Changes + ' It cannot be rolled back with the caller, so Orchestrator''s Omit Commit guard refuses it in a playbook chain that must roll back together.', Idempotent, '', Preconditions));
    end;

    /// <summary>
    /// Adds an entry to the related chapter.
    /// </summary>
    /// <param name="RelatedEntries">Receives the entry.</param>
    /// <param name="MessageType">The related message type; it must exist.</param>
    /// <param name="UseInsteadWhen">When to use that type instead.</param>
    internal procedure Related(var RelatedEntries: JsonArray; MessageType: Text; UseInsteadWhen: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        RelatedEntries.Add(ContractMgt.RelatedEntry(MessageType, UseInsteadWhen));
    end;

    /// <summary>
    /// A workflow chapter with one step.
    /// </summary>
    /// <param name="WorkflowChapter">Receives the steps.</param>
    /// <param name="MessageType">The message type of the step; it must exist.</param>
    /// <param name="Purpose">What the step does.</param>
    internal procedure Workflow(var WorkflowChapter: JsonObject; MessageType: Text; Purpose: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep(MessageType, Purpose));
        WorkflowChapter.Add('steps', Steps);
    end;

    /// <summary>
    /// Adds an entry to the examples chapter.
    /// </summary>
    /// <param name="Examples">Receives the entry.</param>
    /// <param name="Title">What the example shows.</param>
    /// <param name="Request">The request envelope as JSON text.</param>
    /// <param name="ResponseText">The answer as JSON text.</param>
    internal procedure Example(var Examples: JsonArray; Title: Text; Request: Text; ResponseText: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(ContractMgt.Example(Title, Request, ResponseText));
    end;
}
