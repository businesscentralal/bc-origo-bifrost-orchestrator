namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue #223: playbook file export/import keeps the Transform rows and writes no Message Type 0 on Transform steps.</summary>
codeunit 96498 "Playbook Export Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableJSONImport: Codeunit "Table JSON Import ori";

    /// <summary>AC01 and AC02: the file holds the playbook, its steps and its Transform rows, and Transform steps carry no MessageType.</summary>
    [Test]
    procedure Scenario_AC01_ExportHoldsTransformRowsAndNoMessageTypeZero()
    var
        PlaybookCode: Code[20];
        Envelope: JsonObject;
        Tables: JsonArray;
        TableToken: JsonToken;
        Row: JsonToken;
        Token: JsonToken;
        Fields: JsonToken;
    begin
        // Story #223 AC01/AC02 | Time: independent of Today/WorkDate | Risk: None
        PlaybookCode := BuildPlaybook();
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        Assert.AreEqual('bifrost-playbook', Text(Envelope, 'format'), 'format');
        Assert.AreEqual(PlaybookCode, Text(Envelope, 'playbookCode'), 'playbook code');
        Envelope.Get('tables', Token);
        Tables := Token.AsArray();
        Assert.AreEqual(4, Tables.Count(), 'playbook, steps, conditions and transforms');
        Assert.AreEqual(1, RowCount(Tables, Database::"Playbook ori"), 'one playbook');
        Assert.AreEqual(2, RowCount(Tables, Database::"Playbook Step ori"), 'two steps');
        Assert.AreEqual(2, RowCount(Tables, Database::"Playbook Transform ori"), 'both Transform rows are in the file');
        Tables.Get(1, TableToken);
        TableToken.AsObject().Get('rows', Token);
        foreach Row in Token.AsArray() do begin
            Row.AsObject().Get('fields', Fields);
            Assert.IsFalse(Fields.AsObject().Contains('MessageType'), 'A Transform step is exported without MessageType: ' + Format(Row));
            Assert.IsTrue(Fields.AsObject().Contains('StepKind'), 'StepKind stays');
        end;
        Lib.Cleanup(PlaybookCode);
    end;

    /// <summary>AC02: a file from before the fix, with "MessageType": "0" on a Transform step, imports.</summary>
    [Test]
    procedure Scenario_AC02_LegacyMessageTypeZeroImportsAsBlank()
    var
        Step: Record "Playbook Step ori";
        PlaybookCode: Code[20];
        Envelope: JsonObject;
        Result: JsonObject;
    begin
        // Story #223 AC02 | Time: independent of Today/WorkDate | Risk: None
        PlaybookCode := BuildPlaybook();
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        AddLegacyMessageType(Envelope, '0');
        Lib.Cleanup(PlaybookCode);
        Result := TableJSONImport.ImportPlaybook(Envelope);
        Assert.AreEqual(PlaybookCode, Text(Result, 'playbookCode'), 'result names the playbook');
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual(Step."Step Kind"::Transform, Step."Step Kind", 'step kind');
        Assert.AreEqual(0, Step."Message Type".AsInteger(), 'Message Type stays blank');
        Lib.Cleanup(PlaybookCode);
    end;

    /// <summary>A message step keeps its Message Type through export, delete and import.</summary>
    [Test]
    procedure Scenario_AC02_MessageStepKeepsMessageType()
    var
        Step: Record "Playbook Step ori";
        PlaybookCode: Code[20];
        Envelope: JsonObject;
    begin
        // Story #223 AC02 | Time: independent of Today/WorkDate | Risk: None
        PlaybookCode := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
        Lib.CreatePlaybook(PlaybookCode);
        Step.Init();
        Step."Playbook Code" := PlaybookCode;
        Step."Step No." := 10;
        Step."Message Type" := "Message Type ori"::"Data.Records.Get";
        Step.SetRequestTemplate('{"tableName":"Playbook ori"}');
        Step.Insert(true);
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        Lib.Cleanup(PlaybookCode);
        TableJSONImport.ImportPlaybook(Envelope);
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual("Message Type ori"::"Data.Records.Get", Step."Message Type", 'Message Type is kept');
        Assert.AreEqual('{"tableName":"Playbook ori"}', Step.GetRequestTemplate(), 'Request template is kept');
        Lib.Cleanup(PlaybookCode);
    end;

    /// <summary>AC03: export, delete, import, then Verify has no errors and the run gives the same result.</summary>
    [Test]
    procedure Scenario_AC03_RoundTripVerifiesAndRunsTheSame()
    var
        Instance: Record "Playbook Instance ori";
        Transform: Record "Playbook Transform ori";
        Verify: Codeunit "Playbook Verify ori";
        Runner: Codeunit "Playbook Runner ori";
        PlaybookCode: Code[20];
        Envelope: JsonObject;
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
        FirstResponse: Text;
        FirstSteps: Integer;
        Findings: JsonArray;
        Finding: JsonToken;
        Severity: JsonToken;
    begin
        // Story #223 AC03 | Time: independent of Today/WorkDate | Risk: Run seeds the workspace
        PlaybookCode := BuildPlaybook();
        Commit();
        Runner.Run(PlaybookCode, InitialRequest, Response, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'first run completes');
        FirstSteps := Instance."Steps Executed";
        FirstResponse := Format(Response);
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        Lib.Cleanup(PlaybookCode);
        Transform.SetRange("Playbook Code", PlaybookCode);
        Assert.IsTrue(Transform.IsEmpty(), 'deleted');
        TableJSONImport.ImportPlaybook(Envelope);
        Transform.SetRange("Playbook Code", PlaybookCode);
        Assert.AreEqual(2, Transform.Count(), 'Transform rows are back');
        Verify.GetFindings(PlaybookCode, Findings);
        foreach Finding in Findings do begin
            Finding.AsObject().Get('severity', Severity);
            Assert.AreNotEqual('error', Severity.AsValue().AsText().ToLower(), Format(Finding));
        end;
        Clear(Response);
        Commit();
        Runner.Run(PlaybookCode, InitialRequest, Response, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'second run completes');
        Assert.AreEqual(FirstSteps, Instance."Steps Executed", 'same number of steps');
        Assert.AreEqual(FirstResponse, Format(Response), 'same run result');
        Lib.Cleanup(PlaybookCode);
    end;

    /// <summary>A file that is not a playbook file, or holds a foreign table, is refused.</summary>
    [Test]
    procedure Scenario_ImportRefusesForeignFilesAndTables()
    var
        Envelope: JsonObject;
        Tables: JsonArray;
        Foreign: JsonObject;
    begin
        // Story #223 | Time: independent of Today/WorkDate | Risk: None
        Envelope.Add('format', 'bifrost-table-data');
        Envelope.Add('version', 1);
        asserterror TableJSONImport.ImportPlaybook(Envelope);
        Assert.ExpectedError('not a Bifrost playbook file');
        Clear(Envelope);
        Foreign.Add('tableNo', Database::"Test Run Marker");
        Tables.Add(Foreign);
        Envelope.Add('format', 'bifrost-playbook');
        Envelope.Add('version', 1);
        Envelope.Add('playbookCode', 'X');
        Envelope.Add('tables', Tables);
        asserterror TableJSONImport.ImportPlaybook(Envelope);
        Assert.ExpectedError('does not belong in a playbook file');
        asserterror TableJSONExport.ExportPlaybook('NOPE-223');
        Assert.ExpectedError('does not exist');
    end;

    local procedure BuildPlaybook() PlaybookCode: Code[20]
    var
        FirstStep: Record "Playbook Step ori";
        Step: Record "Playbook Step ori";
    begin
        PlaybookCode := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
        Lib.CreatePlaybook(PlaybookCode);
        FirstStep.Init();
        FirstStep."Playbook Code" := PlaybookCode;
        FirstStep."Step No." := 10;
        FirstStep."Step Kind" := FirstStep."Step Kind"::Transform;
        FirstStep.Insert(true);
        FirstStep.SetRequestTemplate('{"rows":[{"amount":12.5},{"amount":-8}]}');
        FirstStep."Next Step No. (Success)" := 20;
        FirstStep.Modify(true);
        AddMapping(PlaybookCode, 10, 'result', 'rows', "Transform Operation ori"::Copy);
        Step.Init();
        Step."Playbook Code" := PlaybookCode;
        Step."Step No." := 20;
        Step."Step Kind" := Step."Step Kind"::Transform;
        Step."Iterate Source Step No." := 10;
        Step."Iterate Array Path" := 'result';
        Step."Stop On Item Error" := true;
        Step.Insert(true);
        AddMapping(PlaybookCode, 20, 'amount', 'amount', "Transform Operation ori"::Negate);
    end;

    local procedure AddMapping(PlaybookCode: Code[20]; StepNo: Integer; Target: Text[250]; Source: Text[250]; Operation: Enum "Transform Operation ori")
    var
        Mapping: Record "Playbook Transform ori";
    begin
        Mapping.Init();
        Mapping."Playbook Code" := PlaybookCode;
        Mapping."Step No." := StepNo;
        Mapping."Line No." := 10000;
        Mapping."Target Path" := Target;
        Mapping."Source Path" := Source;
        Mapping.Operation := Operation;
        Mapping.Insert(true);
    end;

    local procedure AddLegacyMessageType(var Envelope: JsonObject; Value: Text)
    var
        Tables: JsonArray;
        TableToken: JsonToken;
        Rows: JsonToken;
        Row: JsonToken;
        Fields: JsonToken;
        Token: JsonToken;
    begin
        Envelope.Get('tables', Token);
        Tables := Token.AsArray();
        Tables.Get(1, TableToken);
        TableToken.AsObject().Get('rows', Rows);
        foreach Row in Rows.AsArray() do begin
            Row.AsObject().Get('fields', Fields);
            Fields.AsObject().Add('MessageType', Value);
        end;
    end;

    local procedure RowCount(Tables: JsonArray; TableNo: Integer): Integer
    var
        TableToken: JsonToken;
        Token: JsonToken;
        Index: Integer;
    begin
        for Index := 1 to Tables.Count() do begin
            Tables.Get(Index - 1, TableToken);
            TableToken.AsObject().Get('tableNo', Token);
            if Token.AsValue().AsInteger() = TableNo then begin
                TableToken.AsObject().Get('rows', Token);
                exit(Token.AsArray().Count());
            end;
        end;
    end;

    local procedure Text(Source: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Source.Get(KeyName, Token) then
            exit(Token.AsValue().AsText());
    end;
}
