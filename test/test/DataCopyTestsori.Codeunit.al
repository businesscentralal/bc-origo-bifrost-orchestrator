namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.IO;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// #262 Data Copy (port of Tools for Power Users): field auto-fill and auto-match, Copy Table Data through Foundation's
/// guarded Data.Records.Set (parent and child mapping, filter, data template, Swap Amount Sign, insert, modify only on
/// change, no change), the guard refusal, and the job-queue copy of one or all non-manual mappings.
/// </summary>
codeunit 96476 "Data Copy Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>AC05: setting the tables creates one line per normal field and matches the destination by number and type.</summary>
    [Test]
    procedure AC05_SelectAllFieldsAutoFillsAndMatches()
    var
        Mapping: Record "Copy Table Mapping ori";
        FieldMapping: Record "Copy Field Mapping ori";
        FieldNo: Integer;
    begin
        ResetFixtures();
        // [GIVEN] A mapping between two tables with the same field numbers and types
        CreateMapping(Mapping, Database::"Test Copy Parent ori", Database::"Test Copy Child ori", 0, false);
        // [THEN] Every normal source field has a line, matched to the same destination field
        FieldMapping.SetRange("Copy Table Mapping ID", Mapping.ID);
        Assert.AreEqual(3, FieldMapping.Count(), 'One line per normal, enabled source field');
        for FieldNo := 1 to 3 do begin
            FieldMapping.Get(Mapping.ID, FieldNo);
            Assert.AreEqual(FieldNo, FieldMapping."Destination Field ID", 'Matched by number and compatible type');
        end;
        FieldMapping.Get(Mapping.ID, 1);
        FieldMapping.CalcFields("Is Part Of Primary Key");
        Assert.IsTrue(FieldMapping."Is Part Of Primary Key", 'Code is the destination primary key');
        DeleteMapping(Mapping);
    end;

    /// <summary>AC05 edge: a destination field with the same number but an incompatible type is not matched.</summary>
    [Test]
    procedure AC05_IncompatibleTypeIsNotMatched()
    var
        Mapping: Record "Copy Table Mapping ori";
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        ResetFixtures();
        // [GIVEN] Destination fields 1..3 are Guid/Integer/Integer, source fields are Code/Text/Decimal
        CreateMapping(Mapping, Database::"Test Copy Parent ori", Database::"Copy Table Mapping ori", 0, false);
        // [THEN] No destination field is matched
        FieldMapping.SetRange("Copy Table Mapping ID", Mapping.ID);
        Assert.AreEqual(3, FieldMapping.Count(), 'Lines are still created');
        FieldMapping.SetFilter("Destination Field ID", '<>0');
        Assert.IsTrue(FieldMapping.IsEmpty(), 'Incompatible types stay unmatched');
        DeleteMapping(Mapping);
    end;

    /// <summary>AC05 invalid input: a mapping cannot be its own parent.</summary>
    [Test]
    procedure AC05_ParentEqualToSourceIsRefused()
    var
        Mapping: Record "Copy Table Mapping ori";
    begin
        ResetFixtures();
        CreateMapping(Mapping, Database::"Test Copy Parent ori", Database::"Test Copy Child ori", 0, false);
        asserterror Mapping.Validate("Parent Source Table ID", Database::"Test Copy Parent ori");
        Assert.ExpectedError('can not be the same table Id');
        DeleteMapping(Mapping);
    end;

    /// <summary>AC03: parent and child mapping with filter, data template and Swap Amount Sign; insert, then modify only on change.</summary>
    [Test]
    procedure AC03_ParentChildCopyInsertModifyNoChange()
    var
        ParentMapping: Record "Copy Table Mapping ori";
        ChildMapping: Record "Copy Table Mapping ori";
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
        Outside: Record "Test Copy Parent ori";
        TemplateCode: Code[10];
        RuleCode: Code[20];
        Prefix: Code[10];
        ModificationsBefore: Integer;
        UntouchedBefore: Integer;
        RowNo: Integer;
    begin
        ResetFixtures();
        // [GIVEN] Change-log coverage for both owned scratch tables; the production write guard stays on
        AddCoverage(Database::"Test Copy Parent ori");
        AddCoverage(Database::"Test Copy Child ori");
        Prefix := NewPrefix();
        for RowNo := 1 to 3 do
            InsertParent(Prefix + Format(RowNo, 0, 9), 'Source', 100 * RowNo);
        InsertParent('Y' + Prefix, 'Outside the filter', 1);
        TemplateCode := CreateTemplate(Database::"Test Copy Child ori", 2, 'TPL');
        RuleCode := CreateSwapRule();

        // [GIVEN] Parent mapping Parent -> Child: filter, template for Description, Swap Amount Sign on Amount
        CreateMapping(ParentMapping, Database::"Test Copy Parent ori", Database::"Test Copy Child ori", 0, false);
        SetPrefixFilter(ParentMapping, Prefix);
        ParentMapping."Data Template Code" := TemplateCode;
        ParentMapping.Modify(true);
        ClearDestination(ParentMapping, 2);
        SetRule(ParentMapping, 3, RuleCode);
        // [GIVEN] Child mapping Child -> Parent copies the Description back (Amount not mapped)
        CreateMapping(ChildMapping, Database::"Test Copy Child ori", Database::"Test Copy Parent ori", Database::"Test Copy Parent ori", false);
        SetPrefixFilter(ChildMapping, Prefix);
        ClearDestination(ChildMapping, 3);
        ParentMapping.Find();
        ChildMapping.Find();
        Assert.AreEqual(1, ChildMapping.Indentation, 'The child mapping is indented under its parent');
        Assert.AreEqual('Strong', ParentMapping.GetStyleText(), 'The root mapping is shown in bold');
        Commit();

        // [WHEN] The non-manual mappings are copied (parents before children)
        RunCopyTask();

        // [THEN] Insert: template value and swapped sign; the filter kept the outside row out
        for RowNo := 1 to 3 do begin
            Assert.IsTrue(Child.Get(Prefix + Format(RowNo, 0, 9)), 'Inserted through Data.Records.Set');
            Assert.AreEqual('TPL', Child.Description, 'Data template applied on insert');
            Assert.AreEqual(-100 * RowNo, Child.Amount, 'Swap Amount Sign applied');
            Parent.Get(Prefix + Format(RowNo, 0, 9));
            Assert.AreEqual('TPL', Parent.Description, 'Child mapping modified the changed Description');
            Assert.AreEqual(100 * RowNo, Parent.Amount, 'Unmapped Amount untouched by the child mapping');
        end;
        Assert.IsFalse(Child.Get('Y' + Prefix), 'Source filter excludes the outside row');
        Outside.Get('Y' + Prefix);
        ParentMapping.Find();
        ChildMapping.Find();
        Assert.AreNotEqual(0DT, ParentMapping."Last Copy Time", 'Parent Last Copy Time stamped');
        Assert.AreNotEqual(0DT, ChildMapping."Last Copy Time", 'Child Last Copy Time stamped');

        // [WHEN] Copied again without source changes
        ModificationsBefore := CountModifications(Prefix + '1');
        UntouchedBefore := CountModifications(Prefix + '2');
        ParentMapping.CopyTableData(true);
        // [THEN] No change: nothing is written (the change log records every guarded modification)
        Assert.AreEqual(ModificationsBefore, CountModifications(Prefix + '1'), 'No change: no write');
        Parent.Get(Prefix + '1');
        Parent.Amount := 555;
        Parent.Modify(true);
        Commit();

        // [WHEN] One source amount changed
        ParentMapping.CopyTableData(true);

        // [THEN] Only the changed record is modified
        Child.Get(Prefix + '1');
        Assert.AreEqual(-555, Child.Amount, 'Modified value copied with swapped sign');
        Assert.IsTrue(CountModifications(Prefix + '1') > ModificationsBefore, 'Changed record written through the guarded path');
        Assert.AreEqual('TPL', Child.Description, 'Template is not re-applied on modify');
        Assert.AreEqual(UntouchedBefore, CountModifications(Prefix + '2'), 'Unchanged record not written');

        DeleteMapping(ChildMapping);
        DeleteMapping(ParentMapping);
        CleanupRows(Prefix);
        DeleteTemplate(TemplateCode);
        DeleteRule(RuleCode);
        RemoveCoverage(Database::"Test Copy Parent ori");
        RemoveCoverage(Database::"Test Copy Child ori");
        Commit();
    end;

    /// <summary>AC04: a copy into a destination the change log write guard does not cover is refused by Foundation; nothing is written.</summary>
    [Test]
    procedure AC04_GuardedDestinationIsRefused()
    var
        Mapping: Record "Copy Table Mapping ori";
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
        Coverage: Record "Change Log Setup (Table)";
        Prefix: Code[10];
    begin
        ResetFixtures();
        // [GIVEN] The destination table has no change-log coverage; the production guard is on
        Assert.IsFalse(Coverage.Get(Database::"Test Copy Parent ori"), 'Negative fixture destination has no coverage');
        Prefix := NewPrefix();
        Child.Init();
        Child.Code := Prefix + '1';
        Child.Description := 'Must not be copied';
        Child.Insert(true);
        CreateMapping(Mapping, Database::"Test Copy Child ori", Database::"Test Copy Parent ori", 0, true);
        SetPrefixFilter(Mapping, Prefix);
        Commit();

        // [WHEN] Copy Table Data runs
        asserterror Mapping.CopyTableData(true);

        // [THEN] Foundation's own refusal stops the copy and the destination stays empty
        Assert.ExpectedError('BlockedByWriteGuard');
        Assert.IsFalse(Parent.Get(Prefix + '1'), 'Refused destination remains absent');
        Mapping.Find();
        Assert.AreEqual(0DT, Mapping."Last Copy Time", 'A refused copy is not stamped');
        DeleteMapping(Mapping);
        Child.Get(Prefix + '1');
        Child.Delete(true);
        Commit();
    end;

    /// <summary>AC06: the job queue copies the mapping in Record ID to Process, or every non-manual mapping.</summary>
    [Test]
    procedure AC06_JobQueueCopiesOneOrAllNonManual()
    var
        ManualMapping: Record "Copy Table Mapping ori";
        Child: Record "Test Copy Child ori";
        JobQueueEntry: Record "Job Queue Entry";
        Prefix: Code[10];
    begin
        ResetFixtures();
        // [GIVEN] One manual mapping Parent -> Child with coverage
        AddCoverage(Database::"Test Copy Child ori");
        Prefix := NewPrefix();
        InsertParent(Prefix + '1', 'Job', 7);
        CreateMapping(ManualMapping, Database::"Test Copy Parent ori", Database::"Test Copy Child ori", 0, true);
        SetPrefixFilter(ManualMapping, Prefix);
        Commit();

        // [WHEN] The job runs for all mappings
        JobQueueEntry.Init();
        Codeunit.Run(Codeunit::"Copy Table Job Queue ori", JobQueueEntry);
        // [THEN] The manual mapping is skipped
        Assert.IsFalse(Child.Get(Prefix + '1'), 'Manual Copy mappings are not part of the all-mappings job');

        // [WHEN] The job runs for that one mapping
        JobQueueEntry."Record ID to Process" := ManualMapping.RecordId();
        Codeunit.Run(Codeunit::"Copy Table Job Queue ori", JobQueueEntry);
        // [THEN] It is copied
        Assert.IsTrue(Child.Get(Prefix + '1'), 'The job copies the mapping in Record ID to Process');
        Assert.AreEqual(7, Child.Amount, 'Mapped value copied');

        DeleteMapping(ManualMapping);
        CleanupRows(Prefix);
        RemoveCoverage(Database::"Test Copy Child ori");
        Commit();
    end;

    /// <summary>Swap Amount Sign negates invariant and local amounts and keeps text that is not a number.</summary>
    [Test]
    procedure SwapAmountSignTransformsText()
    var
        TransformationRule: Record "Transformation Rule";
        RuleCode: Code[20];
    begin
        RuleCode := CreateSwapRule();
        TransformationRule.Get(RuleCode);
        Assert.AreEqual('-12.5', TransformationRule.TransformText('12.5'), 'Positive becomes negative');
        Assert.AreEqual('100', TransformationRule.TransformText('-100'), 'Negative becomes positive');
        Assert.AreEqual('abc', TransformationRule.TransformText('abc'), 'Not a number is kept');
        Assert.AreEqual('', TransformationRule.TransformText(''), 'Empty stays empty');
        DeleteRule(RuleCode);
    end;

    local procedure CountModifications(Code: Code[20]): Integer
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", Database::"Test Copy Child ori");
        ChangeLogEntry.SetRange("Primary Key Field 1 Value", Code);
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Modification);
        exit(ChangeLogEntry.Count());
    end;

    /// <summary>Removes mappings and coverage that an earlier failed test in this codeunit may have left behind.</summary>
    local procedure ResetFixtures()
    var
        Mapping: Record "Copy Table Mapping ori";
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        Mapping.SetFilter("Source Table ID", '%1|%2', Database::"Test Copy Parent ori", Database::"Test Copy Child ori");
        if Mapping.FindSet() then
            repeat
                FieldMapping.SetRange("Copy Table Mapping ID", Mapping.ID);
                FieldMapping.DeleteAll(false);
            until Mapping.Next() = 0;
        Mapping.DeleteAll(false);
        RemoveCoverage(Database::"Test Copy Parent ori");
        RemoveCoverage(Database::"Test Copy Child ori");
    end;

    local procedure RunCopyTask()
    var
        CopyTask: Codeunit "Copy Table Task ori";
    begin
        CopyTask.StartDataTransfer();
    end;

    local procedure NewPrefix(): Code[10]
    begin
        exit(CopyStr('D' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 8) + '-');
    end;

    local procedure InsertParent(Code: Code[20]; Description: Text[100]; Amount: Decimal)
    var
        Parent: Record "Test Copy Parent ori";
    begin
        Parent.Init();
        Parent.Code := Code;
        Parent.Description := Description;
        Parent.Amount := Amount;
        Parent.Insert(true);
    end;

    local procedure CreateMapping(var Mapping: Record "Copy Table Mapping ori"; SourceTableId: Integer; DestinationTableId: Integer; ParentSourceTableId: Integer; ManualCopy: Boolean)
    begin
        Clear(Mapping);
        Mapping.Init();
        Mapping.ID := CreateGuid();
        Mapping.Validate("Source Table ID", SourceTableId);
        Mapping.Validate("Destination Table ID", DestinationTableId);
        Mapping."Parent Source Table ID" := ParentSourceTableId;
        Mapping."Manual Copy" := ManualCopy;
        Mapping.Insert(true);
        Mapping.SelectAllFields();
    end;

    local procedure SetPrefixFilter(var Mapping: Record "Copy Table Mapping ori"; Prefix: Code[10])
    var
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
    begin
        if Mapping."Source Table ID" = Database::"Test Copy Parent ori" then begin
            Parent.SetFilter(Code, '%1', Prefix + '*');
            Mapping.SetViewAsFilter(Parent.GetView(false));
        end else begin
            Child.SetFilter(Code, '%1', Prefix + '*');
            Mapping.SetViewAsFilter(Child.GetView(false));
        end;
        Mapping.Modify(true);
        Assert.AreNotEqual('', Mapping.GetFiltersAsTextDisplay(), 'The saved filter is readable');
    end;

    local procedure ClearDestination(Mapping: Record "Copy Table Mapping ori"; SourceFieldNo: Integer)
    var
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        FieldMapping.Get(Mapping.ID, SourceFieldNo);
        FieldMapping."Destination Field ID" := 0;
        FieldMapping.Modify(true);
    end;

    local procedure SetRule(Mapping: Record "Copy Table Mapping ori"; SourceFieldNo: Integer; RuleCode: Code[20])
    var
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        FieldMapping.Get(Mapping.ID, SourceFieldNo);
        FieldMapping.Validate("Transformation Rule", RuleCode);
        FieldMapping.Modify(true);
    end;

    local procedure CreateSwapRule(): Code[20]
    var
        TransformationRule: Record "Transformation Rule";
    begin
        TransformationRule.Init();
        TransformationRule.Code := CopyStr('SWAP' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(TransformationRule.Code));
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Swap Amount Sign ori";
        TransformationRule.Insert(false);
        exit(TransformationRule.Code);
    end;

    local procedure DeleteRule(RuleCode: Code[20])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if TransformationRule.Get(RuleCode) then
            TransformationRule.Delete(false);
    end;

    local procedure CreateTemplate(TableId: Integer; FieldId: Integer; DefaultValue: Text[250]): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateHeader.Init();
        ConfigTemplateHeader.Code := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(ConfigTemplateHeader.Code));
        ConfigTemplateHeader."Table ID" := TableId;
        ConfigTemplateHeader.Enabled := true;
        ConfigTemplateHeader.Insert(false);
        ConfigTemplateLine.Init();
        ConfigTemplateLine."Data Template Code" := ConfigTemplateHeader.Code;
        ConfigTemplateLine."Line No." := 10000;
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::Field;
        ConfigTemplateLine."Table ID" := TableId;
        ConfigTemplateLine."Field ID" := FieldId;
        ConfigTemplateLine."Default Value" := DefaultValue;
        ConfigTemplateLine.Insert(false);
        exit(ConfigTemplateHeader.Code);
    end;

    local procedure DeleteTemplate(TemplateCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", TemplateCode);
        ConfigTemplateLine.DeleteAll(false);
        if ConfigTemplateHeader.Get(TemplateCode) then
            ConfigTemplateHeader.Delete(false);
    end;

    local procedure DeleteMapping(var Mapping: Record "Copy Table Mapping ori")
    begin
        if Mapping.Find() then
            Mapping.Delete(true);
    end;

    local procedure CleanupRows(Prefix: Code[10])
    var
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
    begin
        Parent.SetFilter(Code, '%1|%2', Prefix + '*', 'Y' + Prefix);
        Parent.DeleteAll(true);
        Child.SetFilter(Code, '%1', Prefix + '*');
        Child.DeleteAll(true);
    end;

    local procedure AddCoverage(TableId: Integer)
    var
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogTable: Record "Change Log Setup (Table)";
    begin
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(true);
        end;
        if not ChangeLogSetup."Change Log Activated" then begin
            ChangeLogSetup."Change Log Activated" := true;
            ChangeLogSetup.Modify(true);
            WasActivatedByTest := true;
        end;
        if ChangeLogTable.Get(TableId) then
            exit;
        ChangeLogTable.Init();
        ChangeLogTable."Table No." := TableId;
        ChangeLogTable."Log Insertion" := ChangeLogTable."Log Insertion"::"All Fields";
        ChangeLogTable."Log Modification" := ChangeLogTable."Log Modification"::"All Fields";
        ChangeLogTable.Insert(true);
    end;

    local procedure RemoveCoverage(TableId: Integer)
    var
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogTable: Record "Change Log Setup (Table)";
    begin
        if ChangeLogTable.Get(TableId) then
            ChangeLogTable.Delete(true);
        if WasActivatedByTest and ChangeLogSetup.Get() then begin
            ChangeLogTable.Reset();
            if ChangeLogTable.IsEmpty() then begin
                ChangeLogSetup."Change Log Activated" := false;
                ChangeLogSetup.Modify(true);
                WasActivatedByTest := false;
            end;
        end;
    end;

    var
        WasActivatedByTest: Boolean;
}
