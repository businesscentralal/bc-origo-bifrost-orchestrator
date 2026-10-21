namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Completeness guard for the message type contracts and discovery texts of Bifrost Orchestrator, in the
/// shape of Foundation's contract tests. It walks every message type of this app (the enum values named
/// Orchestrator.* and Help.Orchestrator.Get) and fails when a type lacks a required chapter, declares an
/// error without a code, an effect that disagrees with its direction, an example that is not a real request,
/// AL object names in its help text, or discovery texts that are missing, shared with a sibling or not
/// translated into Icelandic.
/// </summary>
codeunit 96441 "Contract Complete Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TheGuardSeesEveryOrchestratorType()
    begin
        // [SCENARIO] The guard enumerates the types of this app from the enum, so a new type is checked without a list to maintain.
        Assert.IsTrue(OrchestratorTypes().Count() >= 24, 'At least the 24 released types are found');
    end;

    [Test]
    procedure EveryType_DeclaresTheRequiredChapters()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Chapter: Text;
        TypeName: Text;
        Required: List of [Text];
        Ordinal: Integer;
    begin
        // [SCENARIO] Every type answers with an envelope, response, errors, effect, metering, related, examples, overview and notes;
        // parameters unless it reads none; a target when it reads subject.
        Required.AddRange('envelope', 'response', 'errors', 'effect', 'metering', 'related', 'examples', 'overview', 'notes');
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            foreach Chapter in Required do
                Assert.IsTrue(Contract.Contains(Chapter), TypeName + ' declares ' + Chapter);
            if not TypeReadsNoParameters(TypeName) then
                Assert.IsTrue(Contract.Contains('parameters'), TypeName + ' declares parameters');
            if SubjectTypes().Contains(TypeName) then
                Assert.IsTrue(Contract.Contains('target'), TypeName + ' reads subject, so it declares a target');
        end;
    end;

    [Test]
    procedure EveryType_EnvelopeStatesSubjectStrictAndContentType()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Envelope: JsonObject;
        Subject: JsonObject;
        Strict: JsonObject;
        Token: JsonToken;
        TypeName: Text;
        ExpectedUse: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] The envelope says whether subject is read (only the types that read it say optional), carries the root
        // option strict that Foundation honours, and names the content type of the answer.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('envelope', Token);
            Envelope := Token.AsObject();
            Envelope.Get('subject', Token);
            Subject := Token.AsObject();
            ExpectedUse := 'notUsed';
            if SubjectTypes().Contains(TypeName) then
                ExpectedUse := 'optional';
            Assert.AreEqual(ExpectedUse, TextOf(Subject, 'use'), TypeName + ' subject use');
            if ExpectedUse = 'optional' then begin
                Assert.IsTrue(Subject.Contains('forms'), TypeName + ' lists the subject forms');
                Assert.AreNotEqual('', TextOf(Subject, 'description'), TypeName + ' says what subject identifies');
            end;
            Assert.IsTrue(Envelope.Get('strict', Token), TypeName + ' declares strict');
            Strict := Token.AsObject();
            Assert.AreEqual('boolean', TextOf(Strict, 'type'), TypeName + ' strict type');
            Assert.IsTrue(Strict.Contains('default'), TypeName + ' strict default');
            Assert.AreEqual('1.0', TextOf(Envelope, 'version'), TypeName + ' version');
            Assert.AreNotEqual('', TextOf(Envelope, 'contentType'), TypeName + ' content type');
            Assert.IsTrue(Envelope.Contains('dataRequired'), TypeName + ' states dataRequired');
        end;
    end;

    [Test]
    procedure EveryType_ParametersAndResponseFieldsAreDescribed()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Response: JsonObject;
        Entry: JsonToken;
        Token: JsonToken;
        TypeName: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Every declared parameter and every response field has a name, a JSON type and a description.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            if Contract.Get('parameters', Token) then
                foreach Entry in Token.AsArray() do begin
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'name'), TypeName + ' parameter name');
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'type'), TypeName + ' parameter ' + TextOf(Entry.AsObject(), 'name') + ' type');
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'description'), TypeName + ' parameter ' + TextOf(Entry.AsObject(), 'name') + ' description');
                end;
            Contract.Get('response', Token);
            Response := Token.AsObject();
            Assert.AreNotEqual('', TextOf(Response, 'contentType'), TypeName + ' response content type');
            Response.Get('fields', Token);
            Assert.IsTrue(Token.AsArray().Count() > 0, TypeName + ' lists response fields');
            foreach Entry in Token.AsArray() do begin
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'name'), TypeName + ' response field name');
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'type'), TypeName + ' response field ' + TextOf(Entry.AsObject(), 'name') + ' type');
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'description'), TypeName + ' response field ' + TextOf(Entry.AsObject(), 'name') + ' description');
            end;
        end;
    end;

    [Test]
    procedure EveryType_EachErrorHasACodeOrATextAndTheStepToTake()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        ErrorCode: Enum "Bifrost Error Code ori";
        Contract: JsonObject;
        Entry: JsonToken;
        Token: JsonToken;
        TypeName: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Every error entry names a Bifrost Error Code (or, without one, the text it answers with), says when it is
        // returned and what to do about it.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('errors', Token);
            Assert.IsTrue(Token.AsArray().Count() > 0, TypeName + ' lists errors');
            foreach Entry in Token.AsArray() do begin
                if Entry.AsObject().Contains('code') then
                    Assert.IsTrue(ErrorCode.Names().Contains(TextOf(Entry.AsObject(), 'code')), TypeName + ' error code ' + TextOf(Entry.AsObject(), 'code') + ' is a Bifrost Error Code')
                else
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'error'), TypeName + ' an error without a code carries its text');
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'when'), TypeName + ' error says when');
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'fix'), TypeName + ' error says what to do');
            end;
        end;
    end;

    [Test]
    procedure EveryType_EffectMatchesTheDirection()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        MessageTypeInterface: Interface "Msg Interface ori";
        Direction: Enum "Msg Direction ori";
        Contract: JsonObject;
        Effect: JsonObject;
        Token: JsonToken;
        TypeName: Text;
        EffectName: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] A type that writes is Inbound and a type that reads is Outbound, except the two documented ones:
        // Orchestrator.Report.Get reads and inserts an empty preset (Both) and Orchestrator.Workspace.Preview commits a nested
        // dispatch but changes no business data (Outbound, #80).
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('effect', Token);
            Effect := Token.AsObject();
            EffectName := TextOf(Effect, 'effect');
            Assert.IsTrue(EffectName in ['read', 'write', 'irreversible'], TypeName + ' effect ' + EffectName + ' is read, write or irreversible');
            Assert.AreNotEqual('', TextOf(Effect, 'changes'), TypeName + ' says what it changes');
            Assert.IsTrue(Effect.Get('idempotent', Token), TypeName + ' states idempotent');
            Assert.IsTrue(Token.IsValue(), TypeName + ' idempotent is a value');
            MessageTypeInterface := TypeOf(Ordinal);
            Direction := MessageTypeInterface.GetMessageDirection();
            case true of
                TypeName = 'Orchestrator.Report.Get':
                    Assert.IsTrue(Direction = Direction::Both, TypeName + ' is Both');
                TypeName = 'Orchestrator.Workspace.Preview':
                    Assert.IsTrue(Direction = Direction::Outbound, TypeName + ' is Outbound');
                EffectName = 'read':
                    Assert.IsTrue(Direction = Direction::Outbound, TypeName + ' reads, so it is Outbound');
                else
                    Assert.IsTrue(Direction = Direction::Inbound, TypeName + ' writes, so it is Inbound');
            end;
        end;
    end;

    [Test]
    procedure EveryType_ExamplesAreRealRequestsAndAnswers()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Entry: JsonToken;
        Token: JsonToken;
        Request: JsonObject;
        TypeName: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Every type has at least one example whose request is a JSON object of its own type and whose answer is a JSON object.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('examples', Token);
            Assert.IsTrue(Token.AsArray().Count() > 0, TypeName + ' has an example');
            foreach Entry in Token.AsArray() do begin
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'title'), TypeName + ' example title');
                Assert.IsTrue(Entry.AsObject().Get('request', Token), TypeName + ' example request');
                Assert.IsTrue(Token.IsObject(), TypeName + ' example request is a JSON object');
                Request := Token.AsObject();
                Assert.AreEqual(TypeName, TextOf(Request, 'type'), TypeName + ' example request names its own type');
                Assert.IsTrue(Entry.AsObject().Get('response', Token), TypeName + ' example response');
                Assert.IsTrue(Token.IsObject(), TypeName + ' example response is a JSON object');
            end;
        end;
    end;

    [Test]
    procedure EveryType_RelatedAndWorkflowNameRealTypes()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Entry: JsonToken;
        Token: JsonToken;
        Steps: JsonToken;
        TypeName: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Related entries and workflow steps say why and name another type; Foundation refuses an unknown name when the
        // contract is built, so building every contract proves the names exist.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('related', Token);
            Assert.IsTrue(Token.AsArray().Count() > 0, TypeName + ' has a related type');
            foreach Entry in Token.AsArray() do begin
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'name'), TypeName + ' related name');
                Assert.AreNotEqual(TypeName, TextOf(Entry.AsObject(), 'name'), TypeName + ' is not related to itself');
                Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'useInsteadWhen'), TypeName + ' related reason');
            end;
            if Contract.Get('workflow', Token) then begin
                Token.AsObject().Get('steps', Steps);
                Assert.IsTrue(Steps.AsArray().Count() > 0, TypeName + ' workflow has steps');
                foreach Entry in Steps.AsArray() do begin
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'messageType'), TypeName + ' workflow step type');
                    Assert.AreNotEqual('', TextOf(Entry.AsObject(), 'purpose'), TypeName + ' workflow step purpose');
                end;
            end;
        end;
    end;

    [Test]
    procedure EveryType_HelpTextHasEnoughSubstanceAndNoAlObjectNames()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Token: JsonToken;
        TypeName: Text;
        ChapterText: Text;
        Chapter: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Overview and notes are real text, and no chapter other than errors and metering names an AL object (a name that ends in ori).
        // The errors chapter keeps the table names a caller types as tableName in Data.Records.Get.
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            Assert.IsTrue(ContractMgt.GetContract(TypeOf(Ordinal), Contract), TypeName + ' has a contract');
            Contract.Get('overview', Token);
            Assert.IsTrue(StrLen(Token.AsValue().AsText()) >= 100, TypeName + ' overview says what the type does and when to use it');
            Contract.Get('notes', Token);
            Assert.IsTrue(StrLen(Token.AsValue().AsText()) >= 40, TypeName + ' notes are real text');
            Contract.Remove('errors');
            Contract.Remove('metering');
            foreach Chapter in Contract.Keys() do begin
                Contract.Get(Chapter, Token);
                Token.WriteTo(ChapterText);
                Assert.IsFalse(NamesAnAlObject(ChapterText), TypeName + ' chapter ' + Chapter + ' names an AL object');
            end;
        end;
    end;

    [Test]
    procedure EveryType_DiscoveryTextsExistAndAreTranslated()
    var
        MessageTypeInterface: Interface "Msg Interface ori";
        Discovery: Interface "Msg Discovery ori";
        PreviousLanguage: Integer;
        TypeName: Text;
        Description: Text;
        Selection: Text;
        Keywords: Text;
        IcelandicDescription: Text;
        IcelandicSelection: Text;
        IcelandicKeywords: Text;
        Ordinal: Integer;
    begin
        // [SCENARIO] Every type has a description, a selection description of its own (not the description again) and at least
        // three keywords, and the three texts have an Icelandic translation.
        PreviousLanguage := GlobalLanguage();
        foreach Ordinal in OrchestratorTypes() do begin
            TypeName := NameOf(Ordinal);
            MessageTypeInterface := TypeOf(Ordinal);
            Discovery := TypeOf(Ordinal);
            GlobalLanguage(1033);
            Description := MessageTypeInterface.GetDescription();
            Selection := Discovery.GetSelectionDescription();
            Keywords := Discovery.GetKeywords();
            GlobalLanguage(1039);
            IcelandicDescription := MessageTypeInterface.GetDescription();
            IcelandicSelection := Discovery.GetSelectionDescription();
            IcelandicKeywords := Discovery.GetKeywords();
            GlobalLanguage(PreviousLanguage);

            Assert.AreNotEqual('', Description, TypeName + ' description');
            Assert.AreNotEqual('', Selection, TypeName + ' selection description');
            Assert.AreNotEqual(Description, Selection, TypeName + ' selection description separates it from its siblings');
            Assert.IsTrue(Keywords.Split(',').Count() >= 3, TypeName + ' has at least three keywords');
            Assert.AreNotEqual(Description, IcelandicDescription, TypeName + ' description has an is-IS target');
            Assert.AreNotEqual(Selection, IcelandicSelection, TypeName + ' selection description has an is-IS target');
            Assert.AreNotEqual(Keywords, IcelandicKeywords, TypeName + ' keywords have an is-IS target');
            Assert.AreNotEqual('', IcelandicDescription, TypeName + ' is-IS description');
            Assert.AreNotEqual('', IcelandicSelection, TypeName + ' is-IS selection description');
            Assert.AreNotEqual('', IcelandicKeywords, TypeName + ' is-IS keywords');
        end;
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure OrchestratorTypes() Ordinals: List of [Integer]
    var
        MessageType: Enum "Message Type ori";
        Names: List of [Text];
        Values: List of [Integer];
        Index: Integer;
    begin
        Names := MessageType.Names();
        Values := MessageType.Ordinals();
        for Index := 1 to Names.Count() do
            if Names.Get(Index).StartsWith('Orchestrator.') or (Names.Get(Index) = 'Help.Orchestrator.Get') then
                Ordinals.Add(Values.Get(Index));
    end;

    local procedure TypeOf(Ordinal: Integer): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori".FromInteger(Ordinal));
    end;

    local procedure NameOf(Ordinal: Integer): Text
    var
        MessageType: Enum "Message Type ori";
    begin
        exit(MessageType.Names().Get(MessageType.Ordinals().IndexOf(Ordinal)));
    end;

    /// <summary>The types whose code reads Argument.Subject (as a GUID, an outbox id or a playbook code).</summary>
    local procedure SubjectTypes() Names: List of [Text]
    begin
        Names.AddRange('Orchestrator.Entry.Run', 'Orchestrator.Entry.Restart', 'Orchestrator.Entry.Register', 'Orchestrator.Entry.Schedule',
            'Orchestrator.JobQueueEntry.Restart', 'Orchestrator.JobQueueEntry.RestartIfNeeded',
            'Orchestrator.Playbook.Run', 'Orchestrator.Playbook.Schedule', 'Orchestrator.Playbook.Enqueue', 'Orchestrator.Playbook.Verify',
            'Orchestrator.Email.Send');
    end;

    local procedure TypeReadsNoParameters(TypeName: Text): Boolean
    begin
        exit(TypeName in ['Orchestrator.Status.Get', 'Orchestrator.Status.Restart', 'Orchestrator.Status.RestartIfNeeded', 'Help.Orchestrator.Get']);
    end;

    local procedure TextOf(Entry: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Entry.Get(PropertyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
    end;

    /// <summary>True when the text holds a word ori that ends an AL object name, such as "Scheduled Entry ori".</summary>
    local procedure NamesAnAlObject(Value: Text): Boolean
    var
        Remaining: Text;
        Following: Text;
        Position: Integer;
    begin
        Remaining := Value;
        repeat
            Position := StrPos(Remaining, ' ori');
            if Position = 0 then
                exit(false);
            if StrLen(Remaining) = Position + 3 then
                exit(true);
            Following := CopyStr(Remaining, Position + 4, 1);
            if not IsWordCharacter(Following) then
                exit(true);
            Remaining := CopyStr(Remaining, Position + 4);
        until false;
    end;

    local procedure IsWordCharacter(Character: Text): Boolean
    begin
        exit((UpperCase(Character) <> LowerCase(Character)) or (StrPos('0123456789', Character) > 0));
    end;
}
