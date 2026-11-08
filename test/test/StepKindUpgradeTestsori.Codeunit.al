namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Preserves the Message default for definitions created without the new field.</summary>
codeunit 96470 "Step Kind Upgrade Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>LegacyDefinitionReadsAsMessage.</summary>
    [Test]
    procedure Scenario_AC41_LegacyDefinitionReadsAsMessage()
    var
        Step: Record "Playbook Step ori";
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCode: Code[20];
    begin
        // Story #155, AC4.1 | Time: independent of Today/WorkDate | Risk: Actual pre-upgrade deployment still requires runtime evidence
        PlaybookCode := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(PlaybookCode));
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{}', 0, '', 0);
        Step.Get(PlaybookCode, 10);
        Assert.AreEqual(0, Step."Step Kind".AsInteger(), 'Stored default remains ordinal zero');
        Assert.AreEqual(Step."Step Kind"::Message, Step."Step Kind", 'Unchanged definitions remain messages');
        Lib.Cleanup(PlaybookCode);
    end;
}
