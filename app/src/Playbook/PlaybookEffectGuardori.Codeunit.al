namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Validates effect contracts before Omit Commit dispatch.</summary>
codeunit 10035554 "Playbook Effect Guard ori"
{
    Access = Internal;

    /// <summary>
    /// Allows only explicit read or write effects of types that do not commit; unknown contracts fail closed.
    /// Orchestrator types that commit on their own execute path declare write since issue #257 (only posting is
    /// irreversible), so they are refused by their own list before the effect is read.
    /// </summary>
    procedure CheckOmitCommitAllowed(PlaybookCode: Code[20]; StepNo: Integer; MessageType: Enum "Message Type ori")
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        EffectToken: JsonToken;
        EffectName: Text;
        TypeName: Text;
        TypeIndex: Integer;
    begin
        TypeIndex := MessageType.Ordinals().IndexOf(MessageType.AsInteger());
        if TypeIndex > 0 then
            TypeName := MessageType.Names().Get(TypeIndex)
        else
            TypeName := Format(MessageType.AsInteger(), 0, 9);

        if CommitsOnExecute(MessageType) then
            Error(OmitCommitCommitsErr, PlaybookCode, StepNo, TypeName);

        Contract := MessageType;
        if not Contract.GetEffect(Effect) then
            Error(OmitCommitNoContractErr, PlaybookCode, StepNo, TypeName);
        if not Effect.Get('effect', EffectToken) then
            Error(OmitCommitNoContractErr, PlaybookCode, StepNo, TypeName);
        if not EffectToken.IsValue() then
            Error(OmitCommitNoContractErr, PlaybookCode, StepNo, TypeName);
        if EffectToken.AsValue().IsNull() or EffectToken.AsValue().IsUndefined() then
            Error(OmitCommitNoContractErr, PlaybookCode, StepNo, TypeName);

        EffectName := EffectToken.AsValue().AsText();
        case EffectName of
            'read', 'write':
                exit;
            'irreversible':
                Error(OmitCommitIrreversibleErr, PlaybookCode, StepNo, TypeName);
            else
                Error(OmitCommitNoContractErr, PlaybookCode, StepNo, TypeName);
        end;
    end;

    /// <summary>
    /// The Orchestrator types that commit on their own execute path, so a rollback chain cannot undo them. Kept
    /// here because their effect (write, or irreversible for Entry.Run and Report.Run) does not say that they commit.
    /// </summary>
    /// <param name="MessageType">The type a step dispatches.</param>
    /// <returns>True when the type commits on its execute path.</returns>
    procedure CommitsOnExecute(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType in [
            "Message Type ori"::"Orchestrator.Email.Send",
            "Message Type ori"::"Orchestrator.Telegram.Message",
            "Message Type ori"::"Purchase.Order.Send",
            "Message Type ori"::"Sales.Quote.Send",
            "Message Type ori"::"Sales.OrderConfirmation.Send",
            "Message Type ori"::"Orchestrator.Playbook.Run",
            "Message Type ori"::"Orchestrator.Workspace.Preview",
            "Message Type ori"::"Orchestrator.Entry.Register",
            "Message Type ori"::"Orchestrator.Entry.Restart",
            "Message Type ori"::"Orchestrator.Entry.Schedule",
            "Message Type ori"::"Orchestrator.Entry.Run",
            "Message Type ori"::"Orchestrator.Status.Restart",
            "Message Type ori"::"Orchestrator.Status.RestartIfNeeded",
            "Message Type ori"::"Orchestrator.Report.Run"]);
    end;

    /// <summary>Checks every enabled Message step, including Check steps. Local Transform steps do not dispatch.</summary>
    procedure ValidateOmitCommitChain(PlaybookCode: Code[20])
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.SetRange("Playbook Code", PlaybookCode);
        PlaybookStep.SetRange(Disabled, false);
        // Transform runs locally and its Message Type is cleared, so it is not a dispatch contract.
        PlaybookStep.SetRange("Step Kind", PlaybookStep."Step Kind"::Message);
        PlaybookStep.SetLoadFields("Playbook Code", "Step No.", Disabled, "Step Kind", "Message Type");
        if PlaybookStep.FindSet() then
            repeat
                CheckOmitCommitAllowed(PlaybookCode, PlaybookStep."Step No.", PlaybookStep."Message Type");
            until PlaybookStep.Next() = 0;
    end;

    var
        OmitCommitIrreversibleErr: Label 'Playbook %1 step %2 cannot run %3 under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', Comment = '%1 = playbook code, %2 = step no, %3 = message type, is-IS=Skref %2 í keðjunni %1 getur ekki keyrt %3 með Omit Commit: samningur þess lýsir áhrifum sem ekki er hægt að afturkalla og því er ekki hægt að bakka því með keðjunni.';
        OmitCommitCommitsErr: Label 'Playbook %1 step %2 cannot run %3 under Omit Commit: the type commits on its own execute path, so it cannot be rolled back with the chain.', Comment = '%1 = playbook code, %2 = step no, %3 = message type, is-IS=Skref %2 í keðjunni %1 getur ekki keyrt %3 með Omit Commit: tegundin staðfestir sjálf breytingar sínar og því er ekki hægt að bakka henni með keðjunni.';
        OmitCommitNoContractErr: Label 'Playbook %1 step %2 cannot run %3 under Omit Commit: the type declares no effect contract, so it is treated as not safe to roll back.', Comment = '%1 = playbook code, %2 = step no, %3 = message type, is-IS=Skref %2 í keðjunni %1 getur ekki keyrt %3 með Omit Commit: tegundin lýsir ekki yfir neinum áhrifasamningi og því er ekki talið öruggt að bakka henni.';
}
