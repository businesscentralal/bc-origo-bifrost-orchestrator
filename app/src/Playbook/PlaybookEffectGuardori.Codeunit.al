namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Validates effect contracts before a future Omit Commit dispatch is enabled.</summary>
codeunit 10035554 "Playbook Effect Guard ori"
{
    Access = Internal;

    /// <summary>Allows only explicit read or write effects; unknown contracts fail closed.</summary>
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

    /// <summary>Checks every enabled dispatching step, including Check steps that still call a type.</summary>
    procedure ValidateOmitCommitChain(PlaybookCode: Code[20])
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.SetRange("Playbook Code", PlaybookCode);
        PlaybookStep.SetRange(Disabled, false);
        PlaybookStep.SetLoadFields("Playbook Code", "Step No.", Disabled, "Message Type");
        if PlaybookStep.FindSet() then
            repeat
                CheckOmitCommitAllowed(PlaybookCode, PlaybookStep."Step No.", PlaybookStep."Message Type");
            until PlaybookStep.Next() = 0;
    end;

    var
        OmitCommitIrreversibleErr: Label 'Playbook %1 step %2 cannot run %3 under Omit Commit: its contract declares effect irreversible, so it cannot be rolled back with the chain.', Locked = true;
        OmitCommitNoContractErr: Label 'Playbook %1 step %2 cannot run %3 under Omit Commit: the type declares no effect contract, so it is treated as not safe to roll back.', Locked = true;
}
