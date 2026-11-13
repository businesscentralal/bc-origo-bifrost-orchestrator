namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.Security.AccessControl;
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
        BeforeState: Dictionary of [Integer, Text];
        TableIds: List of [Integer];
        PreviousLanguage: Integer;
        FirstCount: Integer;
        SecondCount: Integer;
        FirstVisibleCount: Integer;
        SecondVisibleCount: Integer;
        FirstTitle: Text;
        SecondTitle: Text;
        TableId: Integer;
        IsRegistered: Boolean;
        IsCompleted: Boolean;
        PermissionsLowered: Boolean;
        HasBusinessAccess: Boolean;
        WizardDenied: Boolean;
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
        WizardDenied := WizardExecuteExcluded(WizardError);
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('Orch Guided Test ori');
        PermissionsLowered := LowerPermissions.HasChangedPermissions();
        HasBusinessAccess := SchedulerSetup.ReadPermission() or SchedulerSetup.WritePermission() or
            ScheduledEntry.ReadPermission() or ScheduledEntry.WritePermission() or
            ClientCredentials.ReadPermission() or ClientCredentials.WritePermission() or
            BifrostSetup.WritePermission() or NavAppSetting.WritePermission();

        // [WHEN] Opening the standard page raises Guided Experience.OnRegisterAssistedSetup twice.
        FirstVisibleCount := CountWizardEntries(ExpectedTitle);
        FirstCount := ReadRegisteredWizard(FirstTitle);
        SecondVisibleCount := CountWizardEntries(ExpectedTitle);
        SecondCount := ReadRegisteredWizard(SecondTitle);
        IsRegistered := GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Scheduler Setup Wizard ori");
        IsCompleted := GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Scheduler Setup Wizard ori");
        // BC 29 Client Services does not raise a catchable error for this denied read.
        // A thrown permission error still counts. A successful call counts only when read permission is absent.
        if not TryReadSchedulerSetup(SchedulerSetup) then
            SetupError := GetLastErrorText()
        else
            if SchedulerSetup.ReadPermission() or SchedulerSetup.WritePermission() then
                SetupError := ''
            else
                SetupError := 'Read permission is not granted on scheduler setup.';
        ClearLastError();

        // [THEN] Assert after restoring permissions; all product calls above ran with platform-only permissions.
        LowerPermissions.StopLoggingNAVPermissions();
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(PermissionsLowered, 'The permission mock must be active.');
        Assert.IsFalse(HasBusinessAccess, 'Metadata registration must not grant scheduler, credential, consent or HTTP-setting access.');
        Assert.AreEqual(0, FirstVisibleCount, 'Assisted Setup must hide a wizard the user cannot execute.');
        Assert.AreEqual(0, SecondVisibleCount, 'Repeated registration must not grant wizard visibility.');
        Assert.AreEqual(1, FirstCount, 'The scheduler wizard metadata must be registered once.');
        Assert.AreEqual(ExpectedTitle, FirstTitle, 'Registration must persist the translated wizard title.');
        Assert.AreEqual(ExpectedTitle, SecondTitle, 'Repeated registration must preserve the translated title.');
        Assert.AreEqual(1, SecondCount, 'Repeated publisher registration must not duplicate wizard entries.');
        Assert.IsTrue(IsRegistered, 'The real registration event must persist wizard metadata.');
        Assert.IsFalse(IsCompleted, 'Metadata enumeration must not complete the wizard.');
        Assert.IsTrue(WizardDenied, 'The platform-only user must not open the scheduler wizard. ' + WizardError);
        Assert.AreNotEqual('', SetupError, 'The platform-only user must not read scheduler setup.');
        foreach TableId in TableIds do
            Assert.AreEqual(BeforeState.Get(TableId), TableState(TableId), 'Registration must leave business and configuration records unchanged.');
    end;

    local procedure WizardExecuteExcluded(var Detail: Text): Boolean
    var
        MetadataPermission: Record "Metadata Permission";
        PermissionSetRel: Record "Metadata Permission Set Rel.";
        CurrentModule: ModuleInfo;
    begin
        // TestPage.OpenView raises FormAbortException on the local Client Services runner, and
        // neither asserterror nor TryFunction can catch it. The exclusion set is the same gate,
        // and Assisted Setup visibility asserts the runtime effect.
        NavApp.GetCurrentModuleInfo(CurrentModule);
        PermissionSetRel.SetRange("App ID", CurrentModule.Id());
        PermissionSetRel.SetRange("Role ID", 'Orch Guided Test ori');
        PermissionSetRel.SetRange("Related Role ID", 'Orch Meta Excl ori');
        PermissionSetRel.SetRange(Type, PermissionSetRel.Type::Exclude);
        if PermissionSetRel.IsEmpty() then begin
            Detail := 'Orch Guided Test ori does not exclude Orch Meta Excl ori.';
            exit(false);
        end;
        MetadataPermission.SetRange("App ID", CurrentModule.Id());
        MetadataPermission.SetRange("Role ID", 'Orch Meta Excl ori');
        MetadataPermission.SetRange("Object Type", MetadataPermission."Object Type"::Page);
        MetadataPermission.SetRange("Object ID", Page::"Scheduler Setup Wizard ori");
        MetadataPermission.SetRange("Execute Permission", MetadataPermission."Execute Permission"::Yes);
        if MetadataPermission.IsEmpty() then begin
            Detail := 'The exclusion set does not remove execute on the scheduler wizard.';
            exit(false);
        end;
        Detail := 'Execute on the scheduler wizard is excluded from the platform-only set.';
        exit(true);
    end;

    [TryFunction]
    local procedure TryReadSchedulerSetup(var SchedulerSetup: Record "Scheduler Setup ori")
    var
        SetupIsEmpty: Boolean;
    begin
        SetupIsEmpty := SchedulerSetup.IsEmpty();
        if SetupIsEmpty then
            exit;
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

    local procedure ReadRegisteredWizard(var RegisteredTitle: Text): Integer
    var
        Registry: RecordRef;
        EntryCount: Integer;
    begin
        // Microsoft table 1990 is internal. Inspect metadata through RecordRef without bypassing permissions.
        // Fields 4/13 identify the target and experience type; field 6 holds the registered title.
        // Assisted Setup filters out pages without Execute, so visible rows cannot prove registration here.
        Registry.Open(1990);
        Registry.Field(4).SetRange(Page::"Scheduler Setup Wizard ori");
        Registry.Field(13).SetRange(Enum::"Guided Experience Type"::"Assisted Setup");
        EntryCount := Registry.Count();
        if Registry.FindFirst() then
            RegisteredTitle := Format(Registry.Field(6).Value);
        Registry.Close();
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
