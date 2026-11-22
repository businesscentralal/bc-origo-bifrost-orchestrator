namespace Origo.Bifrost.Orchestrator;

using System.Automation;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Stores the source-to-destination table mapping used by Copy Table Data (port of Tools for Power Users
/// "Copy Table Mapping"). Each record defines one table pair, an optional source filter, a data template and its
/// place in the parent/child hierarchy.
/// </summary>
table 10035632 "Copy Table Mapping ori"
{
    Caption = 'Copy Table Mapping', Comment = 'is-IS=Afrita töflu - vörpun';
    DataClassification = SystemMetadata;
    Access = Public;
    LookupPageId = "Copy Tables Mapping ori";
    DrillDownPageId = "Copy Tables Mapping ori";

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID', Comment = 'is-IS=Kenni';
            ToolTip = 'Specifies the unique identifier of the table mapping.', Comment = 'is-IS=Tilgreinir einkvæmt kenni töfluvörpunarinnar.';
        }
        field(2; "Source Table ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Source Table ID', Comment = 'is-IS=Töflukenni upprunastaðs';
            ToolTip = 'Specifies the value of the Source Table ID field.', Comment = 'is-IS=Tilgreinir gildi reitsins töflukenni upprunastaðar.';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if HasChildren() then
                    Error(DeleteWithChildrenErr);
                CalcFields("Source Table Caption");
            end;
        }
        field(3; "Destination Table ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Destination Table ID', Comment = 'is-IS=Töflukenni viðtökustaðs';
            ToolTip = 'Specifies the value of the Destination Table ID field.', Comment = 'is-IS=Tilgreinir gildi reitsins töflukenni viðtökustaðar.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                CalcFields("Destination Table Caption");
            end;
        }
        field(4; "Source Table Filter"; Blob)
        {
            Caption = 'Source Table Filter', Comment = 'is-IS=Töfluafmörkun upprunastaðs';
        }
        field(5; "Source Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table ID")));
            Caption = 'Source Table Caption', Comment = 'is-IS=Texti upprunastaðs';
            ToolTip = 'Specifies the value of the Source Table Caption field.', Comment = 'is-IS=Tilgreinir gildi reitsins töflutexti upprunastaðar.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Destination Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Destination Table ID")));
            Caption = 'Destination Table Caption', Comment = 'is-IS=Texti viðtökustaðs';
            ToolTip = 'Specifies the value of the Destination Table Caption field.', Comment = 'is-IS=Tilgreinir gildi reitsins töflutexti viðtökustaðar.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Last Copy Time"; DateTime)
        {
            Caption = 'Last Copy Time', Comment = 'is-IS=Síðast afritað';
            ToolTip = 'Specifies the value of the Last Copy Time field.', Comment = 'is-IS=Tilgreinir gildi reitsins síðast afritað.';
        }
        field(8; "Data Template Code"; Code[10])
        {
            Caption = 'Data Template Code', Comment = 'is-IS=Gagnasnið mátskóti';
            ToolTip = 'Specifies the value of the Data Template Code field.', Comment = 'is-IS=Tilgreinir gildi reitsins kóti gagnasniðmáts.';
            TableRelation = "Config. Template Header" where("Table ID" = field("Destination Table ID"), Enabled = const(true));

            trigger OnLookup()
            var
                ConfigTemplateHeader: Record "Config. Template Header";
            begin
                ConfigTemplateHeader.SetRange("Table ID", "Destination Table ID");
                ConfigTemplateHeader.SetRange(Enabled, true);
                if Page.RunModal(Page::"Copy Table Templates ori", ConfigTemplateHeader) = Action::LookupOK then
                    Validate("Data Template Code", ConfigTemplateHeader.Code);
            end;
        }
        field(9; "Manual Copy"; Boolean)
        {
            Caption = 'Manual Copy', Comment = 'is-IS=Afrita handvirkt';
            ToolTip = 'Specifies the value of the Manual Copy field.', Comment = 'is-IS=Tilgreinir gildi reitsins handvirkt afritað.';
            InitValue = true;
        }
        field(10; "Copy Method"; Enum "Copy Table Data Transfer ori")
        {
            Caption = 'Copy Method', Comment = 'is-IS=Afritunaraðferð';
            ToolTip = 'Specifies the value of the Copy Method field.', Comment = 'is-IS=Tilgreinir gildi reitsins afritunaraðferð.';
        }
        field(12; "Parent Source Table ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Parent Source Table ID', Comment = 'is-IS=Kenni upprunastaðs foreldris';
            ToolTip = 'Specifies the value of the Parent Source Table ID field.', Comment = 'is-IS=Tilgreinir gildi reitsins töflukenni upprunastaðs foreldris.';
            TableRelation = "Copy Table Mapping ori"."Source Table ID";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Parent Source Table ID" = "Source Table ID" then
                    Error(SameTableIdErr, "Parent Source Table ID", "Source Table ID");
            end;
        }
        field(13; Indentation; Integer)
        {
            Caption = 'Indentation', Comment = 'is-IS=Inndráttur';
        }
        field(14; "Presentation Order"; Integer)
        {
            Caption = 'Presentation Order', Comment = 'is-IS=Framsetningarröð';
        }
        field(15; "Has Children"; Boolean)
        {
            Caption = 'Has Children', Comment = 'is-IS=Hefur undireiningar';
        }
    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(SourceKey; "Source Table ID")
        {
        }
        key(ParentKey; "Parent Source Table ID", "Source Table ID")
        {
        }
        key(PresentationKey; "Presentation Order")
        {
        }
        key(CopyOrder; "Parent Source Table ID", "Has Children", "Destination Table ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Source Table ID", "Source Table Caption")
        {
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid(ID) then
            ID := CreateGuid();
        TestField("Source Table ID");
        UpdateIndentation();
        "Has Children" := HasChildren();
        CalcPresentationOrder();
    end;

    trigger OnModify()
    begin
        UpdateIndentation();
        "Has Children" := HasChildren();
        CalcPresentationOrder();
    end;

    trigger OnDelete()
    var
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        if HasChildren() then
            Error(DeleteWithChildrenErr);

        FieldMapping.SetRange("Copy Table Mapping ID", ID);
        FieldMapping.DeleteAll(true);
    end;

    var
        DefineFiltersTxt: Label 'Specify criteria for when the template will be applied.', Comment = 'is-IS=Tilgreina skilyrði um hvenær nota á sniðmátið.';
        DeleteWithChildrenErr: Label 'You cannot delete this table mapping because it has child table mappings.', Comment = 'is-IS=Þú getur ekki eytt þessari töfluvörpun þar sem það eru til undirtöfluvarpanir sem tengjast þessari vörpun.';
        SameTableIdErr: Label '%1 and %2 can not be the same table Id!', Comment = '%1 = Parent Source Table ID, %2 = Source Table ID, is-IS=%1 og %2 geta ekki verið sama töflukennið!';
        CopyDataQst: Label 'Copy data from %1 to %2?', Comment = '%1 = Source Table Caption, %2 = Destination Table Caption, is-IS=Afrita gögn frá %1 til %2?';

    /// <summary>
    /// Opens a RecordRef for the source table and applies the saved filter. Returns true if at least one record is found.
    /// </summary>
    /// <param name="RecRef">Output: the open RecordRef positioned on the first matching record.</param>
    /// <returns>True if records matching the filter were found; false otherwise.</returns>
    procedure GetRecRefWithFilters(var RecRef: RecordRef) RecordFound: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        OnBeforeGetRecRefWithFilters(Rec, RecRef, RecordFound, IsHandled);
        if IsHandled then
            exit;

        RecRef.Open("Source Table ID", false);
        RecRef.ReadIsolation := IsolationLevel::ReadCommitted;
        CalcFields("Source Table Filter");
        if "Source Table Filter".HasValue() then begin
            TempBlob.FromRecord(Rec, FieldNo("Source Table Filter"));
            RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob);
        end;
        exit(RecRef.FindSet());
    end;

    /// <summary>
    /// Deletes the field mappings of this record and creates one for every normal, enabled, non-obsolete source field.
    /// The destination field is matched automatically by number and compatible type.
    /// </summary>
    procedure SelectAllFields()
    var
        TableField: Record "Field";
        CopyFieldMapping: Record "Copy Field Mapping ori";
        IsHandled: Boolean;
    begin
        OnBeforeSelectAllFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsNullGuid(ID) then
            exit;
        if "Source Table ID" = 0 then
            exit;
        if "Destination Table ID" = 0 then
            exit;
        CopyFieldMapping.SetRange("Copy Table Mapping ID", ID);
        if not CopyFieldMapping.IsEmpty() then
            CopyFieldMapping.DeleteAll(true);

        TableField.SetLoadFields(TableNo, "No.");
        TableField.SetRange(TableNo, "Source Table ID");
        TableField.SetRange(Class, TableField.Class::Normal);
        TableField.SetRange("No.", 0, 1999999999);
        TableField.SetRange(Enabled, true);
        TableField.SetRange(ObsoleteState, TableField.ObsoleteState::No, TableField.ObsoleteState::Pending);
        OnAfterFilterTableFieldsBeforeSelectAllFields(Rec, TableField);
        if TableField.FindSet() then
            repeat
                IsHandled := false;
                CopyFieldMapping.Init();
                CopyFieldMapping."Copy Table Mapping ID" := ID;
                CopyFieldMapping."Source Table ID" := Rec."Source Table ID";
                CopyFieldMapping."Destination Table ID" := Rec."Destination Table ID";
                CopyFieldMapping.Validate("Source Field ID", TableField."No.");
                OnAfterPopulatingCopyFieldMappingBeforeInsert(Rec, TableField, CopyFieldMapping, IsHandled);
                if not IsHandled then
                    CopyFieldMapping.Insert(true);
            until TableField.Next() = 0;

        OnAfterSelectAllFields(Rec, TableField, CopyFieldMapping);
    end;

    /// <summary>
    /// Converts a table view (for example from RecRef.GetView()) into the request-page filter format and saves it to Source Table Filter.
    /// </summary>
    /// <param name="TableView">The table view to save.</param>
    procedure SetViewAsFilter(TableView: Text)
    var
        TableIdTok: Label 'Table%1', Locked = true;
        Filters: Text;
        Doc: XmlDocument;
        DataItemsXmlNode: XmlElement;
        DataItemXmlNode: XmlElement;
        ReportparametersXmlNode: XmlElement;
    begin
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        ReportparametersXmlNode := XmlElement.Create('ReportParameters');
        DataItemsXmlNode := XmlElement.Create('DataItems');
        DataItemXmlNode := XmlElement.Create('DataItem');
        DataItemXmlNode.Add(XmlText.Create(TableView));
        DataItemXmlNode.Attributes().Set('name', StrSubstNo(TableIdTok, "Source Table ID"));
        DataItemsXmlNode.Add(DataItemXmlNode);
        ReportparametersXmlNode.Add(DataItemsXmlNode);
        Doc.Add(ReportparametersXmlNode);
        Doc.WriteTo(Filters);
        RemoveCRLF(Filters);
        SaveTextFilter(Filters);
    end;

    /// <summary>
    /// Recalculates Indentation, Has Children and Presentation Order for all mappings to reflect the current hierarchy.
    /// </summary>
    procedure UpdatePresentationOrder()
    var
        TableMapping: Record "Copy Table Mapping ori";
        TempTableMapping: Record "Copy Table Mapping ori" temporary;
    begin
        TableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if TableMapping.FindSet() then
            repeat
                TempTableMapping.TransferFields(TableMapping);
                TempTableMapping.Insert();
            until TableMapping.Next() = 0;
        UpdatePresentationOrderIterative(TempTableMapping);
    end;

    /// <summary>
    /// Asks for confirmation (unless HideDialog is true), then copies the data of this single table mapping.
    /// </summary>
    /// <param name="HideDialog">When true, copies without asking.</param>
    procedure CopyTableData(HideDialog: Boolean)
    var
        Progress: Codeunit "Copy Table Progress Dialog ori";
        CopyTask: Codeunit "Copy Table Task ori";
    begin
        CalcFields("Source Table Caption", "Destination Table Caption");
        if not HideDialog then
            if not Confirm(CopyDataQst, false, "Source Table Caption", "Destination Table Caption") then
                exit;
        Progress.OpenCopyCountMax("Source Table Caption", GetTableNoOfEntries());
        CopyTask.CopyTableData(Rec, Progress, true);
    end;

    /// <summary>Finds the last mapping with the given source table ID and assigns it to Rec.</summary>
    /// <param name="SourceTableId">The source table ID to search for.</param>
    /// <returns>True if a matching record was found.</returns>
    procedure FindLastBySourceTableId(SourceTableId: Integer) Found: Boolean
    var
        TableMapping: Record "Copy Table Mapping ori";
    begin
        TableMapping.SetRange("Source Table ID", SourceTableId);
        Found := TableMapping.FindLast();
        Rec := TableMapping;
    end;

    /// <summary>Returns the saved source table filter as readable text.</summary>
    /// <returns>The filter expression, or an empty text when no filter is saved.</returns>
    procedure GetFiltersAsTextDisplay(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        FiltersRecordRef: RecordRef;
    begin
        if "Source Table ID" = 0 then
            exit('');
        FiltersRecordRef.Open("Source Table ID");
        CalcFields("Source Table Filter");
        if not "Source Table Filter".HasValue() then
            exit('');
        TempBlob.FromRecord(Rec, FieldNo("Source Table Filter"));

        if RequestPageParametersHelper.ConvertParametersToFilters(FiltersRecordRef, TempBlob) then
            exit(FiltersRecordRef.GetFilters());

        exit('');
    end;

    /// <summary>Returns the style of the row: root and parent mappings are shown in bold.</summary>
    /// <returns>'Strong' for root or parent records; empty text for leaf records.</returns>
    procedure GetStyleText(): Text
    begin
        if Indentation = 0 then
            exit('Strong');

        if HasChildren() then
            exit('Strong');

        exit('');
    end;

    /// <summary>Returns the number of source records that match the saved filter.</summary>
    /// <returns>The count of matching records.</returns>
    procedure GetTableNoOfEntries() NoOfEntries: Integer
    var
        RecRef: RecordRef;
    begin
        GetRecRefWithFilters(RecRef);
        NoOfEntries := RecRef.Count();
        RecRef.Close();
    end;

    /// <summary>Returns true if any mapping uses this mapping's source table as its parent.</summary>
    /// <returns>True if child mappings exist.</returns>
    procedure HasChildren(): Boolean
    var
        TableMapping: Record "Copy Table Mapping ori";
    begin
        if "Source Table ID" = 0 then
            exit(false);
        TableMapping.SetRange("Parent Source Table ID", "Source Table ID");
        exit(not TableMapping.IsEmpty());
    end;

    /// <summary>Saves the given filter text to the Source Table Filter field, replacing any existing filter.</summary>
    /// <param name="NewFilters">The request-page filter text to store.</param>
    procedure SaveTextFilter(NewFilters: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Source Table Filter");
        "Source Table Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(NewFilters);
    end;

    /// <summary>Opens the filter dialog for the source table and saves the result.</summary>
    procedure SetSourceTableFilter()
    var
        CurrentFilters: Text;
        NewFilters: Text;
    begin
        TestField("Source Table ID");

        CurrentFilters := GetExistingFilters();

        if not ShowRequestPageAndGetFilters(NewFilters, CurrentFilters, '', "Source Table ID", DefineFiltersTxt) then
            exit;
        SaveTextFilter(NewFilters);
    end;

    /// <summary>Shows the source table filter as a table view, for use in development.</summary>
    procedure ShowFilterAsView()
    var
        RecRef: RecordRef;
    begin
        GetRecRefWithFilters(RecRef);
        Message(RecRef.GetView(false));
    end;

    /// <summary>Sets Indentation on this record and, recursively, on its child mappings.</summary>
    /// <param name="Level">The indentation level (0 = root).</param>
    procedure UpdateIndentationTree(Level: Integer)
    begin
        Indentation := Level;
        UpdateChildIndentation(Level + 1);
    end;

    /// <summary>Sets and saves Indentation on the child mappings of this record and, recursively, on their children.</summary>
    /// <param name="ChildLevel">The indentation level of the direct children.</param>
    internal procedure UpdateChildIndentation(ChildLevel: Integer)
    var
        TableMapping: Record "Copy Table Mapping ori";
    begin
        TableMapping.SetRange("Parent Source Table ID", "Source Table ID");
        if TableMapping.FindSet() then
            repeat
                TableMapping.Indentation := ChildLevel;
                TableMapping.Modify(false);
                TableMapping.UpdateChildIndentation(ChildLevel + 1);
            until TableMapping.Next() = 0;
    end;

    local procedure CalcPresentationOrder()
    var
        TableMappingNext: Record "Copy Table Mapping ori";
        TableMappingPrev: Record "Copy Table Mapping ori";
        TableMappingSearch: Record "Copy Table Mapping ori";
        TableMappingNextExists: Boolean;
        TableMappingPrevExists: Boolean;
    begin
        if HasChildren() then begin
            "Presentation Order" := 0;
            exit;
        end;

        TableMappingPrev.SetRange("Parent Source Table ID", "Parent Source Table ID");
        TableMappingPrev.SetFilter("Source Table ID", '<%1', "Source Table ID");
        TableMappingPrevExists := TableMappingPrev.FindLast();
        if not TableMappingPrevExists then
            TableMappingPrevExists := TableMappingPrev.FindLastBySourceTableId("Parent Source Table ID")
        else
            TableMappingPrev.FindLastBySourceTableId(GetLastChildID(TableMappingPrev."Source Table ID"));

        TableMappingNext.SetRange("Parent Source Table ID", "Parent Source Table ID");
        TableMappingNext.SetFilter("Source Table ID", '>%1', "Source Table ID");
        TableMappingNextExists := TableMappingNext.FindFirst();
        if not TableMappingNextExists and TableMappingPrevExists then begin
            TableMappingNext.Reset();
            TableMappingNext.SetCurrentKey("Presentation Order");
            TableMappingNext.SetFilter("Source Table ID", '<>%1', "Source Table ID");
            TableMappingNext.SetFilter("Presentation Order", '>%1', TableMappingPrev."Presentation Order");
            TableMappingNextExists := TableMappingNext.FindFirst();
        end;

        case true of
            not TableMappingPrevExists and not TableMappingNextExists:
                "Presentation Order" := 10000;
            not TableMappingPrevExists and TableMappingNextExists:
                "Presentation Order" := TableMappingNext."Presentation Order" div 2;
            TableMappingPrevExists and not TableMappingNextExists:
                "Presentation Order" := TableMappingPrev."Presentation Order" + 10000;
            TableMappingPrevExists and TableMappingNextExists:
                "Presentation Order" := (TableMappingPrev."Presentation Order" + TableMappingNext."Presentation Order") div 2;
        end;

        TableMappingSearch.SetRange("Presentation Order", "Presentation Order");
        TableMappingSearch.SetFilter("Source Table ID", '<>%1', "Source Table ID");
        if not TableMappingSearch.IsEmpty() then
            "Presentation Order" := 0;
    end;

    local procedure GetExistingFilters() Filters: Text
    var
        FiltersInStream: InStream;
    begin
        CalcFields("Source Table Filter");
        if not "Source Table Filter".HasValue() then
            exit;

        "Source Table Filter".CreateInStream(FiltersInStream);
        FiltersInStream.Read(Filters);
    end;

    local procedure GetLastChildID(ParentTableId: Integer) ChildID: Integer
    var
        TableMapping: Record "Copy Table Mapping ori";
        TempStack: Record TempStack temporary;
        RecId: RecordId;
    begin
        ChildID := ParentTableId;

        TableMapping.Ascending(false);
        TableMapping.SetRange("Parent Source Table ID", ParentTableId);
        if TableMapping.FindSet() then
            repeat
                TempStack.Push(TableMapping.RecordId());
            until TableMapping.Next() = 0;

        while TempStack.Pop(RecId) do begin
            TableMapping.Get(RecId);
            ChildID := TableMapping."Source Table ID";

            TableMapping.SetRange("Parent Source Table ID", TableMapping."Source Table ID");
            if TableMapping.FindSet() then
                repeat
                    TempStack.Push(TableMapping.RecordId());
                until TableMapping.Next() = 0;
        end;
    end;

    local procedure RemoveCRLF(var Filters: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        Line: Text;
        OneLineText: TextBuilder;
    begin
        foreach Line in Filters.Split(TypeHelper.NewLine()) do
            OneLineText.Append(Line);
        Filters := OneLineText.ToText();
    end;

    local procedure ShowRequestPageAndGetFilters(var NewFilters: Text; ExistingFilters: Text; EntityName: Code[20]; TableNum: Integer; PageCaption: Text) FiltersSet: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, TableNum) then
            exit(false);

        if ExistingFilters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPageBuilder, ExistingFilters, EntityName, TableNum) then
                exit(false);

        FilterPageBuilder.PageCaption := PageCaption;
        if not FilterPageBuilder.RunModal() then
            exit(false);

        NewFilters := RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, TableNum);

        FiltersSet := true;
    end;

    local procedure UpdateIndentation()
    var
        TableMapping: Record "Copy Table Mapping ori";
    begin
        TableMapping.SetRange("Source Table ID", "Parent Source Table ID");
        if ("Parent Source Table ID" <> 0) and TableMapping.FindFirst() then
            UpdateIndentationTree(TableMapping.Indentation + 1)
        else
            UpdateIndentationTree(0);
    end;

    local procedure UpdatePresentationOrderIterative(var TempTableMapping: Record "Copy Table Mapping ori" temporary)
    var
        TableMapping: Record "Copy Table Mapping ori";
        TempCurTableMapping: Record "Copy Table Mapping ori" temporary;
        TempStack: Record TempStack temporary;
        CurTableMappingID: RecordId;
        NewHasChildren: Boolean;
        NewIndentation: Integer;
        PresentationOrder: Integer;
    begin
        PresentationOrder := 0;

        TempCurTableMapping.Copy(TempTableMapping, true);

        TempTableMapping.SetCurrentKey("Parent Source Table ID", "Has Children", "Destination Table ID");
        TempTableMapping.Ascending(false);
        TempTableMapping.SetRange("Parent Source Table ID", 0);
        if TempTableMapping.FindSet() then
            repeat
                TempStack.Push(TempTableMapping.RecordId());
            until TempTableMapping.Next() = 0;

        while TempStack.Pop(CurTableMappingID) do begin
            TempCurTableMapping.Get(CurTableMappingID);
            NewHasChildren := false;

            TempTableMapping.SetRange("Parent Source Table ID", TempCurTableMapping."Source Table ID");
            if TempTableMapping.FindSet() then
                repeat
                    TempStack.Push(TempTableMapping.RecordId());
                    NewHasChildren := true;
                until TempTableMapping.Next() = 0;

            if TempCurTableMapping."Parent Source Table ID" <> 0 then begin
                TempTableMapping.FindLastBySourceTableId(TempCurTableMapping."Parent Source Table ID");
                NewIndentation := TempTableMapping.Indentation + 1;
            end else
                NewIndentation := 0;
            PresentationOrder := PresentationOrder + 10000;

            if (TempCurTableMapping."Presentation Order" <> PresentationOrder) or
               (TempCurTableMapping.Indentation <> NewIndentation) or (TempCurTableMapping."Has Children" <> NewHasChildren)
            then begin
                TableMapping.Get(TempCurTableMapping.ID);
                TableMapping."Presentation Order" := PresentationOrder;
                TableMapping.Indentation := NewIndentation;
                TableMapping."Has Children" := NewHasChildren;
                TableMapping.Modify(false);
                TempCurTableMapping."Presentation Order" := PresentationOrder;
                TempCurTableMapping.Indentation := NewIndentation;
                TempCurTableMapping."Has Children" := NewHasChildren;
                TempCurTableMapping.Modify(false);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterTableFieldsBeforeSelectAllFields(Rec: Record "Copy Table Mapping ori"; var TableField: Record Field)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulatingCopyFieldMappingBeforeInsert(Rec: Record "Copy Table Mapping ori"; TableField: Record Field; var CopyFieldMapping: Record "Copy Field Mapping ori"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectAllFields(var Rec: Record "Copy Table Mapping ori"; TableField: Record "Field"; CopyFieldMapping: Record "Copy Field Mapping ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRecRefWithFilters(var Rec: Record "Copy Table Mapping ori"; var RecRef: RecordRef; var RecordFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectAllFields(var Rec: Record "Copy Table Mapping ori"; var IsHandled: Boolean)
    begin
    end;
}
