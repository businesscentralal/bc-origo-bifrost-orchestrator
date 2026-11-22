namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Lists the Copy Table Mapping records as an indented parent/child tree, where users configure and run
/// table-to-table data copies (port of Tools for Power Users "Copy Tables Mapping").
/// </summary>
page 10035612 "Copy Tables Mapping ori"
{
    ApplicationArea = All;
    Caption = 'Copy Tables Mapping', Comment = 'is-IS=Töfluafritun - vörpun';
    CardPageId = "Copy Table Mapping Card ori";
    Editable = false;
    PageType = List;
    SourceTable = "Copy Table Mapping ori";
    SourceTableView = sorting("Presentation Order") order(ascending);
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Source Table Caption";
                ShowCaption = false;

                field("Source Table ID"; Rec."Source Table ID")
                {
                    StyleExpr = StyleTxt;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        Rec.SelectAllFields();
                    end;
                }
                field("Source Table Caption"; Rec."Source Table Caption")
                {
                    StyleExpr = StyleTxt;
                }
                field("Source Table Filter"; SourceTableFilterText)
                {
                    Caption = 'Source Table Filter', Comment = 'is-IS=Töfluafmörkun upprunastaðar';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Source Table Filter field.', Comment = 'is-IS=Tilgreinir gildi reitsins töfluafmörkun upprunastaðar.';

                    trigger OnAssistEdit()
                    begin
                        if not CurrPage.Editable() then
                            exit;
                        Rec.SetSourceTableFilter();
                        CurrPage.Update(true);
                    end;
                }
                field("Destination Table ID"; Rec."Destination Table ID")
                {
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        Rec.SelectAllFields();
                    end;
                }
                field("Destination Table Caption"; Rec."Destination Table Caption")
                {
                }
                field("Data Template"; Rec."Data Template Code")
                {
                    Caption = 'Data Template', Comment = 'is-IS=Gagnasniðmát';
                    ToolTip = 'Specifies the value of the Data Template field', Comment = 'is-IS=Tilgreinir gildi reitsins gagnasniðmát';
                }
                field("Parent Source Table ID"; Rec."Parent Source Table ID")
                {
                }
                field("Manual Copy"; Rec."Manual Copy")
                {
                }
                field("Copy Method"; Rec."Copy Method")
                {
                }
                field("Last Copy Time"; Rec."Last Copy Time")
                {
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(FieldMapping)
            {
                Caption = 'Field Mapping', Comment = 'is-IS=Vörpun reita';
                Image = Relationship;
                RunObject = page "Copy Fields Mapping ori";
                RunPageLink = "Copy Table Mapping ID" = field(ID);
                Scope = Repeater;
                ToolTip = 'View or edit the field mapping for the selected table mapping.', Comment = 'is-IS=Skoða eða breyta reitavörpun fyrir valda töfluvörpun.';
            }
        }
        area(Processing)
        {
            action(CopyTableData)
            {
                Caption = 'Copy Table Data', Comment = 'is-IS=Afrita töfluggögn';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Copy data from the source table to the destination table.', Comment = 'is-IS=Afrita gögn frá upprunastað til viðtökustaðar.';

                trigger OnAction()
                var
                    CopyTableMapping: Record "Copy Table Mapping ori";
                    CopyDataQst: Label 'Copy data for %1 table(s)?', Comment = '%1 = No. of tables selected, is-IS=Afrita gögn fyrir %1 töflu(r)?';
                begin
                    CurrPage.SetSelectionFilter(CopyTableMapping);
                    if not Confirm(CopyDataQst, true, CopyTableMapping.Count()) then
                        exit;
                    TableMappingEvents.BeforeDataCopy();
                    if CopyTableMapping.FindSet() then
                        repeat
                            CopyTableMapping.CopyTableData(true);
                            Commit();
                        until CopyTableMapping.Next() = 0;
                    TableMappingEvents.AfterDataCopy();
                end;
            }
            action(ShowFilterAsView)
            {
                Caption = 'Show Filter as View', Comment = 'is-IS=Sýna afmörkun sem sjónarhorn';
                Image = Filter;
                Scope = Repeater;
                ToolTip = 'Show the source table filter as a view to be used in development.', Comment = 'is-IS=Sýna töfluafmörkun upprunastaðar sem sjónarhorn til notkunar í forritun.';

                trigger OnAction()
                begin
                    Rec.ShowFilterAsView();
                end;
            }
            action(Recalculate)
            {
                Caption = 'Recalculate', Comment = 'is-IS=Endurreikna';
                Image = Hierarchy;
                ToolTip = 'Update the tree of table mapping based on recent changes.', Comment = 'is-IS=Uppfæra vörpunartré sem byggist á nýlegum breytingum.';

                trigger OnAction()
                begin
                    Rec.UpdatePresentationOrder();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(FieldMapping_Promoted; FieldMapping)
                {
                }
                actionref(CopyTableData_Promoted; CopyTableData)
                {
                }
            }
        }
    }

    var
        TableMappingEvents: Codeunit "Copy Table Events ori";
        SourceTableFilterText: Text;
        StyleTxt: Text;

    trigger OnInit()
    var
        Progress: Codeunit "Copy Table Progress Dialog ori";
    begin
        TableMappingEvents.BeforeUsingTableMapping(Progress);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ID := CreateGuid();
        SourceTableFilterText := '';
        StyleTxt := '';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SourceTableFilterText := Rec.GetFiltersAsTextDisplay();
        StyleTxt := Rec.GetStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        SourceTableFilterText := Rec.GetFiltersAsTextDisplay();
        StyleTxt := Rec.GetStyleText();
    end;
}
