namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Lists the field mappings of one Copy Table Mapping, source field to destination field with an optional
/// Transformation Rule (port of Tools for Power Users "Copy Fields Mapping").
/// </summary>
page 10035614 "Copy Fields Mapping ori"
{
    ApplicationArea = All;
    Caption = 'Copy Fields Mapping', Comment = 'is-IS=Reitaafritun - vörpun';
    PageType = List;
    SourceTable = "Copy Field Mapping ori";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Source Field ID"; Rec."Source Field ID")
                {
                    LookupPageId = "Copy Tbl. Fields Selection ori";
                }
                field("Source Field Caption"; Rec."Source Field Caption")
                {
                }
                field("Destination Field ID"; Rec."Destination Field ID")
                {
                    LookupPageId = "Copy Tbl. Fields Selection ori";
                }
                field("Destination Field Caption"; Rec."Destination Field Caption")
                {
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                }
                field("Is Part Of Primary Key"; Rec."Is Part Of Primary Key")
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ClearDestinationMapping)
            {
                Caption = 'Clear Destination Mapping', Comment = 'is-IS=Hreinsa vörpun viðtökustaðar.';
                Image = Restore;
                ToolTip = 'Clears the Destination Field ID field.', Comment = 'is-IS=Hreinsar reitarkenni viðtökustaðar.';

                trigger OnAction()
                begin
                    Rec."Destination Field ID" := 0;
                    Rec.Modify(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ClearDestinationMapping_Promoted; ClearDestinationMapping)
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        TableMappingId: Guid;
    begin
        if Evaluate(TableMappingId, Rec.GetFilter("Copy Table Mapping ID")) then
            Rec.Validate("Copy Table Mapping ID", TableMappingId);
    end;
}
