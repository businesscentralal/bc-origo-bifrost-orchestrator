namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

/// <summary>Generates ordered Get/Set steps while leaving all business access checks to Foundation.</summary>
codeunit 10035622 "Copy Plan Generator ori"
{
    Access = Internal;

    /// <summary>Replaces only this plan's generated playbook, after validating the complete plan tree.</summary>
    /// <param name="PlanCode">Root copy plan code.</param>
    internal procedure Generate(PlanCode: Code[20])
    var
        Plan: Record "Copy Plan ori";
        Playbook: Record "Playbook ori";
        Step: Record "Playbook Step ori";
        OrderedPlans: List of [Code[20]];
        CurrentCode: Code[20];
        PlaybookCode: Code[20];
        StepNo: Integer;
    begin
        Plan.Get(PlanCode);
        Plan.TestField("Parent Plan Code", '');
        CollectPlans(PlanCode, OrderedPlans);
        foreach CurrentCode in OrderedPlans do
            ValidatePlan(CurrentCode);
        PlaybookCode := Plan."Generated Playbook Code";
        if PlaybookCode = '' then begin
            PlaybookCode := Plan.Code;
            if Playbook.Get(PlaybookCode) then
                Error(ErrorInfo.Create(StrSubstNo(PlaybookExistsErr, PlaybookCode)));
        end;
        if not Playbook.Get(PlaybookCode) then begin
            Playbook.Init();
            Playbook.Code := PlaybookCode;
            Playbook.Insert(true);
        end;
        Playbook.Description := Plan.Description;
        Playbook.Modify(true);
        Step.SetRange("Playbook Code", PlaybookCode);
        Step.DeleteAll(true);
        StepNo := 10;
        foreach CurrentCode in OrderedPlans do begin
            AddPlanSteps(CurrentCode, PlaybookCode, StepNo);
            StepNo += 20;
        end;
        // The final Set terminates the graph; all earlier pairs lead to the next parent/child pair.
        Step.Get(PlaybookCode, StepNo - 10);
        Step."Next Step No. (Success)" := 0;
        Step.Modify(true);
        Plan."Generated Playbook Code" := PlaybookCode;
        Plan.Modify(true);
    end;

    /// <summary>Checks field metadata both at entry time and when generating a plan.</summary>
    /// <param name="TableNo">Table containing the field.</param>
    /// <param name="FieldNo">Normal enabled field number.</param>
    internal procedure ValidateField(TableNo: Integer; FieldNo: Integer)
    var
        TableField: Record Field;
    begin
        TableField.Get(TableNo, FieldNo);
        TableField.TestField(Class, TableField.Class::Normal);
        TableField.TestField(Enabled, true);
        if FieldNo >= 2000000000 then
            Error(ErrorInfo.Create(SystemFieldErr));
    end;

    local procedure CollectPlans(PlanCode: Code[20]; var OrderedPlans: List of [Code[20]])
    var
        Child: Record "Copy Plan ori";
    begin
        if OrderedPlans.Contains(PlanCode) then
            Error(ErrorInfo.Create(StrSubstNo(CycleErr, PlanCode)));
        OrderedPlans.Add(PlanCode);
        Child.SetCurrentKey("Parent Plan Code", "Sequence No.", Code);
        Child.SetLoadFields(Code, "Parent Plan Code", "Sequence No.");
        Child.SetRange("Parent Plan Code", PlanCode);
        Child.ReadIsolation := IsolationLevel::ReadCommitted;
        if Child.FindSet() then
            repeat
                CollectPlans(Child.Code, OrderedPlans);
            until Child.Next() = 0;
    end;

    local procedure ValidatePlan(PlanCode: Code[20])
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
        Source: RecordRef;
        Destination: RecordRef;
        DestinationKey: KeyRef;
        TargetFields: List of [Integer];
        Index: Integer;
    begin
        Plan.Get(PlanCode);
        Plan.TestField("Source Table No.");
        Plan.TestField("Destination Table No.");
        if (Plan."Page Size" < 1) or (Plan."Page Size" > 500) then
            Error(ErrorInfo.Create(PageSizeErr));
        Source.Open(Plan."Source Table No.");
        if Plan."Source View" <> '' then
            Source.SetView(Plan."Source View");
        Source.Close();
        Mapping.SetRange("Plan Code", PlanCode);
        Mapping.SetRange(Skip, false);
        Mapping.SetLoadFields("Plan Code", Skip, "Source Field No.", "Destination Field No.");
        Mapping.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Mapping.FindSet() then
            Error(ErrorInfo.Create(StrSubstNo(NoFieldsErr, PlanCode)));
        repeat
            ValidateField(Plan."Source Table No.", Mapping."Source Field No.");
            ValidateField(Plan."Destination Table No.", Mapping."Destination Field No.");
            if TargetFields.Contains(Mapping."Destination Field No.") then
                Error(ErrorInfo.Create(StrSubstNo(DuplicateFieldErr, Mapping."Destination Field No.")));
            TargetFields.Add(Mapping."Destination Field No.");
        until Mapping.Next() = 0;
        Destination.Open(Plan."Destination Table No.");
        DestinationKey := Destination.KeyIndex(1);
        for Index := 1 to DestinationKey.FieldCount() do
            if not TargetFields.Contains(DestinationKey.FieldIndex(Index).Number) then
                Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, DestinationKey.FieldIndex(Index).Name)));
        Destination.Close();
    end;

    local procedure AddPlanSteps(PlanCode: Code[20]; PlaybookCode: Code[20]; StepNo: Integer)
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
        Step: Record "Playbook Step ori";
        Source: RecordRef;
        Destination: RecordRef;
        Request: JsonObject;
        Fields: JsonObject;
        PrimaryKey: JsonObject;
        Row: JsonObject;
        Rows: JsonArray;
        FieldNumbers: JsonArray;
        SelectedFields: List of [Integer];
        RequestText: Text;
        SourcePath: Text;
        TargetName: Text;
    begin
        Plan.Get(PlanCode);
        Source.Open(Plan."Source Table No.");
        Destination.Open(Plan."Destination Table No.");
        Mapping.SetRange("Plan Code", PlanCode);
        Mapping.SetRange(Skip, false);
        Mapping.SetLoadFields("Plan Code", Skip, "Source Field No.", "Destination Field No.");
        Mapping.ReadIsolation := IsolationLevel::ReadCommitted;
        if Mapping.FindSet() then
            repeat
                if not SelectedFields.Contains(Mapping."Source Field No.") then begin
                    SelectedFields.Add(Mapping."Source Field No.");
                    FieldNumbers.Add(Mapping."Source Field No.");
                end;
                if IsKeyField(Source, Mapping."Source Field No.") then
                    SourcePath := '@_current.primaryKey.'
                else
                    SourcePath := '@_current.fields.';
                SourcePath += JsonFieldName(Source.Field(Mapping."Source Field No.").Name);
                TargetName := JsonFieldName(Destination.Field(Mapping."Destination Field No.").Name);
                if IsKeyField(Destination, Mapping."Destination Field No.") then
                    PrimaryKey.Add(TargetName, SourcePath)
                else
                    Fields.Add(TargetName, SourcePath);
            until Mapping.Next() = 0;
        Request.Add('tableName', Source.Name);
        // SetView accepts field numbers, while the public Data.Records contract requires names.
        if Plan."Source View" <> '' then
            Source.SetView(Plan."Source View");
        Request.Add('tableView', Source.GetView(true));
        Request.Add('fieldNumbers', FieldNumbers);
        Request.WriteTo(RequestText);
        Step.Init();
        Step."Playbook Code" := PlaybookCode;
        Step."Step No." := StepNo;
        Step.Description := Plan.Description;
        Step."Message Type" := "Message Type ori"::"Data.Records.Get";
        Step.Paged := true;
        Step."Page Size" := Plan."Page Size";
        Step."Page Through Step No." := StepNo + 10;
        Step."Next Step No. (Success)" := StepNo + 10;
        Step.SetRequestTemplate(RequestText);
        Step.Insert(true);
        AddSuccessCondition(PlaybookCode, StepNo, 'noOfRecords', "Playbook Cond. Operator ori"::GreaterOrEqual, '0');
        Clear(Request);
        Row.Add('primaryKey', PrimaryKey);
        Row.Add('fields', Fields);
        Rows.Add(Row);
        Request.Add('tableName', Destination.Name);
        Request.Add('data', Rows);
        Request.WriteTo(RequestText);
        Clear(Step);
        Step.Init();
        Step."Playbook Code" := PlaybookCode;
        Step."Step No." := StepNo + 10;
        Step.Description := Plan.Description;
        Step."Message Type" := "Message Type ori"::"Data.Records.Set";
        Step."Iterate Source Step No." := StepNo;
        Step."Iterate Array Path" := 'result';
        Step."Stop On Item Error" := true;
        Step."Next Step No. (Success)" := StepNo + 20;
        Step.SetRequestTemplate(RequestText);
        Step.Insert(true);
        AddSuccessCondition(PlaybookCode, StepNo + 10, 'status', "Playbook Cond. Operator ori"::Equals, 'Success');
        Source.Close();
        Destination.Close();
    end;

    local procedure IsKeyField(TableRef: RecordRef; FieldNo: Integer): Boolean
    var
        PrimaryKey: KeyRef;
        Index: Integer;
    begin
        PrimaryKey := TableRef.KeyIndex(1);
        for Index := 1 to PrimaryKey.FieldCount() do
            if PrimaryKey.FieldIndex(Index).Number = FieldNo then
                exit(true);
        exit(false);
    end;

    local procedure JsonFieldName(FieldName: Text): Text
    begin
        // Match the public Data.Records field-key contract; no record serialization is performed here.
        FieldName := ConvertStr(FieldName, '%."\/''', '______');
        exit(DelChr(FieldName, '=', DelChr(FieldName, '=', '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')));
    end;

    local procedure AddSuccessCondition(PlaybookCode: Code[20]; StepNo: Integer; Path: Text[250]; Operator: Enum "Playbook Cond. Operator ori"; Value: Text[250])
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.Init();
        Condition."Playbook Code" := PlaybookCode;
        Condition."Step No." := StepNo;
        Condition."Condition Type" := "Playbook Cond. Type ori"::Success;
        Condition."Group No." := 1;
        Condition."Line No." := 10000;
        Condition.Path := Path;
        Condition.Operator := Operator;
        Condition.Value := Value;
        Condition.Insert(true);
    end;

    var
        PlaybookExistsErr: Label 'Playbook %1 already exists. Choose a different plan code; generation never takes over an unrelated playbook.', Comment = '%1 = playbook code, is-IS=Keðjan %1 er þegar til. Veldu annan áætlunarkóða; myndun tekur aldrei yfir ótengda keðju.';
        CycleErr: Label 'Copy plan %1 occurs twice in the parent hierarchy.', Comment = '%1 = plan code, is-IS=Afritunaráætlunin %1 kemur tvisvar fyrir í stigveldinu.';
        NoFieldsErr: Label 'Copy plan %1 needs at least one active field mapping.', Comment = '%1 = plan code, is-IS=Afritunaráætlunin %1 þarf að minnsta kosti eina virka reitavörpun.';
        PageSizeErr: Label 'Page size must be between 1 and 500.', Comment = 'is-IS=Síðustærð verður að vera á milli 1 og 500.';
        DuplicateFieldErr: Label 'Destination field %1 is mapped more than once.', Comment = '%1 = field number, is-IS=Markreitnum %1 er varpað oftar en einu sinni.';
        MissingKeyErr: Label 'Map destination primary-key field %1 before generating the playbook.', Comment = '%1 = field name, is-IS=Varpaðu aðallykilsreitnum %1 í marktöflunni áður en keðjan er mynduð.';
        SystemFieldErr: Label 'System fields cannot be mapped by a copy plan.', Comment = 'is-IS=Ekki er hægt að varpa kerfisreitum með afritunaráætlun.';
}
