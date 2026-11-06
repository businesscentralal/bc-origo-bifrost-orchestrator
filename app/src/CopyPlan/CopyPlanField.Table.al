namespace Origo.Bifrost.Orchestrator;

/// <summary>Maps one source field to one destination field without granting access to either table.</summary>
table 10035578 "Copy Plan Field ori"
{
    Access = Internal;
    Caption = 'Copy Plan Field', Comment = 'is-IS=Reitur afritunaráætlunar';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Plan Code"; Code[20])
        {
            Caption = 'Plan Code', Comment = 'is-IS=Áætlunarkóði';
            ToolTip = 'Specifies the copy plan that owns this mapping.', Comment = 'is-IS=Tilgreinir afritunaráætlunina sem á þessa vörpun.';
            TableRelation = "Copy Plan ori".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.', Comment = 'is-IS=Línunúmer';
            ToolTip = 'Specifies the order of the field mapping.', Comment = 'is-IS=Tilgreinir röð reitavörpunarinnar.';
        }
        field(3; "Source Field No."; Integer)
        {
            Caption = 'Source Field No.', Comment = 'is-IS=Númer upprunareits';
            ToolTip = 'Specifies the field to read from the source table.', Comment = 'is-IS=Tilgreinir reitinn sem lesinn er úr upprunatöflunni.';
            trigger OnValidate()
            var
                Plan: Record "Copy Plan ori";
                Generator: Codeunit "Copy Plan Generator ori";
            begin
                Plan.Get("Plan Code");
                Generator.ValidateField(Plan."Source Table No.", "Source Field No.");
            end;
        }
        field(4; "Destination Field No."; Integer)
        {
            Caption = 'Destination Field No.', Comment = 'is-IS=Númer markreits';
            ToolTip = 'Specifies the destination field; key fields identify the row to insert or update.', Comment = 'is-IS=Tilgreinir markreitinn; lykilreitir auðkenna færsluna sem á að bæta við eða uppfæra.';
            trigger OnValidate()
            var
                Plan: Record "Copy Plan ori";
                Generator: Codeunit "Copy Plan Generator ori";
            begin
                Plan.Get("Plan Code");
                Generator.ValidateField(Plan."Destination Table No.", "Destination Field No.");
            end;
        }
        field(5; Skip; Boolean)
        {
            Caption = 'Skip', Comment = 'is-IS=Sleppa';
            ToolTip = 'Specifies that this mapping is excluded from the generated playbook.', Comment = 'is-IS=Tilgreinir að þessari vörpun sé sleppt úr mynduðu keðjunni.';
        }
    }
    keys { key(PK; "Plan Code", "Line No.") { Clustered = true; } }
}
