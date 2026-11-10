namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>A reusable field mapping that generates a guarded, schedulable copy playbook.</summary>
table 10035577 "Copy Plan ori"
{
    Access = Internal;
    Caption = 'Copy Plan', Comment = 'is-IS=Afritunaráætlun';
    DataClassification = CustomerContent;
    LookupPageId = "Copy Plans ori";
    DrillDownPageId = "Copy Plans ori";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            ToolTip = 'Specifies the unique code of the copy plan.', Comment = 'is-IS=Tilgreinir einkvæman kóða afritunaráætlunarinnar.';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
            ToolTip = 'Specifies the purpose of this copy plan.', Comment = 'is-IS=Tilgreinir tilgang afritunaráætlunarinnar.';
        }
        field(3; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.', Comment = 'is-IS=Númer upprunatöflu';
            ToolTip = 'Specifies the table to read through Data.Records.Get.', Comment = 'is-IS=Tilgreinir töfluna sem lesin er með Data.Records.Get.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Destination Table No."; Integer)
        {
            Caption = 'Destination Table No.', Comment = 'is-IS=Númer marktöflu';
            ToolTip = 'Specifies the table to write through Data.Records.Set with Foundation guards.', Comment = 'is-IS=Tilgreinir töfluna sem skrifað er í með Data.Records.Set og vörnum Foundation.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5; "Source View"; Text[2048])
        {
            Caption = 'Source View', Comment = 'is-IS=Upprunasýn';
            ToolTip = 'Specifies the table view and filters used to select source records.', Comment = 'is-IS=Tilgreinir töflusýn og afmarkanir fyrir upprunafærslur.';
        }
        field(6; "Page Size"; Integer)
        {
            Caption = 'Page Size', Comment = 'is-IS=Síðustærð';
            ToolTip = 'Specifies how many source rows the runner reads per page.', Comment = 'is-IS=Tilgreinir hversu margar upprunafærslur eru lesnar á hverri síðu.';
            InitValue = 50;
            MinValue = 1;
            MaxValue = 500;
        }
        field(7; "Parent Plan Code"; Code[20])
        {
            Caption = 'Parent Plan Code', Comment = 'is-IS=Kóði yfirskipaðrar áætlunar';
            ToolTip = 'Specifies the plan that must run before this child plan.', Comment = 'is-IS=Tilgreinir áætlunina sem verður að keyra á undan þessari undirskipuðu áætlun.';
            TableRelation = "Copy Plan ori".Code;
        }
        field(8; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.', Comment = 'is-IS=Raðnúmer';
            ToolTip = 'Specifies the order of child plans under the same parent.', Comment = 'is-IS=Tilgreinir röð undirskipaðra áætlana undir sama foreldri.';
        }
        field(9; "Generated Playbook Code"; Code[20])
        {
            Caption = 'Generated Playbook Code', Comment = 'is-IS=Kóði myndaðrar keðju';
            ToolTip = 'Specifies the only playbook replaced when this plan is generated again.', Comment = 'is-IS=Tilgreinir eina keðjuna sem er skipt út þegar áætlunin er mynduð aftur.';
            TableRelation = "Playbook ori".Code;
            Editable = false;
        }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
        key(ParentOrder; "Parent Plan Code", "Sequence No.", Code) { }
    }
    trigger OnDelete()
    var
        CopyField: Record "Copy Plan Field ori";
        Child: Record "Copy Plan ori";
    begin
        Child.SetRange("Parent Plan Code", Code);
        Child.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Child.IsEmpty() then
            Error(ErrorInfo.Create(ChildrenExistErr));
        CopyField.SetRange("Plan Code", Code);
        CopyField.DeleteAll(true);
    end;
    var
        ChildrenExistErr: Label 'Remove or reparent the child plans before deleting this plan.', Comment = 'is-IS=Fjarlægðu eða tengdu undirskipaðar áætlanir við annað foreldri áður en þessari áætlun er eytt.';
}
