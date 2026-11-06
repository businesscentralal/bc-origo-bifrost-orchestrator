namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>Maintains the fields definition used by the guarded copy generator.</summary>
page 10035608 "Copy Plan Fields ori"
{
    Caption = 'Fields', Comment = 'is-IS=Reitir';
    PageType = ListPart;
    SourceTable = "Copy Plan Field ori";
    ApplicationArea = All;
    ContextSensitiveHelpPage = 'playbooks';
    AutoSplitKey = true;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Source Field No."; Rec."Source Field No.")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupField(true));
                    end;
                }
                field("Destination Field No."; Rec."Destination Field No.")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupField(false));
                    end;
                }
                field("Skip"; Rec."Skip")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    local procedure LookupField(Source: Boolean): Boolean
    var
        Plan: Record "Copy Plan ori";
        TableField: Record Field;
    begin
        Plan.Get(Rec."Plan Code");
        if Source then
            TableField.SetRange(TableNo, Plan."Source Table No.")
        else
            TableField.SetRange(TableNo, Plan."Destination Table No.");
        TableField.SetRange(Class, TableField.Class::Normal);
        if Page.RunModal(Page::"Fields Lookup", TableField) <> Action::LookupOK then
            exit(false);
        if Source then
            Rec.Validate("Source Field No.", TableField."No.")
        else
            Rec.Validate("Destination Field No.", TableField."No.");
        exit(true);
    end;
}
