namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Protects the committed workspace seed boundary from Omit Commit callers (#80).</summary>
codeunit 96409 "Workspace Preview Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>The published contract exposes the nested committed dispatch.</summary>
    [Test]
    procedure Scenario_AC01_PreviewDeclaresCommit()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Token: JsonToken;
    begin
        // Story #80 AC01 | Time: independent | Risk: contract must reflect nested dispatch.
        // [GIVEN] The real Preview contract.
        Contract := "Message Type ori"::"Orchestrator.Workspace.Preview";
        // [WHEN] Its effect is requested.
        Assert.IsTrue(Contract.GetEffect(Effect), 'Preview must declare its effect.');
        // [THEN] Callers see the committed _who seed boundary.
        Effect.Get('effect', Token);
        Assert.AreEqual('irreversible', Token.AsValue().AsText(), 'Preview cannot join a rollback chain.');
        Effect.Get('changes', Token);
        Assert.IsTrue(Token.AsValue().AsText().Contains('Help.WhoAmI.Get'), 'Name the nested dispatch.');
        Assert.IsTrue(Token.AsValue().AsText().Contains('commits'), 'Disclose the commit.');
    end;

    /// <summary>Executor refuses Preview before the nested dispatcher can reach boolean Run.</summary>
    [Test]
    procedure Scenario_AC01_ExecutorRefusesPreview()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        // Story #80 AC01 | Time: independent | Risk: no queue or user setup writes permitted.
        // [GIVEN] Preview requested within an Omit Commit dispatch.
        Executor.SetParameters("Message Type ori"::"Orchestrator.Workspace.Preview", '', '{}');
        Executor.SetOmitCommit(true, 'XPREVIEW80', 80);
        // [WHEN] The real executor runs, with commits prohibited.
        asserterror RunWithoutCommit();
        // [THEN] The guard, rather than a stopped nested transaction, explains the refusal.
        Assert.AreEqual('Playbook XPREVIEW80 step 80 cannot run Orchestrator.Workspace.Preview under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', GetLastErrorText(), 'Preview must fail at the guard boundary.');
        Assert.AreEqual('', Executor.GetResponseText(), 'A refused Preview cannot return a dispatched response.');
    end;

    /// <summary>An enabled Preview is rejected even when a preceding step is safe.</summary>
    [Test]
    procedure Scenario_AC01_ChainRefusesPreview()
    var
        Playbook: Record "Playbook ori";
        Step: Record "Playbook Step ori";
        Guard: Codeunit "Playbook Effect Guard ori";
    begin
        // Story #80 AC01 | Time: independent | Risk: generated fixtures roll back on AssertError.
        // [GIVEN] An owned chain with a read followed by Preview.
        Playbook.Init();
        Playbook.Code := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Playbook.Code));
        Playbook.Insert(true);
        Step.Init();
        Step."Playbook Code" := Playbook.Code;
        Step."Step No." := 10;
        Step."Message Type" := "Message Type ori"::"Orchestrator.Report.List";
        Step.Insert(true);
        Step."Step No." := 20;
        Step."Message Type" := "Message Type ori"::"Orchestrator.Workspace.Preview";
        Step.Insert(true);
        // [WHEN] Validation runs while these writes are uncommitted.
        asserterror Guard.ValidateOmitCommitChain(Playbook.Code);
        // [THEN] The exact Preview step is refused before any execution.
        Assert.AreEqual('Playbook ' + Playbook.Code + ' step 20 cannot run Orchestrator.Workspace.Preview under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', GetLastErrorText(), 'Chain validation identifies Preview.');
        Step.SetRange("Playbook Code", Playbook.Code);
        Step.DeleteAll(true);
        if Playbook.Get(Playbook.Code) then
            Playbook.Delete(true);
        Assert.IsTrue(Step.IsEmpty(), 'Owned steps removed or rolled back.');
        Assert.IsFalse(Playbook.Get(Playbook.Code), 'Owned playbook removed or rolled back.');
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure RunWithoutCommit()
    var
        Executor: Codeunit "Msg Executor ori";
    begin
        Executor.Run();
    end;
}
