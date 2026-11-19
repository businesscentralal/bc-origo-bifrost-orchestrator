namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.TestLibraries.Utilities;

/// <summary>Issue #223: playbook file export/import keeps the Transform rows and writes no Message Type 0 on Transform steps.</summary>
codeunit 96498 "Playbook Export Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TempSavedCoverage: Record "Change Log Setup (Table)" temporary;
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableJSONImport: Codeunit "Table JSON Import ori";
        SavedGuard: Text;
        WasActivated: Boolean;
        SavedLanguage: Integer;
        ConfirmImport: Boolean;

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
        Setup();
        // Story #223 AC02 | Time: independent of Today/WorkDate | Risk: None
        PlaybookCode := BuildPlaybook();
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        AddLegacyMessageType(Envelope, '0');
        Lib.Cleanup(PlaybookCode);
        Result := TableJSONImport.ImportPlaybookFromUI(Envelope);
        Assert.AreEqual(PlaybookCode, Text(Result, 'playbookCode'), 'result names the playbook');
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual(Step."Step Kind"::Transform, Step."Step Kind", 'step kind');
        Assert.AreEqual(0, Step."Message Type".AsInteger(), 'Message Type stays blank');
        Lib.Cleanup(PlaybookCode);
        TearDown();
    end;

    /// <summary>A message step keeps its Message Type through export, delete and import.</summary>
    [Test]
    procedure Scenario_AC02_MessageStepKeepsMessageType()
    var
        Step: Record "Playbook Step ori";
        PlaybookCode: Code[20];
        Envelope: JsonObject;
    begin
        Setup();
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
        TableJSONImport.ImportPlaybookFromUI(Envelope);
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual("Message Type ori"::"Data.Records.Get", Step."Message Type", 'Message Type is kept');
        Assert.AreEqual('{"tableName":"Playbook ori"}', Step.GetRequestTemplate(), 'Request template is kept');
        Lib.Cleanup(PlaybookCode);
        TearDown();
    end;

    /// <summary>AC03: export, delete, import, then Verify has no errors and the run gives the same result.</summary>
    [Test]
    procedure Scenario_AC03_RoundTripVerifiesAndRunsTheSame()
    var
        Instance: Record "Playbook Instance ori";
        Transform: Record "Playbook Transform ori";
        Verify: Codeunit "Playbook Verify ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        Response: BigText;
        PlaybookCode: Code[20];
        Envelope: JsonObject;
        InstanceId: Guid;
        FirstResponse: Text;
        FirstSteps: Integer;
        Findings: JsonArray;
        Finding: JsonToken;
        Severity: JsonToken;
    begin
        Setup();
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
        TableJSONImport.ImportPlaybookFromUI(Envelope);
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
        TearDown();
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
        asserterror TableJSONImport.ImportPlaybookFromUI(Envelope);
        Assert.ExpectedError('not a Bifrost playbook file');
        Clear(Envelope);
        Foreign.Add('tableNo', Database::"Test Run Marker");
        Tables.Add(Foreign);
        Envelope.Add('format', 'bifrost-playbook');
        Envelope.Add('version', 1);
        Envelope.Add('playbookCode', 'X');
        Envelope.Add('tables', Tables);
        asserterror TableJSONImport.ImportPlaybookFromUI(Envelope);
        Assert.ExpectedError('does not belong in a playbook file');
        asserterror TableJSONExport.ExportPlaybook('NOPE-223');
        Assert.ExpectedError('does not exist');
    end;

    /// <summary>#231 AC01: the page imports all four tables with the default blocked guard and no coverage.</summary>
    [Test]
    [HandlerFunctions('ImportConfirmHandler,ImportMessageHandler')]
    procedure Scenario_AC01_PageImportsWithoutChangeLogCoverage()
    begin
        VerifyPageImport(true);
    end;

    /// <summary>#231 AC01: declining the UI confirmation writes nothing.</summary>
    [Test]
    [HandlerFunctions('ImportConfirmHandler')]
    procedure Scenario_AC01_CancelledPageImportWritesNothing()
    begin
        VerifyPageImport(false);
    end;

    local procedure VerifyPageImport(Confirmed: Boolean)
    var
        Playbook: Record "Playbook ori";
        Step: Record "Playbook Step ori";
        Condition: Record "Playbook Condition ori";
        Transform: Record "Playbook Transform ori";
        Playbooks: Page "Playbooks ori";
        Envelope: JsonObject;
        PlaybookCode: Code[20];
    begin
        // Story #231 AC01 | Time: independent of Today/WorkDate | Risk: guard setup restored by TearDown
        Setup();
        PlaybookCode := BuildPlaybook();
        Condition."Playbook Code" := PlaybookCode;
        Condition."Step No." := 10;
        Condition."Group No." := 1;
        Condition."Line No." := 10000;
        Condition.Path := 'result';
        Condition.Insert(true);
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        Lib.Cleanup(PlaybookCode);
        ConfirmImport := Confirmed;
        // The action delegates here after UploadIntoStream; browser checks cover the actual file picker.
        Assert.AreEqual(Confirmed, Playbooks.ImportPlaybookFile(Envelope), 'Confirmation controls import');
        Assert.AreEqual(Confirmed, Playbook.Get(PlaybookCode), 'Header imported only on confirmation');
        Step.SetRange("Playbook Code", PlaybookCode);
        Condition.SetRange("Playbook Code", PlaybookCode);
        Transform.SetRange("Playbook Code", PlaybookCode);
        if Confirmed then begin
            Assert.AreEqual(2, Step.Count(), 'Both steps imported');
            Assert.AreEqual(1, Condition.Count(), 'Condition imported');
            Assert.AreEqual(2, Transform.Count(), 'Both transforms imported');
            Step.Get(PlaybookCode, 10);
            Assert.AreEqual('{"rows":[{"amount":12.5},{"amount":-8}]}', Step.GetRequestTemplate(), 'Template BLOB preserved');
            // Repeat through the same page path: existing rows are updated, not duplicated.
            Assert.IsTrue(Playbooks.ImportPlaybookFile(Envelope), 'Repeat import succeeds');
            Assert.AreEqual(2, Step.Count(), 'Repeat import does not duplicate steps');
        end else begin
            Assert.IsTrue(Step.IsEmpty(), 'No steps after cancellation');
            Assert.IsTrue(Condition.IsEmpty(), 'No conditions after cancellation');
            Assert.IsTrue(Transform.IsEmpty(), 'No transforms after cancellation');
        end;
        AssertDefaultGuard();
        Lib.Cleanup(PlaybookCode);
        TearDown();
    end;

    /// <summary>#231 AC02: the UI exemption does not open the generic table/playbook import paths.</summary>
    [Test]
    procedure Scenario_AC02_GenericImportsRemainGuarded()
    var
        Envelope: JsonObject;
        TableToken: JsonToken;
        Tables: JsonToken;
        PlaybookCode: Code[20];
    begin
        // Story #231 AC02 | Time: independent of Today/WorkDate | Risk: None
        Setup();
        PlaybookCode := BuildPlaybook();
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        TableJSONImport.ImportPlaybookFromUI(Envelope);
        Commit();
        asserterror TableJSONImport.ImportPlaybook(Envelope);
        Assert.IsTrue(GetLastErrorText().ToLower().Contains('change log'), 'Generic import is refused by the Change Log guard');
        Envelope.Get('tables', Tables);
        Tables.AsArray().Get(0, TableToken);
        asserterror TableJSONImport.ImportTable(TableToken.AsObject(), false, true);
        Assert.IsTrue(GetLastErrorText().ToLower().Contains('change log'), 'Generic import is refused by the Change Log guard');
        AssertDefaultGuard();
        Lib.Cleanup(PlaybookCode);
        TearDown();
    end;

    /// <summary>#231 AC01: invalid values fail instead of being silently kept or truncated.</summary>
    [Test]
    procedure Scenario_AC01_InvalidUIFieldRollsBackImport()
    var
        Step: Record "Playbook Step ori";
        Envelope: JsonObject;
        PlaybookCode: Code[20];
    begin
        // Story #231 AC01 | Time: independent of Today/WorkDate | Risk: None
        Setup();
        PlaybookCode := BuildPlaybook();
        Envelope := TableJSONExport.ExportPlaybook(PlaybookCode);
        SetStepDescription(Envelope, PadStr('TOO LONG', 251, 'X'));
        Commit();
        asserterror TableJSONImport.ImportPlaybookFromUI(Envelope);
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual('', Step.Description, 'Invalid value did not persist');
        AssertDefaultGuard();
        Lib.Cleanup(PlaybookCode);
        TearDown();
    end;

    /// <summary>Answers the page's import confirmation.</summary>
    [ConfirmHandler]
    procedure ImportConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreNotEqual('', Question, 'The user sees a confirmation');
        Reply := ConfirmImport;
    end;

    /// <summary>Checks that the page reports the imported row counts.</summary>
    [MessageHandler]
    procedure ImportMessageHandler(Message: Text[1024])
    begin
        Assert.AreNotEqual('', Message, 'The user sees the import result');
    end;

    /// <summary>A file labelled with one playbook that carries another playbook's header or rows is refused before anything is written.</summary>
    [Test]
    procedure Scenario_ImportRefusesRowsOfAnotherPlaybook()
    var
        StepA: Record "Playbook Step ori";
        StepB: Record "Playbook Step ori";
        CodeA: Code[20];
        CodeB: Code[20];
        EnvelopeA: JsonObject;
        EnvelopeB: JsonObject;
        Mixed: JsonObject;
    begin
        Setup();
        // Story #223 | Time: independent of Today/WorkDate | Risk: None
        CodeA := BuildPlaybook();
        CodeB := BuildPlaybook();
        Commit(); // an asserterror rolls back; keep the playbooks so the unchanged checks mean something
        EnvelopeB := TableJSONExport.ExportPlaybook(CodeB);
        SetStepDescription(EnvelopeB, 'HIJACK');

        // File labelled A with the header and rows of B: no Playbook row for A.
        Mixed := EnvelopeB.Clone().AsObject();
        Mixed.Replace('playbookCode', CodeA);
        asserterror TableJSONImport.ImportPlaybookFromUI(Mixed);
        Assert.ExpectedError('has no Playbook row for playbook');
        StepB.Get(CodeB, 10);
        Assert.AreNotEqual('HIJACK', StepB.Description, 'playbook B unchanged after header mismatch');

        // File with A header and A rows plus a step row of B (matched by id): refused, nothing written.
        EnvelopeA := TableJSONExport.ExportPlaybook(CodeA);
        AppendStepRows(EnvelopeA, EnvelopeB);
        asserterror TableJSONImport.ImportPlaybookFromUI(EnvelopeA);
        Assert.ExpectedError('belongs to playbook');
        StepB.Get(CodeB, 10);
        Assert.AreNotEqual('HIJACK', StepB.Description, 'playbook B unchanged after row mismatch');
        StepA.Get(CodeA, 10);
        Assert.AreNotEqual('HIJACK', StepA.Description, 'playbook A unchanged after row mismatch');
        Lib.Cleanup(CodeA);
        Lib.Cleanup(CodeB);
        TearDown();
    end;

    local procedure SetStepDescription(var Envelope: JsonObject; Value: Text)
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
            begin
                Fields.AsObject().Remove('Description');
                Fields.AsObject().Add('Description', Value);
            end;
        end;
    end;

    local procedure AppendStepRows(var Target: JsonObject; Source: JsonObject)
    var
        TargetTables: JsonArray;
        SourceTables: JsonArray;
        TargetTable: JsonToken;
        SourceTable: JsonToken;
        TargetRows: JsonToken;
        SourceRows: JsonToken;
        Row: JsonToken;
        Token: JsonToken;
    begin
        Target.Get('tables', Token);
        TargetTables := Token.AsArray();
        Source.Get('tables', Token);
        SourceTables := Token.AsArray();
        TargetTables.Get(1, TargetTable);
        SourceTables.Get(1, SourceTable);
        TargetTable.AsObject().Get('rows', TargetRows);
        SourceTable.AsObject().Get('rows', SourceRows);
        foreach Row in SourceRows.AsArray() do
            TargetRows.AsArray().Add(Row.AsObject().Clone());
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

    local procedure Setup()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        SetupPage: TestPage "Setup ori";
        TableNo: Integer;
    begin
        SavedLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(true);
        end;
        WasActivated := ChangeLogSetup."Change Log Activated";
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
        SetupPage.OpenEdit();
        SavedGuard := SetupPage."ChangeLog Write Guard ori".Value();
        SetupPage."ChangeLog Write Guard ori".SetValue('Blocked');
        SetupPage.Close();
        TempSavedCoverage.Reset();
        TempSavedCoverage.DeleteAll();
        foreach TableNo in PlaybookTables() do
            if Coverage.Get(TableNo) then begin
                TempSavedCoverage := Coverage;
                TempSavedCoverage.Insert();
                Coverage.Delete(true);
            end;
        AssertDefaultGuard();
    end;

    local procedure AssertDefaultGuard()
    var
        Coverage: Record "Change Log Setup (Table)";
        SetupPage: TestPage "Setup ori";
        TableNo: Integer;
    begin
        SetupPage.OpenView();
        SetupPage."ChangeLog Write Guard ori".AssertEquals('Blocked');
        SetupPage.Close();
        foreach TableNo in PlaybookTables() do
            Assert.IsFalse(Coverage.Get(TableNo), 'No playbook Change Log coverage');
    end;

    local procedure TearDown()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        SetupPage: TestPage "Setup ori";
    begin
        if TempSavedCoverage.FindSet() then
            repeat
                Coverage := TempSavedCoverage;
                Coverage.Insert(true);
            until TempSavedCoverage.Next() = 0;
        SetupPage.OpenEdit();
        SetupPage."ChangeLog Write Guard ori".SetValue(SavedGuard);
        SetupPage.Close();
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
        GlobalLanguage(SavedLanguage);
    end;

    local procedure PlaybookTables() TableNos: List of [Integer]
    begin
        TableNos.Add(Database::"Playbook ori");
        TableNos.Add(Database::"Playbook Step ori");
        TableNos.Add(Database::"Playbook Condition ori");
        TableNos.Add(Database::"Playbook Transform ori");
    end;
}
