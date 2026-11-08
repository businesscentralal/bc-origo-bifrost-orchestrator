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
        field(6; Operation; Enum "Transform Operation ori")
        {
            Caption = 'Operation', Comment = 'is-IS=Aðgerð';
            ToolTip = 'Specifies the field transformation applied before writing the destination.', Comment = 'is-IS=Tilgreinir umbreytingu reitsins áður en skrifað er í marktöfluna.';
        }
        field(7; "Argument 1"; Text[250])
        {
            Caption = 'Argument 1', Comment = 'is-IS=Viðfang 1';
            ToolTip = 'Specifies the constant value or text to replace.', Comment = 'is-IS=Tilgreinir fastagildið eða textann sem á að skipta út.';
        }
        field(8; "Argument 2"; Text[250])
        {
            Caption = 'Argument 2', Comment = 'is-IS=Viðfang 2';
            ToolTip = 'Specifies the replacement text.', Comment = 'is-IS=Tilgreinir nýja textann.';
        }
    }
    keys
    {
        key(PK; "Plan Code", "Line No.")
        {
            Clustered = true;
        }
    }
}
