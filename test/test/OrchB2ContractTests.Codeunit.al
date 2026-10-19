namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Contract and discovery conformance tests for Batch 2 message types.
/// </summary>
codeunit 96453 "Orch B2 Contract Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch2MessagesHaveContractChaptersAndDiscovery()
    begin
        AssertContract("Message Type ori"::"Orchestrator.Report.List", 'Orchestrator.Report.List');
        AssertContract("Message Type ori"::"Orchestrator.Report.Get", 'Orchestrator.Report.Get');
        AssertContract("Message Type ori"::"Orchestrator.Report.SaveAs", 'Orchestrator.Report.SaveAs');
        AssertContract("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run');
        AssertContract("Message Type ori"::"Orchestrator.Workspace.Preview", 'Orchestrator.Workspace.Preview');
        AssertContract("Message Type ori"::"Orchestrator.ReportLayout.Set", 'Orchestrator.ReportLayout.Set');
    end;

    [Test]
    procedure CommittingTypesDeclareIrreversible()
    begin
        // [SCENARIO #60] Report.Run runs caller-named batch reports that commit, so it declares irreversible
        AssertEffect("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run', 'irreversible', true);
        // [SCENARIO #80] Preview seeds _who through a nested Help.WhoAmI.Get dispatch that commits
        AssertEffect("Message Type ori"::"Orchestrator.Workspace.Preview", 'Orchestrator.Workspace.Preview', 'irreversible', true);
    end;

    /// <summary>Preview names the nested committed dispatch and keeps its read direction (#80).</summary>
    [Test]
    procedure PreviewDisclosesNestedCommit()
    var
        Contract: Interface "Msg Contract ori";
        MessageTypeInterface: Interface "Msg Interface ori";
        Effect: JsonObject;
        Token: JsonToken;
        Notes: Text;
    begin
        // [GIVEN] The Workspace.Preview contract
        Contract := "Message Type ori"::"Orchestrator.Workspace.Preview";
        // [WHEN] Its effect and notes are read
        Assert.IsTrue(Contract.GetEffect(Effect), 'Preview declares an effect');
        Assert.IsTrue(Contract.GetNotes(Notes), 'Preview has notes');
        // [THEN] The changes text names the nested dispatch and its commit
        Assert.IsTrue(Effect.Get('changes', Token), 'changes is present');
        Assert.IsTrue(Token.AsValue().AsText().Contains('Help.WhoAmI.Get'), 'changes names the nested dispatch');
        Assert.IsTrue(Token.AsValue().AsText().Contains('commits'), 'changes discloses the commit');
        Assert.IsTrue(Notes.Contains('outer transaction'), 'notes explain why it cannot roll back');
        // [THEN] No business data changes, so the roster direction stays Outbound
        MessageTypeInterface := "Message Type ori"::"Orchestrator.Workspace.Preview";
        Assert.AreEqual("Msg Direction ori"::Outbound, MessageTypeInterface.GetMessageDirection(), 'Preview direction');
    end;

    [Test]
    procedure NonCommittingTypesKeepTheirEffect()
    begin
        // [SCENARIO #60] ReportLayout.Set stays write; the reads stay read
        AssertEffect("Message Type ori"::"Orchestrator.ReportLayout.Set", 'Orchestrator.ReportLayout.Set', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.List", 'Orchestrator.Report.List', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.Get", 'Orchestrator.Report.Get', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.SaveAs", 'Orchestrator.Report.SaveAs', 'read', false);
    end;

    /// <summary>Preserves every field and position of the main choice entry.</summary>
    [Test]
    procedure Scenario_AC05_Format_KeepsMainContract()
    begin
        // Story #68, AC05 | Time: independent of Today/WorkDate | Risk: #71 shared Parts helper.
        // [GIVEN] The choice entry captured from main 6413d705.
        // [WHEN] Its message contract is generated.
        // [THEN] Every entry field, its position and the chapter size remain unchanged.
        AssertChoiceParameter("Message Type ori"::"Orchestrator.Report.SaveAs", 1, 4,
            '{"name":"format","type":"string","required":false,"description":"Output format. Case-insensitive.","default":"PDF","allowed":["PDF","Excel","Word","XML"]}');
    end;

    /// <summary>Preserves every field and position of the main choice entry.</summary>
    [Test]
    procedure Scenario_AC05_LayoutFormat_KeepsMainContract()
    begin
        // Story #68, AC05 | Time: independent of Today/WorkDate | Risk: #71 shared Parts helper.
        // [GIVEN] The choice entry captured from main 6413d705.
        // [WHEN] Its message contract is generated.
        // [THEN] Every entry field, its position and the chapter size remain unchanged.
        AssertChoiceParameter("Message Type ori"::"Orchestrator.ReportLayout.Set", 2, 6,
            '{"name":"layoutFormat","type":"string","required":true,"description":"Layout format. Case-insensitive; RDL is stored as RDLC.","allowed":["Word","Excel","RDLC","RDL"]}');
    end;

    local procedure AssertChoiceParameter(MessageType: Enum "Message Type ori"; Index: Integer; Count: Integer; ExpectedJson: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Chapter: JsonToken;
        Entry: JsonToken;
        Expected: JsonToken;
        ActualText: Text;
        ExpectedText: Text;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'Contract exists');
        Assert.IsTrue(Contract.Get('parameters', Chapter), 'Parameters chapter exists');
        Assert.AreEqual(Count, Chapter.AsArray().Count(), 'Parameter count matches main');
        Assert.IsTrue(Chapter.AsArray().Get(Index, Entry), 'Entry position matches main');
        Assert.IsTrue(Expected.ReadFrom(ExpectedJson), 'Valid captured main fixture');
        Entry.WriteTo(ActualText);
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, ActualText, 'Choice entry matches main byte for byte');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Workspace.Preview.</summary>
    [Test]
    procedure Scenario_AC04_WorkspacePreview_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Workspace.Preview",
            '[{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"initialRequest is a JSON array.","fix":"Send an object, a string that holds one, or leave initialRequest out."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Report.Get.</summary>
    [Test]
    procedure Scenario_AC04_ReportGet_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Report.Get",
            '[{"code":"BusinessCentralError","error":"Request must include \"reportId\".","when":"data.reportId is missing.","fix":"Send the report object ID in data.reportId."},{"code":"BusinessCentralError","error":"Report <reportId> not found.","when":"No report with that ID exists in Report Metadata.","fix":"Find the ID with Orchestrator.Report.List."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"data.reportId is not a whole number.","fix":"Send reportId as an integer."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Report.List.</summary>
    [Test]
    procedure Scenario_AC04_ReportList_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Report.List",
            '[{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"processingOnly is not a boolean.","fix":"Send true, false, or omit processingOnly."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Report.Run.</summary>
    [Test]
    procedure Scenario_AC04_ReportRun_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Report.Run",
            '[{"code":"BusinessCentralError","error":"Request must include \"reportId\".","when":"data.reportId is missing.","fix":"Send the report object ID in data.reportId."},{"code":"BusinessCentralError","error":"Report <reportId> not found.","when":"No report with that ID exists in Report Metadata.","fix":"Find the ID with Orchestrator.Report.List."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"data.reportId is not a whole number.","fix":"Send reportId as an integer."},{"code":"BusinessCentralError","error":"Report <reportId> produces output and cannot be run as a batch job. Use Orchestrator.Report.SaveAs instead.","when":"The report is not processing-only.","fix":"Use Orchestrator.Report.SaveAs for reports that produce output."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"tableView is not a valid view for the report''s data item table.","fix":"Fix the view or leave it out."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Report.SaveAs.</summary>
    [Test]
    procedure Scenario_AC04_ReportSaveAs_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Report.SaveAs",
            '[{"code":"BusinessCentralError","error":"Request must include \"reportId\".","when":"data.reportId is missing.","fix":"Send the report object ID in data.reportId."},{"code":"BusinessCentralError","error":"Report <reportId> not found.","when":"No report with that ID exists in Report Metadata.","fix":"Find the ID with Orchestrator.Report.List."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"data.reportId is not a whole number.","fix":"Send reportId as an integer."},{"code":"BusinessCentralError","error":"Report <reportId> is processing-only and cannot be saved.","when":"The report is a batch job that produces no document.","fix":"Use Orchestrator.Report.Run for it."},{"code":"BusinessCentralError","error":"Unsupported format \"<FORMAT>\". Use PDF, Excel, Word, or XML.","when":"data.format is not one of the four formats.","fix":"Send PDF, Excel, Word or XML, or leave format out."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The report fails while rendering, or tableView is not a valid view.","fix":"Read the text; check the request page XML and the view."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.ReportLayout.Set.</summary>
    [Test]
    procedure Scenario_AC04_ReportLayoutSet_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.ReportLayout.Set",
            '[{"code":"BusinessCentralError","error":"Request must include \"<key>\".","when":"reportId, name, layoutFormat or layoutBase64 is missing.","fix":"Send all four keys."},{"code":"BusinessCentralError","error":"Layout format <layoutFormat> is not valid for report <reportId>.","when":"layoutFormat is not Word, Excel, RDLC or RDL.","fix":"Send one of those formats."},{"code":"BusinessCentralError","error":"Report <reportId> not found.","when":"No report with that ID exists in Report Metadata.","fix":"Find the ID with Orchestrator.Report.List."},{"code":"BusinessCentralError","error":"Request must include non-empty \"layoutBase64\".","when":"layoutBase64 is empty.","fix":"Send the layout file as base64."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"layoutBase64 is not valid base64, or the layout import fails.","fix":"Send the file content base64-encoded, in the format named by layoutFormat."}]');
    end;

    local procedure AssertMainErrors(MessageType: Enum "Message Type ori"; ExpectedJson: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Actual: JsonToken;
        Expected: JsonToken;
        ActualText: Text;
        ExpectedText: Text;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'Contract exists');
        Assert.IsTrue(Contract.Get('errors', Actual), 'Errors chapter exists');
        Assert.IsTrue(Expected.ReadFrom(ExpectedJson), 'Valid captured main fixture');
        Actual.WriteTo(ActualText);
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, ActualText, 'Errors chapter matches main byte for byte');
    end;

    local procedure AssertContract(MessageType: Enum "Message Type ori"; Name: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Discovery: Interface "Msg Discovery ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Assert.IsTrue(Contract.Contains('envelope'), Name + ' envelope');
        Assert.IsTrue(Contract.Contains('response'), Name + ' response');
        Assert.IsTrue(Contract.Contains('errors'), Name + ' errors');
        Assert.IsTrue(Contract.Get('effect', EffectToken), Name + ' effect');
        Assert.IsTrue(EffectToken.AsObject().Contains('effect'), Name + ' effect kind');
        Discovery := MessageType;
        Assert.AreNotEqual('', Discovery.GetKeywords(), Name + ' keywords');
        Assert.AreNotEqual('', Discovery.GetSelectionDescription(), Name + ' selection');
    end;

    local procedure AssertEffect(MessageType: Enum "Message Type ori"; Name: Text; ExpectedEffect: Text; NamesCommit: Boolean)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
        ValueToken: JsonToken;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Contract.Get('effect', EffectToken);
        EffectToken.AsObject().Get('effect', ValueToken);
        Assert.AreEqual(ExpectedEffect, ValueToken.AsValue().AsText(), Name + ' effect');
        if NamesCommit then begin
            EffectToken.AsObject().Get('changes', ValueToken);
            Assert.IsTrue(ValueToken.AsValue().AsText().Contains('commit'), Name + ' changes names the commit');
            Assert.IsTrue(ValueToken.AsValue().AsText().Contains('Omit Commit guard'), Name + ' changes names the Omit Commit guard');
        end;
    end;
}
