namespace Origo.Bifrost.Nornir;

using System.Environment.Configuration;
using System.Media;

codeunit 10035589 "Scheduler Wizard Reg. ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterAssistedSetup, '', false, false)]
    local procedure RegisterOrchSetupWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
        SetupTitleTok: Label 'Set up Bifrost Nornir', Comment = 'is-IS=Setja upp Bifröst stjórnanda';
        SetupShortTitleTok: Label 'Bifrost Nornir', Comment = 'is-IS=Bifröst stjórnandi';
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

    internal procedure OpenSetupWizard(SetupNotification: Notification)
    begin
        Page.Run(Page::"Scheduler Setup Wizard ori");
    end;
}
