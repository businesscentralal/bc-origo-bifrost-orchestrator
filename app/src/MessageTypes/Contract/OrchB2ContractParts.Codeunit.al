namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Shared contract chapters for Report, Workspace and ReportLayout messages.
/// </summary>
codeunit 10035610 "Orch B2 Contract Parts ori"
{
    Access = Internal;

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

    internal procedure Target(Source: Text; Form: Text; Description: Text) Result: JsonArray
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Result.Add(ContractMgt.TargetEntry(Source, Form, Description));
    end;

    internal procedure AddRecordErrors(var Errors: JsonArray; RecordName: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter,
            StrSubstNo('No %1 identifier was supplied.', RecordName),
            'Send the identifier in data or as subject.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound,
            StrSubstNo('The %1 was not found.', RecordName),
            'Check the identifier and try again.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat,
            StrSubstNo('The %1 identifier has an invalid format.', RecordName),
            'Send a valid identifier.'));
    end;

    internal procedure AddRuntimeError(var Errors: JsonArray; When: Text; Fix: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.TextErrorEntry('Business Central error text', When, Fix));
    end;

    internal procedure AddResponseField(var Fields: JsonArray; Name: Text; JsonType: Text; Description: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Fields.Add(ContractMgt.ResponseField(Name, JsonType, Description));
    end;

    internal procedure Response(Fields: JsonArray; ContentType: Text) Result: JsonObject
    begin
        Result.Add('contentType', ContentType);
        Result.Add('fields', Fields);
    end;

    internal procedure Effect(EffectName: Text; Changes: Text; Idempotent: Boolean; PermissionSet: Text; Preconditions: JsonArray) Result: JsonObject
    begin
        Result.Add('effect', EffectName);
        Result.Add('changes', Changes);
        Result.Add('idempotent', Idempotent);
        if PermissionSet <> '' then
            Result.Add('permissionSet', PermissionSet);
        Result.Add('preconditions', Preconditions);
    end;

    internal procedure Related(var Related: JsonArray; MessageType: Text; UseInsteadWhen: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry(MessageType, UseInsteadWhen));
    end;

    internal procedure Workflow(var Workflow: JsonObject; MessageType: Text; Purpose: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep(MessageType, Purpose));
        Workflow.Add('steps', Steps);
    end;

    internal procedure Example(var Examples: JsonArray; Title: Text; Request: Text; ResponseText: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(ContractMgt.Example(Title, Request, ResponseText));
    end;
}
