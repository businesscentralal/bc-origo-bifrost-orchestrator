namespace Origo.Bifrost.Orchestrator;

/// <summary>Ordered field mappings belonging to a Transform step; contains definitions, never business data.</summary>
table 10035625 "Playbook Transform ori"
{
    Access = Internal;
    Caption = 'Playbook Transform', Comment = 'is-IS=Umbreyting keðju';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Playbook Code"; Code[20])
        {
            Caption = 'Playbook Code', Comment = 'is-IS=Keðjukóði';
            ToolTip = 'Specifies the playbook that owns this mapping.', Comment = 'is-IS=Tilgreinir keðjuna sem á þessa vörpun.';
            TableRelation = "Playbook ori".Code;
        }
        field(2; "Step No."; Integer)
        {
            Caption = 'Step No.', Comment = 'is-IS=Skrefnúmer';
            ToolTip = 'Specifies the Transform step.', Comment = 'is-IS=Tilgreinir umbreytingarskrefið.';
            TableRelation = "Playbook Step ori"."Step No." where("Playbook Code" = field("Playbook Code"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.', Comment = 'is-IS=Línunúmer';
            ToolTip = 'Specifies the order of this mapping.', Comment = 'is-IS=Tilgreinir röð þessarar vörpunar.';
        }
        field(10; "Target Path"; Text[250])
        {
            Caption = 'Target Path', Comment = 'is-IS=Markslóð';
            ToolTip = 'Specifies the dot-separated path in the output row.', Comment = 'is-IS=Tilgreinir slóðina í úttaksfærslunni.';
        }
        field(20; "Source Path"; Text[250])
        {
            Caption = 'Source Path', Comment = 'is-IS=Upprunaslóð';
            ToolTip = 'Specifies the path in the input row, or an @workspace reference.', Comment = 'is-IS=Tilgreinir slóðina í inntaksfærslunni eða @tilvísun í vinnusvæði.';
        }
        field(30; "Operation"; Enum "Transform Operation ori")
        {
            Caption = 'Operation', Comment = 'is-IS=Aðgerð';
            ToolTip = 'Specifies the operation applied to the source value.', Comment = 'is-IS=Tilgreinir aðgerðina sem beitt er á upprunagildið.';
        }
        field(40; "Argument 1"; Text[250])
        {
            Caption = 'Argument 1', Comment = 'is-IS=Viðfang 1';
            ToolTip = 'Specifies the constant value or text to replace.', Comment = 'is-IS=Tilgreinir fastagildið eða textann sem á að skipta út.';
        }
        field(50; "Argument 2"; Text[250])
        {
            Caption = 'Argument 2', Comment = 'is-IS=Viðfang 2';
            ToolTip = 'Specifies the replacement text.', Comment = 'is-IS=Tilgreinir nýja textann.';
        }
    }
    keys
    {
        key(PK; "Playbook Code", "Step No.", "Line No.") { Clustered = true; }
    }
}
