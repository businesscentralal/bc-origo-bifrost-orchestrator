namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Validates only explicit safe effects and isolates chain fixtures by generated code.</summary>
codeunit 96406 "Playbook Effect Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Guard: Codeunit "Playbook Effect Guard ori";

    /// <summary>Real read and write contracts are accepted without dispatch.</summary>
    [Test]
    procedure ReadAndWriteAllowed()
    begin
        Guard.CheckOmitCommitAllowed('XGUARD', 10, "Message Type ori"::"Orchestrator.Report.List");
        Guard.CheckOmitCommitAllowed('XGUARD', 20, "Message Type ori"::"Orchestrator.Playbook.Enqueue");
    end;

    /// <summary>Real external-write types are refused with exact playbook, step and type context.</summary>
    [Test]
    procedure ExternalWritesRefused()
    begin
        asserterror Guard.CheckOmitCommitAllowed('XGUARD', 10, "Message Type ori"::"Orchestrator.Email.Send");
        Assert.AreEqual('Playbook XGUARD step 10 cannot run Orchestrator.Email.Send under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', GetLastErrorText(), 'Email refusal');
        asserterror Guard.CheckOmitCommitAllowed('XGUARD', 20, "Message Type ori"::"Orchestrator.Telegram.Message");
        Assert.AreEqual('Playbook XGUARD step 20 cannot run Orchestrator.Telegram.Message under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', GetLastErrorText(), 'Telegram refusal');
    end;

    /// <summary>The Foundation fallback contract is refused for a stable test enum value.</summary>
    [Test]
    procedure MissingContractRefused()
    begin
        asserterror Guard.CheckOmitCommitAllowed('XGUARD', 30, "Message Type ori"::"Test.Effect.Missing");
        Assert.AreEqual('Playbook XGUARD step 30 cannot run Test.Effect.Missing under Omit Commit: the type declares no effect contract, so it is treated as not safe to roll back.', GetLastErrorText(), 'Missing contract refusal');
    end;

    /// <summary>MissingChapter is not an explicit safe effect.</summary>
    [Test]
    procedure MissingChapterRefused()
    begin
        AssertMalformedEffect('{}', false);
    end;

    /// <summary>MissingEffect is not an explicit safe effect.</summary>
    [Test]
    procedure MissingEffectRefused()
    begin
        AssertMalformedEffect('{}', true);
    end;

    /// <summary>UnknownEffect is not an explicit safe effect.</summary>
    [Test]
    procedure UnknownEffectRefused()
    begin
        AssertMalformedEffect('{"effect":"custom"}', true);
    end;

    /// <summary>NullEffect is not an explicit safe effect.</summary>
    [Test]
    procedure NullEffectRefused()
    begin
        AssertMalformedEffect('{"effect":null}', true);
    end;

    /// <summary>ArrayEffect is not an explicit safe effect.</summary>
    [Test]
    procedure ArrayEffectRefused()
    begin
        AssertMalformedEffect('{"effect":[]}', true);
    end;

    /// <summary>ObjectEffect is not an explicit safe effect.</summary>
    [Test]
    procedure ObjectEffectRefused()
    begin
        AssertMalformedEffect('{"effect":{}}', true);
    end;

    /// <summary>BooleanEffect is not an explicit safe effect.</summary>
    [Test]
    procedure BooleanEffectRefused()
    begin
        AssertMalformedEffect('{"effect":true}', true);
    end;

    /// <summary>NumberEffect is not an explicit safe effect.</summary>
    [Test]
    procedure NumberEffectRefused()
    begin
        AssertMalformedEffect('{"effect":42}', true);
    end;

    /// <summary>CaseVariant is not an explicit safe effect.</summary>
    [Test]
    procedure CaseVariantRefused()
    begin
        AssertMalformedEffect('{"effect":"READ"}', true);
    end;

    /// <summary>Disabled unsafe steps do not prevent validation of an otherwise safe chain.</summary>
    [Test]
    procedure SafeChainIgnoresDisabled()
    var
        Playbook: Record "Playbook ori";
    begin
        CreatePlaybook(Playbook);
        AddStep(Playbook.Code, 10, "Message Type ori"::"Orchestrator.Report.List", false, false);
        AddStep(Playbook.Code, 20, "Message Type ori"::"Orchestrator.Playbook.Enqueue", false, false);
        AddStep(Playbook.Code, 30, "Message Type ori"::"Orchestrator.Email.Send", true, false);
        Guard.ValidateOmitCommitChain(Playbook.Code);
        Cleanup(Playbook);
    end;

    /// <summary>The first enabled unsafe step identifies its own position in a mixed chain.</summary>
    [Test]
    procedure UnsafeChainNamesStep()
    var
        Playbook: Record "Playbook ori";
    begin
        CreatePlaybook(Playbook);
        AddStep(Playbook.Code, 10, "Message Type ori"::"Orchestrator.Playbook.Enqueue", false, false);
        AddStep(Playbook.Code, 20, "Message Type ori"::"Orchestrator.Telegram.Message", false, false);
        asserterror Guard.ValidateOmitCommitChain(Playbook.Code);
        Assert.IsTrue(GetLastErrorText().Contains('Playbook ' + Playbook.Code + ' step 20 cannot run Orchestrator.Telegram.Message'), 'First unsafe chain step');
        Cleanup(Playbook);
    end;

    /// <summary>A Check step still dispatches a message, so cannot hide an irreversible effect.</summary>
    [Test]
    procedure CheckStepCannotHideEffect()
    var
        Playbook: Record "Playbook ori";
    begin
        CreatePlaybook(Playbook);
        AddStep(Playbook.Code, 10, "Message Type ori"::"Orchestrator.Email.Send", false, true);
        asserterror Guard.ValidateOmitCommitChain(Playbook.Code);
        Assert.IsTrue(GetLastErrorText().Contains('step 10 cannot run Orchestrator.Email.Send'), 'Check steps dispatch too');
        Cleanup(Playbook);
    end;

    /// <summary>AC04 rejects actual email execution before any dispatcher queue write.</summary>
    [Test]
    procedure AC04_ExecutorEmailRefusedBeforeDispatch()
    begin
        // Story #59 AC04 | Time: independent | Risk: no email or external request is allowed.
        AssertExecutorRefused("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send', 'irreversible');
    end;

    /// <summary>AC04 rejects actual Telegram execution before any dispatcher queue write.</summary>
    [Test]
    procedure AC04_ExecutorTelegramRefusedBeforeDispatch()
    begin
        // Story #59 AC04 | Time: independent | Risk: no Telegram request is allowed.
        AssertExecutorRefused("Message Type ori"::"Orchestrator.Telegram.Message", 'Orchestrator.Telegram.Message', 'irreversible');
    end;

    /// <summary>AC04 rejects a missing contract at the executor boundary, not just the guard helper.</summary>
    [Test]
    procedure AC04_ExecutorMissingContractRefused()
    begin
        // Story #59 AC04 | Time: independent | Risk: test fixture must never dispatch.
        AssertExecutorRefused("Message Type ori"::"Test.Effect.Missing", 'Test.Effect.Missing', 'no effect contract');
    end;

    /// <summary>AC04 rejects malformed effect metadata through the real executor.</summary>
    [Test]
    procedure AC04_ExecutorMalformedEffectRefused()
    var
        Fixture: Codeunit "Effect Contract Fixture ori";
    begin
        // Story #59 AC04 | Time: independent | Risk: test fixture must never dispatch.
        Fixture.Configure('{"effect":null}', true);
        AssertExecutorRefused("Message Type ori"::"Test.Effect.Contract", 'Test.Effect.Contract', 'no effect contract');
        Fixture.Configure('', false);
    end;

    /// <summary>AC04 forwards true through the public dispatcher without an explicit commit.</summary>
    [Test]
    procedure AC04_ReadDispatchOmitsCommit()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        // Story #59 AC04 | Time: independent | Risk: transport proof only, not licensed message acceptance.
        // The response may be a licensing or request error. The real dispatcher must still honor true.
        Executor.SetParameters("Message Type ori"::"Orchestrator.Report.List", Format(CreateGuid(), 0, 4), '{}');
        Executor.SetOmitCommit(true, 'XREAD', 80);
        RunWithoutCommit();
        Assert.AreEqual('application/json', Executor.GetResponseContentType(), 'The actual dispatcher returns its JSON response.');
        Assert.AreNotEqual('', Executor.GetResponseText(), 'The dispatch must produce a response without committing.');
        // The configured codeunit test isolation rolls back the owned request; container cleanup is verified too.
    end;

    /// <summary>AC05 a newly configured run cannot inherit a previous Omit Commit request.</summary>
    [Test]
    procedure AC05_SetParametersResetsCommitSignal()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        // Story #59 AC05 | Time: independent | Risk: commit-error scope stops before any handler.
        Executor.SetParameters("Message Type ori"::"Orchestrator.Email.Send", '', '{}');
        Executor.SetOmitCommit(true, 'OLD', 10);
        Executor.SetParameters("Message Type ori"::"Orchestrator.Email.Send", '', '{}');
        asserterror RunWithoutCommit();
        Assert.IsTrue(LowerCase(GetLastErrorText()).Contains('commit'), 'The default dispatch must attempt its normal commit.');
        Assert.IsFalse(GetLastErrorText().Contains('cannot run'), 'The previous Omit Commit guard must not survive SetParameters.');
    end;

    /// <summary>AC05 a refused run consumes the SingleInstance signal even before new parameters arrive.</summary>
    [Test]
    procedure AC05_FailedRunConsumesCommitSignal()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        // Story #59 AC05 | Time: independent | Risk: commit-error scope stops before any handler.
        AssertExecutorRefused("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send', 'irreversible');
        asserterror RunWithoutCommit();
        Assert.IsTrue(LowerCase(GetLastErrorText()).Contains('commit'), 'A later default run must attempt its normal commit.');
        Assert.IsFalse(GetLastErrorText().Contains('cannot run'), 'A refused run must consume the Omit Commit flag.');
        Executor.SetParameters("Message Type ori"::"Test.Effect.Missing", '', '');
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure RunWithoutCommit()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        Executor.Run();
    end;

    local procedure AssertExecutorRefused(MessageType: Enum "Message Type ori"; TypeName: Text; Reason: Text)
    var
        Executor: Codeunit "Msg Executor ori";
        Subject: Text[250];
        ExpectedError: Text;
    begin
        Subject := Format(CreateGuid(), 0, 4);
        Executor.SetParameters(MessageType, Subject, '{}');
        Executor.SetOmitCommit(true, 'XEXECUTOR', 70);
        asserterror Executor.Run();
        ExpectedError := GetLastErrorText();
        Assert.IsTrue(ExpectedError.StartsWith('Playbook XEXECUTOR step 70 cannot run ' + TypeName + ' under Omit Commit:'), 'Runtime refusal identifies the exact caller and target.');
        Assert.IsTrue(ExpectedError.Contains(Reason), 'Runtime refusal identifies the unsafe effect.');
        Assert.AreEqual('', Executor.GetResponseText(), 'Refusal cannot produce a dispatched response.');
    end;

    local procedure AssertMalformedEffect(EffectJson: Text; HasEffect: Boolean)
    var
        Fixture: Codeunit "Effect Contract Fixture ori";
    begin
        Fixture.Configure(EffectJson, HasEffect);
        asserterror Guard.CheckOmitCommitAllowed('XGUARD', 40, "Message Type ori"::"Test.Effect.Contract");
        Assert.AreEqual('Playbook XGUARD step 40 cannot run Test.Effect.Contract under Omit Commit: the type declares no effect contract, so it is treated as not safe to roll back.', GetLastErrorText(), 'Malformed effect fails closed with context');
        Fixture.Configure('', false);
    end;

    local procedure CreatePlaybook(var Playbook: Record "Playbook ori")
    begin
        Playbook.Init();
        Playbook.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Playbook.Code));
        Playbook.Insert(true);
    end;

    local procedure AddStep(PlaybookCode: Code[20]; StepNo: Integer; MessageType: Enum "Message Type ori"; Disabled: Boolean; IsCheck: Boolean)
    var
        Step: Record "Playbook Step ori";
    begin
        Step.Init();
        Step."Playbook Code" := PlaybookCode;
        Step."Step No." := StepNo;
        Step."Message Type" := MessageType;
        Step.Disabled := Disabled;
        if IsCheck then
            Step."Step Type" := Step."Step Type"::Check;
        Step.Insert(true);
    end;

    local procedure Cleanup(var Playbook: Record "Playbook ori")
    var
        Step: Record "Playbook Step ori";
    begin
        Step.SetRange("Playbook Code", Playbook.Code);
        Step.DeleteAll(true);
        Assert.IsTrue(Step.IsEmpty(), 'Own chain steps deleted');
        // AssertError rolls back an uncommitted fixture; success leaves it for explicit deletion.
        if Playbook.Get(Playbook.Code) then
            Playbook.Delete(true);
        Assert.IsFalse(Playbook.Get(Playbook.Code), 'Own playbook absent after delete or rollback');
    end;
}
