namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;

/// <summary>
/// Test subscriber that answers the language model role question of Orchestrator.Playbook.Verify: the roles belong to
/// Bifrost Bragi, which the test app does not depend on, so a test says which role codes exist.
/// </summary>
codeunit 96440 "Role Lookup Subscriber ori"
{
    EventSubscriberInstance = Manual;

    var
        KnownRole: Text;
        QuestionsAsked: Integer;

    /// <summary>
    /// Sets the one role code that exists.
    /// </summary>
    /// <param name="RoleCode">The code of the role that exists.</param>
    internal procedure SetKnownRole(RoleCode: Text)
    begin
        KnownRole := RoleCode;
    end;

    /// <summary>
    /// How many times Verify asked whether a role exists.
    /// </summary>
    /// <returns>The number of questions.</returns>
    internal procedure GetQuestionsAsked(): Integer
    begin
        exit(QuestionsAsked);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Playbook Verify Lookup ori", 'OnBeforeCheckLanguageModelRole', '', false, false)]
    local procedure OnBeforeCheckLanguageModelRole(RoleCode: Text; var Handled: Boolean; var Exists: Boolean)
    begin
        QuestionsAsked += 1;
        Handled := true;
        Exists := (KnownRole <> '') and (RoleCode = KnownRole);
    end;
}
