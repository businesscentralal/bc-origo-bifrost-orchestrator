namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Transform Verify findings, source references and generated Copy Plan acceptance.</summary>
codeunit 96469 "Transform Verify Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>MissingTargetIsAFinding.</summary>
    [Test]
    procedure Scenario_AC43_MissingTargetIsAFinding()
    begin
        // Story #155, AC4.3 | Time: independent of Today/WorkDate | Risk: None
        AssertMappingFinding('', 'known', false, 'TransformTargetInvalid', '{"known":1}');
    end;

    /// <summary>UnknownSourceIsAFinding.</summary>
    [Test]
    procedure Scenario_AC43_UnknownSourceIsAFinding()
    begin
        // Story #155, AC4.3 | Time: independent of Today/WorkDate | Risk: None
        AssertMappingFinding('result', 'missing', false, 'TransformSourceUnknown', '{"known":1}');
    end;

    /// <summary>Malformed or absent input produces findings instead of aborting Verify.</summary>
    [Test]
    procedure Scenario_AC43_InvalidInputIsAFinding()
    begin
        // Story #155, AC4.3 | Time: independent of Today/WorkDate | Risk: None
        AssertMappingFinding('result', 'known', false, 'TransformSourceUnknown', '');
        AssertMappingFinding('result', 'known', false, 'TransformSourceUnknown', '{invalid');
    end;

    /// <summary>MessageTypeOnTransformIsAFinding.</summary>
    [Test]
    procedure Scenario_AC43_MessageTypeOnTransformIsAFinding()
    begin
        // Story #155, AC4.3 | Time: independent of Today/WorkDate | Risk: None
        AssertMappingFinding('result', 'known', true, 'TransformMessageType', '{"known":1}');
    end;

    /// <summary>CopyOperationGeneratesVerifiedTransform.</summary>
    [Test]
    procedure Scenario_AC45_CopyOperationGeneratesVerifiedTransform()
    var
        Plan: Record "Copy Plan ori";
        Field: Record "Copy Plan Field ori";
        Step: Record "Playbook Step ori";
        Transform: Record "Playbook Transform ori";
        Generator: Codeunit "Copy Plan Generator ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Finding: JsonToken;
        Severity: JsonToken;
        FieldNo: Integer;
    begin
        // Story #155, AC4.5 | Time: independent of Today/WorkDate | Risk: Public Data.Records metadata
        Plan.Init();
        Plan.Code := NewCode();
        Plan."Source Table No." := Database::"Test Copy Parent ori";
        Plan."Destination Table No." := Database::"Test Copy Child ori";
        Plan."Page Size" := 2;
        Plan.Insert(true);
        for FieldNo := 1 to 3 do begin
            Field.Init();
            Field."Plan Code" := Plan.Code;
            Field."Line No." := FieldNo * 10000;
            Field.Validate("Source Field No.", FieldNo);
            Field.Validate("Destination Field No.", FieldNo);
            if FieldNo = 3 then
                Field.Operation := Field.Operation::Negate;
            Field.Insert(true);
        end;
        Generator.Generate(Plan.Code);
        Step.Get(Plan.Code, 10);
        Assert.AreEqual(30, Step."Page Through Step No.", 'Paging includes Transform and destination');
        Step.Get(Plan.Code, 20);
        Assert.AreEqual(Step."Step Kind"::Transform, Step."Step Kind", 'Middle step is local');
        Step.Get(Plan.Code, 30);
        Assert.AreEqual(20, Step."Iterate Source Step No.", 'Set consumes transformed output');
        Transform.Get(Plan.Code, 20, 30000);
        Assert.AreEqual('fields.Amount', Transform."Source Path", 'Mapping uses source row field');
        Assert.AreEqual('fields.Amount', Transform."Target Path", 'Mapping writes destination field');
        Verify.GetFindings(Plan.Code, Findings);
        foreach Finding in Findings do begin
            Finding.AsObject().Get('severity', Severity);
            Assert.AreNotEqual('error', Severity.AsValue().AsText().ToLower(), Format(Finding));
        end;
        Generator.Generate(Plan.Code);
        Transform.SetRange("Playbook Code", Plan.Code);
        Assert.AreEqual(3, Transform.Count(), 'Regeneration replaces mappings without duplicates');
        Lib.Cleanup(Plan.Code);
        Plan.Get(Plan.Code);
        Plan.Delete(true);
    end;

    /// <summary>The user can author a local Transform and its mapping through the playbook card.</summary>
    [Test]
    procedure Scenario_AC44_CardAuthorsTransformMapping()
    var
        Step: Record "Playbook Step ori";
        Mapping: Record "Playbook Transform ori";
        Playbook: Record "Playbook ori";
        Card: TestPage "Playbook Card ori";
        PlaybookCode: Code[20];
    begin
        // Story #155, AC4.4 | Time: independent of Today/WorkDate | Risk: None
        PlaybookCode := NewCode();
        Lib.CreatePlaybook(PlaybookCode);
        Playbook.Get(PlaybookCode);
        Card.OpenEdit();
        Card.GoToRecord(Playbook);
        Card.Steps.New();
        Card.Steps."Step No.".SetValue(10);
        Card.Steps."Step Kind".SetValue("Playbook Step Kind ori"::Transform);
        Card.Steps.Description.SetValue('Local transform');
        Card.Steps.Next();
        Card.Steps.First();
        Card.Transforms.New();
        Card.Transforms."Target Path".SetValue('result');
        Card.Transforms.Operation.SetValue("Transform Operation ori"::Constant);
        Card.Transforms."Argument 1".SetValue('literal value');
        Card.Transforms.Next();
        Card.Close();
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual(Step."Step Kind"::Transform, Step."Step Kind", 'Kind saved from user surface');
        Mapping.SetRange("Playbook Code", PlaybookCode);
        Mapping.SetRange("Step No.", 10);
        Assert.IsTrue(Mapping.FindFirst(), 'Mapping saved from user surface');
        Assert.AreEqual('literal value', Mapping."Argument 1", 'Argument retained');
        Lib.Cleanup(PlaybookCode);
    end;

    local procedure AssertMappingFinding(Target: Text[250]; Source: Text[250]; HasMessage: Boolean; Expected: Text; InputTemplate: Text)
    var
        Step: Record "Playbook Step ori";
        Mapping: Record "Playbook Transform ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Finding: JsonToken;
        CodeToken: JsonToken;
        Found: Boolean;
    begin
        Step."Playbook Code" := NewCode();
        Lib.CreatePlaybook(Step."Playbook Code");
        Step."Step No." := 10;
        Step."Step Kind" := Step."Step Kind"::Transform;
        if HasMessage then
            Step."Message Type" := "Message Type ori"::"Data.Records.Get";
        Step.SetRequestTemplate(InputTemplate);
        Step.Insert(true);
        Mapping."Playbook Code" := Step."Playbook Code";
        Mapping."Step No." := 10;
        Mapping."Line No." := 10000;
        Mapping."Target Path" := Target;
        Mapping."Source Path" := Source;
        Mapping.Insert(true);
        Verify.GetFindings(Step."Playbook Code", Findings);
        foreach Finding in Findings do begin
            Finding.AsObject().Get('code', CodeToken);
            Found := Found or (CodeToken.AsValue().AsText() = Expected);
        end;
        Assert.IsTrue(Found, 'Expected finding ' + Expected);
        Lib.Cleanup(Step."Playbook Code");
    end;

    local procedure NewCode(): Code[20]
    begin
        exit(CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20));
    end;
}
