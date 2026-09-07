namespace Origo.Bifrost.Orchestrator;

using System.Environment.Configuration;
using System.Media;

codeunit 10035589 "Scheduler Wizard Reg. ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterAssistedSetup, '', false, false)]
    local procedure RegisterOrchSetupWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
        SetupTitleTok: Label 'Set up Bifrost Orchestrator', Comment = 'is-IS=Setja upp Bifröst stjórnanda';
        SetupShortTitleTok: Label 'Bifrost Orchestrator', Comment = 'is-IS=Bifröst stjórnandi';
        SetupDescriptionTok: Label 'Configure the Job Queue Orchestrator: enable HTTP client requests, verify the management job queue, and set up scheduling policies.', Comment = 'is-IS=Stilla vinnsluraðarann: virkja HTTP-biðlarabeiðnir, staðfesta stjórnunarvinnsluröð og setja upp tímasetningarstefnur.';
    begin
        GuidedExperience.InsertAssistedSetup(
            SetupTitleTok,
            SetupShortTitleTok,
            SetupDescriptionTok,
            10,
            ObjectType::Page,
            Page::"Scheduler Setup Wizard ori",
            Enum::"Assisted Setup Group"::Extensions,
            '',
            Enum::"Video Category"::Uncategorized,
            '');
    end;

    /// <summary>
    /// Opens the Bifrost Orchestrator setup wizard. This is the action handler behind the setup
    /// notification raised by the Scheduler Setup page, which is why it carries a Notification
    /// parameter it does not read.
    /// </summary>
    /// <param name="SetupNotification">The notification the user clicked. Required by the handler signature, not used.</param>
    internal procedure OpenSetupWizard(SetupNotification: Notification)
    begin
        Page.Run(Page::"Scheduler Setup Wizard ori");
    end;
}
