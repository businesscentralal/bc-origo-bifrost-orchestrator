/// <summary>
/// Reads a playbook and reports the configuration mistakes the engine accepts silently, as findings
/// with a severity (error or warning), the step, a code, a message and the next step to take.
/// The messages are returned in the language of the calling session. The same verification gates
/// <c>Orchestrator.Playbook.Run</c> and the enabling of a schedule: they refuse a playbook with error
/// findings, and with warnings unless the caller accepts them on purpose.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035616 "Playbook Verify ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook ori" = R,
                  tabledata "Playbook Step ori" = R,
                  tabledata "Playbook Condition ori" = R,
                  tabledata "Scheduled Entry ori" = R;

    /// <summary>
    /// Verifies the playbook named in the request and answers with the findings.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteVerify(var Argument: Record "Message Argument ori")
    var
        Playbook: Record "Playbook ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Findings: JsonArray;
    begin
        RequestJson := Argument.GetRequestJson();
        Playbook.SetLoadFields(Code);
        Playbook.Get(GetPlaybookCode(Argument, RequestJson));

        GetFindings(Playbook.Code, Findings);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('playbookCode', Playbook.Code);
        ResponseJson.Add('valid', CountFindings(Findings, ErrorTok) = 0);
        ResponseJson.Add('errorCount', CountFindings(Findings, ErrorTok));
        ResponseJson.Add('warningCount', CountFindings(Findings, WarningTok));
        ResponseJson.Add('findings', Findings);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// Collects the findings for one playbook, in step order, then the findings about the playbook as a whole.
    /// Every step is checked, enabled or not, so a playbook built with all steps disabled can be verified
    /// before anything is switched on; a finding about a disabled step carries <c>stepDisabled: true</c>
    /// and never blocks a run or a schedule.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to verify.</param>
    /// <param name="Findings">Receives one object per finding: severity, stepNo, code, message and nextStep.</param>
    procedure GetFindings(PlaybookCode: Code[20]; var Findings: JsonArray)
    var
        Step: Record "Playbook Step ori";
        StepChecks: Codeunit "Playbook Verify Step ori";
        TemplateChecks: Codeunit "Playbook Verify Template ori";
    begin
        Clear(Findings);
        Step.SetLoadFields("Step No.", Description, "Step Type", "Message Type", "Iterate Array Path", "Iterate Source Step No.",
            "Next Step No. (Success)", "Next Step No. (Failure)", "Skip If Step Failed", "Result Log Paths", Disabled, Paged);
        Step.SetRange("Playbook Code", PlaybookCode);
        if Step.FindSet() then
            repeat
                StepChecks.CheckStep(Step, Findings);
                TemplateChecks.CheckTemplate(Step, Findings);
            until Step.Next() = 0;

        CheckScheduleWithErrors(PlaybookCode, Findings);
    end;

    /// <summary>
    /// Refuses to start a playbook that does not verify: answers PreconditionFailed on the playbook code, lists
    /// the findings that block in the answer and returns true. Errors always block; warnings block unless the
    /// caller set ignoreWarnings. Findings about disabled steps never block.
    /// </summary>
    /// <param name="Argument">The argument that receives the refusal.</param>
    /// <param name="PlaybookCode">The playbook about to run or to be scheduled.</param>
    /// <param name="IgnoreWarnings">True when the caller accepts the warnings on purpose.</param>
    /// <returns>True when the call was refused and the answer is set; the caller must stop.</returns>
    procedure RefuseIfUnsafe(var Argument: Record "Message Argument ori"; PlaybookCode: Code[20]; IgnoreWarnings: Boolean): Boolean
    var
        Blocking: JsonArray;
        ResponseJson: JsonObject;
        Summary: Text;
    begin
        if not GetBlockingFindings(PlaybookCode, IgnoreWarnings, Blocking, Summary) then
            exit(false);

        // The answer has the shape of Argument.RespondWithError (status, code, error, parameter, received, expected,
        // nextStep) and carries the blocking findings, so the caller does not have to call Verify to read them.
        ResponseJson.Add('status', 'Error');
        ResponseJson.Add('code', 'PreconditionFailed');
        ResponseJson.Add('error', Summary);
        ResponseJson.Add('parameter', 'playbookCode');
        ResponseJson.Add('received', PlaybookCode);
        ResponseJson.Add('expected', ExpectedTxt);
        ResponseJson.Add('nextStep', RefusedNextStepTxt);
        ResponseJson.Add('findings', Blocking);
        Argument.SetResponseJson(ResponseJson);
        exit(true);
    end;

    /// <summary>
    /// Raises an error that lists the blocking findings when the playbook does not verify. For callers that
    /// answer with a plain error, such as the schedule dialog and the schedule table procedure.
    /// </summary>
    /// <param name="PlaybookCode">The playbook about to run or to be scheduled.</param>
    /// <param name="IgnoreWarnings">True when the caller accepts the warnings on purpose.</param>
    procedure AssertSafeToStart(PlaybookCode: Code[20]; IgnoreWarnings: Boolean)
    var
        Blocking: JsonArray;
        Summary: Text;
    begin
        if GetBlockingFindings(PlaybookCode, IgnoreWarnings, Blocking, Summary) then
            Error('%1 %2', Summary, RefusedNextStepTxt);
    end;

    /// <summary>
    /// Collects the findings that stop a playbook from starting.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to verify.</param>
    /// <param name="IgnoreWarnings">True when warnings do not block.</param>
    /// <param name="Blocking">Receives the blocking findings.</param>
    /// <param name="Summary">Receives the refusal text, naming the playbook, the counts and each blocking finding.</param>
    /// <returns>True when at least one finding blocks.</returns>
    procedure GetBlockingFindings(PlaybookCode: Code[20]; IgnoreWarnings: Boolean; var Blocking: JsonArray; var Summary: Text): Boolean
    var
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        Lines: TextBuilder;
        Severity: Text;
    begin
        Clear(Blocking);
        Clear(Summary);
        GetFindings(PlaybookCode, Findings);
        foreach Token in Findings do begin
            Finding := Token.AsObject();
            if not Finding.Contains('stepDisabled') then begin
                Severity := GetText(Finding, 'severity');
                if (Severity = ErrorTok) or ((Severity = WarningTok) and not IgnoreWarnings) then begin
                    Blocking.Add(Finding);
                    Lines.Append(StrSubstNo(FindingLineTxt, GetText(Finding, 'stepNo'), GetText(Finding, 'code'), GetText(Finding, 'message')));
                    Lines.Append(' ');
                end;
            end;
        end;
        if Blocking.Count() = 0 then
            exit(false);
        Summary := StrSubstNo(RefusedTxt, PlaybookCode, CountFindings(Blocking, ErrorTok), CountFindings(Blocking, WarningTok), Lines.ToText().TrimEnd());
        exit(true);
    end;

    /// <summary>
    /// Counts the findings of one severity.
    /// </summary>
    /// <param name="Findings">The findings.</param>
    /// <param name="Severity">The severity, error or warning.</param>
    /// <returns>The number of findings with that severity.</returns>
    procedure CountFindings(Findings: JsonArray; Severity: Text): Integer
    var
        Token: JsonToken;
        Count: Integer;
    begin
        foreach Token in Findings do
            if GetText(Token.AsObject(), 'severity') = Severity then
                Count += 1;
        exit(Count);
    end;

    /// <summary>
    /// Builds one finding.
    /// </summary>
    /// <param name="Severity">The severity, error or warning.</param>
    /// <param name="StepNo">The step the finding is about, or 0 for the playbook as a whole.</param>
    /// <param name="FindingCode">The stable code of the finding.</param>
    /// <param name="MessageText">What is wrong, in the language of the session.</param>
    /// <param name="NextStepText">What to do about it, in the language of the session.</param>
    /// <param name="StepDisabled">True when the step is disabled.</param>
    /// <returns>The finding object.</returns>
    internal procedure BuildFinding(Severity: Text; StepNo: Integer; FindingCode: Text; MessageText: Text; NextStepText: Text; StepDisabled: Boolean) Finding: JsonObject
    begin
        Finding.Add('severity', Severity);
        Finding.Add('stepNo', StepNo);
        Finding.Add('code', FindingCode);
        Finding.Add('message', MessageText);
        Finding.Add('nextStep', NextStepText);
        if StepDisabled then
            Finding.Add('stepDisabled', true);
    end;

    /// <summary>
    /// Adds one finding to the list.
    /// </summary>
    /// <param name="Findings">The list the finding is added to.</param>
    /// <param name="Severity">The severity, error or warning.</param>
    /// <param name="StepNo">The step the finding is about, or 0 for the playbook as a whole.</param>
    /// <param name="FindingCode">The stable code of the finding.</param>
    /// <param name="MessageText">What is wrong, in the language of the session.</param>
    /// <param name="NextStepText">What to do about it, in the language of the session.</param>
    /// <param name="StepDisabled">True when the step is disabled.</param>
    internal procedure AddFinding(var Findings: JsonArray; Severity: Text; StepNo: Integer; FindingCode: Text; MessageText: Text; NextStepText: Text; StepDisabled: Boolean)
    begin
        Findings.Add(BuildFinding(Severity, StepNo, FindingCode, MessageText, NextStepText, StepDisabled));
    end;

    /// <summary>
    /// The severity of a finding that stops a run and a schedule.
    /// </summary>
    /// <returns>The text error.</returns>
    internal procedure ErrorSeverity(): Text
    begin
        exit(ErrorTok);
    end;

    /// <summary>
    /// The severity of a finding that stops a run and a schedule unless the caller accepts it.
    /// </summary>
    /// <returns>The text warning.</returns>
    internal procedure WarningSeverity(): Text
    begin
        exit(WarningTok);
    end;

    /// <summary>
    /// Names a message type the way a step stores it: its invariant dotted name, or Unknown(ordinal) when the
    /// enum no longer lists the value (the app that provided it is gone).
    /// </summary>
    /// <param name="MessageType">The message type of a step.</param>
    /// <returns>The invariant name.</returns>
    internal procedure GetTypeName(MessageType: Enum "Message Type ori"): Text
    var
        Index: Integer;
    begin
        Index := MessageType.Ordinals().IndexOf(MessageType.AsInteger());
        if Index = 0 then
            exit(StrSubstNo(UnknownNameTok, Format(MessageType.AsInteger(), 0, 9)));
        exit(MessageType.Names().Get(Index));
    end;

    /// <summary>
    /// Tells whether a message type exists in this deployment and is enabled for the calling user in this
    /// company. An unknown ordinal and a type whose own check raises are not enabled.
    /// </summary>
    /// <param name="MessageType">The message type of a step.</param>
    /// <returns>True when the type can be dispatched.</returns>
    internal procedure IsTypeEnabled(MessageType: Enum "Message Type ori"): Boolean
    var
        Enabled: Boolean;
    begin
        if not TryIsEnabled(MessageType, Enabled) then
            exit(false);
        exit(Enabled);
    end;

    /// <summary>
    /// Tells whether the enum lists the message type: an app that provided it may be gone, and then the ordinal is unknown.
    /// </summary>
    /// <param name="MessageType">The message type of a step.</param>
    /// <returns>True when the enum lists the ordinal.</returns>
    internal procedure IsTypeListed(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType.Ordinals().Contains(MessageType.AsInteger()));
    end;

    [TryFunction]
    local procedure TryIsEnabled(MessageType: Enum "Message Type ori"; var Enabled: Boolean)
    var
        MessageTypeInterface: Interface "Msg Interface ori";
    begin
        MessageTypeInterface := MessageType;
        Enabled := MessageTypeInterface.IsEnabled();
    end;

    /// <summary>
    /// Tells whether a message type name is a write: its last segment is one of the verbs that
    /// change data or send something out (Set, Post, Delete, Create, Update, Send, ...).
    /// </summary>
    /// <param name="MessageTypeName">The invariant dotted message type name, for example "Data.Records.Set".</param>
    /// <returns>True when the message type writes.</returns>
    procedure IsWriteMessageType(MessageTypeName: Text): Boolean
    var
        Verb: Text;
        Verbs: List of [Text];
        Segments: List of [Text];
    begin
        Segments := MessageTypeName.Split('.');
        if Segments.Count() < 2 then
            exit(false);
        Verb := Segments.Get(Segments.Count());

        Verbs.AddRange('Set', 'Post', 'Delete', 'Create', 'Update', 'Insert', 'Modify', 'Cancel', 'Correct',
            'Send', 'MakeOrder', 'Release', 'Reopen', 'Approve', 'Reject', 'Register', 'Schedule', 'Enqueue');
        exit(Verbs.Contains(Verb));
    end;

    /// <summary>
    /// Tells whether a message type reads records and answers <c>noOfRecords</c> beside its <c>result</c> array:
    /// a data reader (name starts with Data. and ends in Get, Find, Search or List).
    /// </summary>
    /// <param name="MessageTypeName">The invariant dotted message type name, for example "Data.Records.Get".</param>
    /// <returns>True when the message type is a record reader.</returns>
    procedure IsRecordReaderMessageType(MessageTypeName: Text): Boolean
    var
        Verbs: List of [Text];
        Segments: List of [Text];
    begin
        if not MessageTypeName.StartsWith('Data.') then
            exit(false);
        Segments := MessageTypeName.Split('.');
        Verbs.AddRange('Get', 'Find', 'Search', 'List');
        exit(Verbs.Contains(Segments.Get(Segments.Count())));
    end;

    local procedure CheckScheduleWithErrors(PlaybookCode: Code[20]; var Findings: JsonArray)
    var
        Playbook: Record "Playbook ori";
        Token: JsonToken;
        Finding: JsonObject;
        ErrorCount: Integer;
    begin
        Playbook.SetLoadFields(Code, "Orchestrator Entry ID");
        if not Playbook.Get(PlaybookCode) then
            exit;
        Playbook.CalcFields(Scheduled);
        if not Playbook.Scheduled then
            exit;

        // Only an error on an enabled step counts: that is what the next scheduled run would meet.
        foreach Token in Findings do begin
            Finding := Token.AsObject();
            if (GetText(Finding, 'severity') = ErrorTok) and not Finding.Contains('stepDisabled') then
                ErrorCount += 1;
        end;
        if ErrorCount > 0 then
            AddFinding(Findings, ErrorTok, 0, 'ScheduledWithErrors', StrSubstNo(ScheduledWithErrorsMsg, PlaybookCode, ErrorCount), ScheduledWithErrorsNextStepTxt, false);
    end;

    local procedure GetText(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Source.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetPlaybookCode(var Argument: Record "Message Argument ori"; RequestJson: JsonObject): Code[20]
    var
        PlaybookCodeToken: JsonToken;
    begin
        if RequestJson.Get('playbookCode', PlaybookCodeToken) then
            exit(CopyStr(PlaybookCodeToken.AsValue().AsText(), 1, 20));
        if Argument.Subject <> '' then
            exit(CopyStr(Argument.Subject, 1, 20));
        Error(MissingPlaybookCodeErr);
    end;

    var
        ErrorTok: Label 'error', Locked = true;
        WarningTok: Label 'warning', Locked = true;
        UnknownNameTok: Label 'Unknown(%1)', Locked = true;
        MissingPlaybookCodeErr: Label 'Request must include "playbookCode" in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "playbookCode" í gagnahleðslunni eða sem viðfang.';
        RefusedTxt: Label 'Playbook %1 was not started: errors on enabled steps: %2, warnings: %3. %4', Comment = '%1 = playbook code, %2 = number of errors, %3 = number of warnings, %4 = the findings, is-IS=Keðjan %1 var ekki ræst: villur í virkum skrefum: %2, viðvaranir: %3. %4';
        FindingLineTxt: Label 'Step %1 [%2]: %3', Comment = '%1 = step no, %2 = finding code, %3 = the message, is-IS=Skref %1 [%2]: %3';
        ExpectedTxt: Label 'a playbook whose enabled steps verify without errors, and without warnings unless ignoreWarnings is true', Comment = 'is-IS=keðja þar sem virk skref sannreynast án villna, og án viðvarana nema ignoreWarnings sé true';
        RefusedNextStepTxt: Label 'Call Orchestrator.Playbook.Verify with the same playbookCode, fix the findings, then call again. A warning can be accepted on purpose with ignoreWarnings = true; an error cannot.', Comment = 'is-IS=Kallaðu á Orchestrator.Playbook.Verify með sama playbookCode, lagaðu niðurstöðurnar og kallaðu svo aftur. Viðvörun má samþykkja viljandi með ignoreWarnings = true; villu má ekki samþykkja.';
        ScheduledWithErrorsMsg: Label 'Playbook %1 is scheduled, but its enabled steps have errors (%2) that will fail the next scheduled run.', Comment = '%1 = playbook code, %2 = number of errors, is-IS=Keðjan %1 er tímasett, en virk skref hennar eru með villur (%2) sem láta næstu tímasettu keyrslu mistakast.';
        ScheduledWithErrorsNextStepTxt: Label 'Fix the errors above, or remove the schedule (delete the Scheduled Entry ori of the playbook) until they are fixed.', Comment = 'is-IS=Lagaðu villurnar hér að ofan, eða fjarlægðu tímasetninguna (eyddu Scheduled Entry ori keðjunnar) þar til þær eru lagaðar.';
}
