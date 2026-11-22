namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Card for one Copy Table Mapping: source and destination tables, source filter, data template and copy method
/// (port of Tools for Power Users "Copy Table Mapping Card").
/// </summary>
page 10035613 "Copy Table Mapping Card ori"
{
    ApplicationArea = All;
    Caption = 'Copy Table Mapping Card', Comment = 'is-IS=Töfluvörpunarspjald';
    DataCaptionExpression = '';
    DataCaptionFields = "Source Table ID", "Source Table Caption";
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Copy Table Mapping ori";
    UsageCategory = None;
    ContextSensitiveHelpPage = 'playbooks';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("Parent Source Table ID"; Rec."Parent Source Table ID")
                {
                }
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        Rec.SelectAllFields();
                    end;
                }
                field("Source Table Caption"; Rec."Source Table Caption")
                {
                    QuickEntry = false;
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
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        Rec.SelectAllFields();
                    end;
                }
                field("Destination Table Caption"; Rec."Destination Table Caption")
                {
                    QuickEntry = false;
                }
                field("Data Template Code"; Rec."Data Template Code")
                {
                }
                field("Copy Method"; Rec."Copy Method")
                {
                }
                field("Manual Copy"; Rec."Manual Copy")
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
                ToolTip = 'View or edit the field mapping for the selected table mapping.', Comment = 'is-IS=Skoða eða breyta reitavörpun fyrir valda töfluvörpun.';
            }
        }
        area(Processing)
        {
            action(CopyTableData)
            {
                Caption = 'Copy Table Data', Comment = 'is-IS=Afrita töfluggögn';
                Image = Import;
                ToolTip = 'Copy data from the source table to the destination table.', Comment = 'is-IS=Afrita gögn frá upprunastað til viðtökustaðar.';

                trigger OnAction()
                var
                    CopyTableMapping: Record "Copy Table Mapping ori";
                    TableMappingEvents: Codeunit "Copy Table Events ori";
                begin
                    CurrPage.SetSelectionFilter(CopyTableMapping);
                    TableMappingEvents.BeforeDataCopy();
                    if CopyTableMapping.FindSet() then
                        repeat
                            CopyTableMapping.CopyTableData(false);
                            Commit();
                        until CopyTableMapping.Next() = 0;
                    TableMappingEvents.AfterDataCopy();
                end;
            }
            action(ShowFilterAsView)
            {
                Caption = 'Show Filter as View', Comment = 'is-IS=Sýna afmörkun sem sjónarhorn';
                Image = Filter;
                ToolTip = 'Show the source table filter as a view to be used in development.', Comment = 'is-IS=Sýna töfluafmörkun upprunastaðar sem sjónarhorn til notkunar í forritun.';

                trigger OnAction()
                begin
                    Rec.ShowFilterAsView();
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
        SourceTableFilterText: Text;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ID := CreateGuid();
        SourceTableFilterText := '';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SourceTableFilterText := Rec.GetFiltersAsTextDisplay();
    end;

    trigger OnAfterGetRecord()
    begin
        SourceTableFilterText := Rec.GetFiltersAsTextDisplay();
    end;
}
