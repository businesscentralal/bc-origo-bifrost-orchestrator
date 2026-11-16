namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #194: Verify checks Success condition paths against the declared response of the called message type.
/// Orchestrator.Playbook.Verify is the called type: its response declares status, valid and findings (with children).
/// No live calls: the playbook is verified, never run.
/// </summary>
codeunit 96490 "Playbook Condition Path Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'CND-194', Locked = true;
        FindingCodeTok: Label 'UnknownFieldReference', Locked = true;

    /// <summary>A path that the response declares gives no finding.</summary>
    [Test]
    procedure DeclaredPath_NoFinding()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC: valid, status and findings[0].code are declared in the response.
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        AddVerifyStep(20);
        Lib.AddSuccessCondition(PlaybookCodeTok, 20, 'findings[0].code', 'X');
        AddVerifyStep(30);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'valid', 'true');
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings), 'Declared paths are not reported');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>A path nested one level too deep (result.valid) is reported once, naming the path and the declared fields.</summary>
    [Test]
    procedure UndeclaredPath_IsWarned()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC: the path result.valid is not in the response (the issue's Kennitala shape, mirrored).
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'result.valid', 'true');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings), 'One finding per path');
        Assert.AreEqual('warning', GetField(Findings, 'severity'), 'It is a warning');
        Assert.IsTrue(GetField(Findings, 'message').Contains('result.valid'), 'The path is named');
        Assert.IsTrue(GetField(Findings, 'message').Contains('playbookCode'), 'The declared fields are listed');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>An unknown child under a field that lists children is reported once.</summary>
    [Test]
    procedure UnknownChild_IsWarned()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] edge: findings[0].bogus is not a child of findings.
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'findings[0].bogus', 'a');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings), 'Reported once');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The finding text is in the session language, in 1033 and 1039.</summary>
    [Test]
    procedure FindingText_1033And1039()
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'nope', 'true');
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'message').StartsWith('Step 10 has a Success condition on nope'), 'English text');
        Clear(Findings);
        GlobalLanguage(1039);
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'message').StartsWith('Skref 10 hefur árangursskilyrði á nope'), 'Icelandic text');
        GlobalLanguage(PreviousLanguage);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure SetupStep()
    begin
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        AddVerifyStep(10);
    end;

    local procedure AddVerifyStep(StepNo: Integer)
    begin
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Playbook.Verify", '{"playbookCode":"CND-194"}', 0, '', 0);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure CountCode(Findings: JsonArray): Integer
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        Total: Integer;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCodeTok then
                    Total += 1;
        exit(Total);
    end;

    local procedure GetField(Findings: JsonArray; FieldName: Text): Text
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        FieldToken: JsonToken;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCodeTok then begin
                    Token.AsObject().Get(FieldName, FieldToken);
                    exit(FieldToken.AsValue().AsText());
                end;
        exit('');
    end;
}
