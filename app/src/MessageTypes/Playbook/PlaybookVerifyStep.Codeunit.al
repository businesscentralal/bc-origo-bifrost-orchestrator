/// <summary>
/// The checks of Orchestrator.Playbook.Verify that look at one step and its place in the playbook: the message
/// type, the Success condition, the Next Step edges, the forEach source and the per-item gate.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

codeunit 10035617 "Playbook Verify Step ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Step ori" = R,
                  tabledata "Playbook Condition ori" = R;

    /// <summary>
    /// Runs every step-level check on one step.
    /// </summary>
    /// <param name="Step">The step to check; loaded with the fields the checks read.</param>
    /// <param name="Findings">Receives the findings of the step.</param>
    internal procedure CheckStep(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    begin
        CheckMessageType(Step, Findings);
        CheckSuccessCondition(Step, Findings);
        CheckNextSteps(Step, Findings);
        CheckIterateSource(Step, Findings);
        CheckSkipGate(Step, Findings);
        CheckSourceGuard(Step, Findings);
        CheckUnsafeWrite(Step, Findings);
    end;

    local procedure CheckMessageType(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        if Verify.IsTypeEnabled(Step."Message Type") then
            exit;
        // A type that exists but is not enabled for this user (Telegram without a chat ID, a type the user may not
        // use) is the very thing a Start condition on the step guards against, as the reporting tail does with
        // _who.telegramChatId Exists: the author has decided when the step runs, so it is not judged. An unknown
        // ordinal is never right.
        if Verify.IsTypeListed(Step."Message Type") and Step.HasConditions("Playbook Cond. Type ori"::Start) then
            exit;
        Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'MessageTypeUnavailable',
            StrSubstNo(MessageTypeUnavailableMsg, Step."Step No.", Verify.GetTypeName(Step."Message Type")),
            MessageTypeUnavailableNextStepTxt, Step.Disabled);
    end;

    local procedure CheckSuccessCondition(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        if Step.HasConditions("Playbook Cond. Type ori"::Success) then
            exit;
        if Step.IsCheck() then
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'CheckWithoutSuccessCondition',
                StrSubstNo(CheckWithoutConditionMsg, Step."Step No."), StrSubstNo(CheckWithoutConditionNextStepTxt, Step."Step No."), Step.Disabled)
        else
            Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'ActionWithoutSuccessCondition',
                StrSubstNo(ActionWithoutConditionMsg, Step."Step No."), StrSubstNo(ActionWithoutConditionNextStepTxt, Step."Step No."), Step.Disabled);
    end;

    local procedure CheckNextSteps(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        if (Step."Next Step No. (Success)" > 0) and not StepExists(Step."Playbook Code", Step."Next Step No. (Success)") then
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'NextStepNotFound',
                StrSubstNo(NextStepNotFoundMsg, Step."Step No.", Step.FieldCaption("Next Step No. (Success)"), Step."Next Step No. (Success)"),
                StrSubstNo(NextStepNotFoundNextStepTxt, Step.FieldCaption("Next Step No. (Success)"), Step."Step No."), Step.Disabled);
        if (Step."Next Step No. (Failure)" > 0) and not StepExists(Step."Playbook Code", Step."Next Step No. (Failure)") then
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'NextStepNotFound',
                StrSubstNo(NextStepNotFoundMsg, Step."Step No.", Step.FieldCaption("Next Step No. (Failure)"), Step."Next Step No. (Failure)"),
                StrSubstNo(NextStepNotFoundNextStepTxt, Step.FieldCaption("Next Step No. (Failure)"), Step."Step No."), Step.Disabled);
    end;

    local procedure CheckIterateSource(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        if not Step.IsForEach() then
            exit;
        if (Step."Iterate Source Step No." > 0) and (Step."Iterate Source Step No." < Step."Step No.") and
           StepExists(Step."Playbook Code", Step."Iterate Source Step No.")
        then
            exit;
        Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'IterateSourceInvalid',
            StrSubstNo(IterateSourceInvalidMsg, Step."Step No.", Step."Iterate Source Step No."),
            StrSubstNo(IterateSourceInvalidNextStepTxt, Step."Step No."), Step.Disabled);
    end;

    local procedure CheckSkipGate(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        GateStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        GateIsValid: Boolean;
    begin
        // Skip If Step Failed is only read for a forEach step; on a single step it does nothing.
        if (Step."Skip If Step Failed" = 0) or not Step.IsForEach() then
            exit;

        GateStep.SetLoadFields("Iterate Array Path");
        if (Step."Skip If Step Failed" < Step."Step No.") and GateStep.Get(Step."Playbook Code", Step."Skip If Step Failed") then
            GateIsValid := GateStep.IsForEach();
        if GateIsValid then
            exit;
        Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'InvalidSkipGate',
            StrSubstNo(InvalidSkipGateMsg, Step."Step No.", Step."Skip If Step Failed"),
            StrSubstNo(InvalidSkipGateNextStepTxt, Step."Step No."), Step.Disabled);
    end;

    /// <summary>
    /// A forEach step iterates the answer of its source step. When the source is a record reader whose Success
    /// conditions do not look at noOfRecords, an empty answer still succeeds and the forEach silently does nothing.
    /// Reported once per source step, from its first forEach consumer.
    /// </summary>
    local procedure CheckSourceGuard(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        SourceStep: Record "Playbook Step ori";
        EarlierConsumer: Record "Playbook Step ori";
        Condition: Record "Playbook Condition ori";
        Verify: Codeunit "Playbook Verify ori";
        TypeName: Text;
    begin
        if not Step.IsForEach() then
            exit;
        SourceStep.SetLoadFields("Step No.", "Message Type", Disabled);
        if not SourceStep.Get(Step."Playbook Code", Step."Iterate Source Step No.") then
            exit;
        TypeName := Verify.GetTypeName(SourceStep."Message Type");
        if not Verify.IsRecordReaderMessageType(TypeName) then
            exit;

        EarlierConsumer.SetLoadFields("Step No.");
        EarlierConsumer.SetRange("Playbook Code", Step."Playbook Code");
        EarlierConsumer.SetRange("Iterate Source Step No.", SourceStep."Step No.");
        EarlierConsumer.SetFilter("Iterate Array Path", '<>%1', '');
        EarlierConsumer.SetFilter("Step No.", '<%1', Step."Step No.");
        if not EarlierConsumer.IsEmpty() then
            exit;

        Condition.FilterForStep(Step."Playbook Code", SourceStep."Step No.", "Playbook Cond. Type ori"::Success);
        Condition.SetRange(Path, 'noOfRecords');
        if not Condition.IsEmpty() then
            exit;
        Verify.AddFinding(Findings, Verify.WarningSeverity(), SourceStep."Step No.", 'ForEachSourceUnguarded',
            StrSubstNo(SourceUnguardedMsg, SourceStep."Step No.", TypeName),
            StrSubstNo(SourceUnguardedNextStepTxt, SourceStep."Step No."), SourceStep.Disabled);
    end;

    /// <summary>
    /// Warning <c>UnsafeForEachWrite</c>: an enabled forEach step with a write-type message type iterates the same
    /// array as an earlier, enabled forEach Check step and has <c>Skip If Step Failed = 0</c>. The Next Step edges of
    /// a forEach step apply once for the whole step, never per item, so only <c>Skip If Step Failed</c> gates the
    /// write per item.
    /// </summary>
    local procedure CheckUnsafeWrite(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        GateCheck: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Finding: JsonObject;
        MessageTypeName: Text;
    begin
        if Step.Disabled or not Step.IsForEach() or (Step."Skip If Step Failed" <> 0) then
            exit;
        MessageTypeName := Verify.GetTypeName(Step."Message Type");
        if not Verify.IsWriteMessageType(MessageTypeName) then
            exit;

        GateCheck.SetLoadFields("Step No.");
        GateCheck.SetRange("Playbook Code", Step."Playbook Code");
        GateCheck.SetRange("Step Type", GateCheck."Step Type"::Check);
        GateCheck.SetRange(Disabled, false);
        GateCheck.SetFilter("Step No.", '<%1', Step."Step No.");
        GateCheck.SetRange("Iterate Source Step No.", Step."Iterate Source Step No.");
        GateCheck.SetRange("Iterate Array Path", Step."Iterate Array Path");
        if not GateCheck.FindLast() then
            exit;

        Finding := Verify.BuildFinding(Verify.WarningSeverity(), Step."Step No.", 'UnsafeForEachWrite',
            StrSubstNo(UnsafeForEachWriteMsg, Step."Step No.", MessageTypeName, GateCheck."Step No."),
            StrSubstNo(UnsafeForEachWriteNextStepTxt, GateCheck."Step No.", Step."Step No."), false);
        Finding.Add('checkStepNo', GateCheck."Step No.");
        Findings.Add(Finding);
    end;

    local procedure StepExists(PlaybookCode: Code[20]; StepNo: Integer): Boolean
    var
        Step: Record "Playbook Step ori";
    begin
        Step.SetLoadFields("Step No.");
        exit(Step.Get(PlaybookCode, StepNo));
    end;

    var
        MessageTypeUnavailableMsg: Label 'Step %1 calls message type %2, which does not exist in this deployment or is not enabled for this user in this company. Every run of the step would fail.', Comment = '%1 = step no, %2 = message type, is-IS=Skref %1 kallar á skilaboðategundina %2, sem er ekki til í þessari uppsetningu eða er ekki virk fyrir þennan notanda í þessu fyrirtæki. Hver keyrsla skrefsins myndi mistakast.';
        MessageTypeUnavailableNextStepTxt: Label 'Call Help.MessageTypes.Get (or describe_message_type) to find the exact name of the message type, check that the app that provides it is installed and that you may use it, then correct the step.', Comment = 'is-IS=Kallaðu á Help.MessageTypes.Get (eða describe_message_type) til að finna nákvæmt heiti skilaboðategundarinnar, athugaðu að forritið sem býr hana til sé uppsett og að þú megir nota hana og lagaðu svo skrefið.';
        CheckWithoutConditionMsg: Label 'Check step %1 has no Success condition, so it answers yes every time and decides nothing.', Comment = '%1 = step no, is-IS=Athugunarskref %1 hefur ekkert árangursskilyrði, svo það svarar alltaf já og ákveður ekkert.';
        CheckWithoutConditionNextStepTxt: Label 'Add a Success condition to step %1 (a Playbook Condition ori row with ConditionType Success), for example status Equals Success and the value the decision depends on.', Comment = '%1 = step no, is-IS=Bættu árangursskilyrði við skref %1 (færsla í Playbook Condition ori með ConditionType Success), til dæmis status Equals Success og gildið sem ákvörðunin byggir á.';
        ActionWithoutConditionMsg: Label 'Step %1 has no Success condition, so it counts as successful whenever the message type does not raise an error, also when it answers status Error.', Comment = '%1 = step no, is-IS=Skref %1 hefur ekkert árangursskilyrði, svo það telst árangursríkt svo lengi sem skilaboðategundin kastar ekki villu, líka þegar hún svarar status Error.';
        ActionWithoutConditionNextStepTxt: Label 'Add the Success condition status Equals Success to step %1.', Comment = '%1 = step no, is-IS=Bættu árangursskilyrðinu status Equals Success við skref %1.';
        NextStepNotFoundMsg: Label 'Step %1 has %2 = %3, but the playbook has no step %3. The run would stop there with an error.', Comment = '%1 = step no, %2 = field caption, %3 = the missing step no, is-IS=Skref %1 er með %2 = %3, en keðjan hefur ekkert skref %3. Keyrslan myndi stöðvast þar með villu.';
        NextStepNotFoundNextStepTxt: Label 'Set %1 on step %2 to a step that exists, or to 0 to end the playbook.', Comment = '%1 = field caption, %2 = step no, is-IS=Stilltu %1 í skrefi %2 á skref sem er til, eða á 0 til að ljúka keðjunni.';
        IterateSourceInvalidMsg: Label 'Step %1 iterates over the result of step %2 (Iterate Source Step No.), which does not exist or does not come before step %1, so the step would do nothing.', Comment = '%1 = step no, %2 = source step no, is-IS=Skref %1 ítrar yfir niðurstöðu skrefs %2 (Upprunaskref ítrunar), sem er ekki til eða kemur ekki á undan skrefi %1, svo skrefið myndi ekkert gera.';
        IterateSourceInvalidNextStepTxt: Label 'Set Iterate Source Step No. on step %1 to the number of an earlier step that produces the array.', Comment = '%1 = step no, is-IS=Stilltu Upprunaskref ítrunar í skrefi %1 á númer fyrra skrefs sem skilar fylkinu.';
        InvalidSkipGateMsg: Label 'Step %1 has Skip If Step Failed = %2, but step %2 does not exist, does not come before step %1 or does not iterate, so it records no result per item and every item of step %1 would be skipped.', Comment = '%1 = step no, %2 = gate step no, is-IS=Skref %1 er með Sleppa ef skref mistókst = %2, en skref %2 er ekki til, kemur ekki á undan skrefi %1 eða ítrar ekki, svo það skráir enga niðurstöðu fyrir hvert atriði og öllum atriðum skrefs %1 yrði sleppt.';
        InvalidSkipGateNextStepTxt: Label 'Set Skip If Step Failed on step %1 to the number of the earlier forEach step that decides, or to 0.', Comment = '%1 = step no, is-IS=Stilltu Sleppa ef skref mistókst í skrefi %1 á númer fyrra forEach-skrefs sem ákveður, eða á 0.';
        SourceUnguardedMsg: Label 'Step %1 (%2) feeds a forEach but has no Success condition on noOfRecords. When it finds no records it still succeeds, the forEach does nothing and the run completes having done nothing.', Comment = '%1 = step no, %2 = message type, is-IS=Skref %1 (%2) fóðrar forEach en hefur ekkert árangursskilyrði á noOfRecords. Þegar það finnur engar færslur heppnast það samt, forEach gerir ekkert og keyrslunni lýkur án þess að nokkuð hafi verið gert.';
        SourceUnguardedNextStepTxt: Label 'Add the Success condition noOfRecords GreaterThan 0 to step %1, beside status Equals Success, in the same group.', Comment = '%1 = step no, is-IS=Bættu árangursskilyrðinu noOfRecords GreaterThan 0 við skref %1, við hlið status Equals Success, í sama hópi.';
        UnsafeForEachWriteMsg: Label 'Step %1 (%2) writes for every item of an array that an earlier forEach Check step %3 decides on, but Skip If Step Failed is not set to %3. Next Step edges apply once per step, not per item, so this step runs for all items, also those the check answered no. Set Skip If Step Failed to %3 on step %1.', Comment = '%1 = step no, %2 = message type, %3 = check step no, is-IS=Skref %1 (%2) skrifar fyrir öll atriði fylkis sem forEach-athugunarskref %3 á undan tekur ákvörðun um, en Sleppa ef skref mistókst er ekki stillt á %3. Næsta skref gildir einu sinni fyrir skrefið, ekki fyrir hvert atriði, svo þetta skref keyrir fyrir öll atriði, líka þau sem athugunin svaraði nei. Stilltu Sleppa ef skref mistókst á %3 í skrefi %1.';
        UnsafeForEachWriteNextStepTxt: Label 'Set Skip If Step Failed to %1 on step %2.', Comment = '%1 = check step no, %2 = write step no, is-IS=Stilltu Sleppa ef skref mistókst á %1 í skrefi %2.';
}
