namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>Exercises assisted-setup registration through the real publisher without scheduler business permissions.</summary>
codeunit 96446 "Scheduler Wizard Reg Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    /// <summary>Platform-only Assisted Setup enumeration registers one English wizard entry without business access.</summary>
    [Test]
    procedure Scenario_AC02_English_RegistersMetadataOnly()
    begin
        // Story #139 AC02-05 | Time: independent of Today/WorkDate | Risk: other installed registration subscribers.
        ExerciseRegistration(1033, 'Set up Bifrost Orchestrator');
    end;

    /// <summary>The same publisher path registers translated metadata exactly once in Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_Icelandic_RegistersMetadataOnly()
    begin
        // Story #139 AC02-05 | Time: independent of Today/WorkDate | Risk: other installed registration subscribers.
        ExerciseRegistration(1039, 'Setja upp Bifröst stjórnanda');
    end;

    local procedure ExerciseRegistration(LanguageId: Integer; ExpectedTitle: Text)
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        ScheduledEntry: Record "Scheduled Entry ori";
        ClientCredentials: Record "Client Credentials ori";
        BifrostSetup: Record "Setup ori";
        NavAppSetting: Record "NAV App Setting";
        GuidedExperience: Codeunit "Guided Experience";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Wizard: TestPage "Scheduler Setup Wizard ori";
        BeforeState: Dictionary of [Integer, Text];
        TableIds: List of [Integer];
        PreviousLanguage: Integer;
        FirstCount: Integer;
        SecondCount: Integer;
        TableId: Integer;
        IsRegistered: Boolean;
        IsCompleted: Boolean;
        PermissionsLowered: Boolean;
        HasBusinessAccess: Boolean;
        WizardError: Text;
        SetupError: Text;
    begin
        // [GIVEN] Fresh metadata and a snapshot of business/configuration tables; no consent or licence writes.
        TableIds.Add(Database::"Scheduler Setup ori");
        TableIds.Add(Database::"Scheduled Entry ori");
        TableIds.Add(Database::"Client Credentials ori");
        TableIds.Add(Database::"Job Queue Entry");
        TableIds.Add(Database::"Setup ori");
        TableIds.Add(Database::"NAV App Setting");
        foreach TableId in TableIds do
            BeforeState.Add(TableId, TableState(TableId));
        GuidedExperience.Remove(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Scheduler Setup Wizard ori");
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('Orch Guided Test ori');
        PermissionsLowered := LowerPermissions.HasChangedPermissions();
        HasBusinessAccess := SchedulerSetup.ReadPermission() or SchedulerSetup.WritePermission() or
            ScheduledEntry.ReadPermission() or ScheduledEntry.WritePermission() or
            ClientCredentials.ReadPermission() or ClientCredentials.WritePermission() or
            BifrostSetup.WritePermission() or NavAppSetting.WritePermission();

        // [WHEN] Opening the standard page raises Guided Experience.OnRegisterAssistedSetup twice.
        FirstCount := CountWizardEntries(ExpectedTitle);
        SecondCount := CountWizardEntries(ExpectedTitle);
        IsRegistered := GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Scheduler Setup Wizard ori");
        IsCompleted := GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Scheduler Setup Wizard ori");
        asserterror Wizard.OpenView();
        WizardError := GetLastErrorText();
        ClearLastError();
        asserterror HasBusinessAccess := SchedulerSetup.IsEmpty();
        SetupError := GetLastErrorText();
        ClearLastError();

        // [THEN] Assert after restoring permissions; all product calls above ran with platform-only permissions.
        LowerPermissions.StopLoggingNAVPermissions();
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(PermissionsLowered, 'The permission mock must be active.');
        Assert.IsFalse(HasBusinessAccess, 'Metadata registration must not grant scheduler, credential, consent or HTTP-setting access.');
        Assert.AreEqual(1, FirstCount, 'The translated scheduler wizard must appear once.');
        Assert.AreEqual(1, SecondCount, 'Repeated publisher registration must not duplicate wizard entries.');
        Assert.IsTrue(IsRegistered, 'The real registration event must persist wizard metadata.');
        Assert.IsFalse(IsCompleted, 'Metadata enumeration must not complete the wizard.');
        Assert.AreNotEqual('', WizardError, 'The platform-only user must not open the scheduler wizard.');
        Assert.AreNotEqual('', SetupError, 'The platform-only user must not read scheduler setup.');
        foreach TableId in TableIds do
            Assert.AreEqual(BeforeState.Get(TableId), TableState(TableId), 'Registration must leave business and configuration records unchanged.');
    end;

    local procedure CountWizardEntries(ExpectedTitle: Text): Integer
    var
        AssistedSetup: TestPage "Assisted Setup";
        EntryCount: Integer;
    begin
        AssistedSetup.OpenView();
        if AssistedSetup.First() then
            repeat
                if AssistedSetup.Name.Value() = ExpectedTitle then
                    EntryCount += 1;
            until not AssistedSetup.Next();
        AssistedSetup.Close();
        exit(EntryCount);
    end;

    local procedure TableState(TableId: Integer): Text
    var
        TableReference: RecordRef;
        State: TextBuilder;
    begin
        TableReference.Open(TableId);
        if TableReference.FindSet() then
            repeat
                State.Append(Format(TableReference.Field(TableReference.SystemIdNo()).Value));
                State.Append(Format(TableReference.Field(TableReference.SystemModifiedAtNo()).Value, 0, 9));
            until TableReference.Next() = 0;
        TableReference.Close();
        exit(State.ToText());
    end;
}
