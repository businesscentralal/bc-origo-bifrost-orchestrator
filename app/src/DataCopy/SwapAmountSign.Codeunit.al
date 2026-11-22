namespace Origo.Bifrost.Orchestrator;

using System.IO;

/// <summary>
/// Transformation Rule type Swap Amount Sign: turns an amount into its negative, 100 into -100 and -100 into 100.
/// Text that is not a number is kept (port of Tools for Power Users "Swap Amount Sign").
/// </summary>
codeunit 10035577 "Swap Amount Sign ori" implements "Transformation Rule"
{
    Access = Public;

    /// <summary>Returns the value with its sign swapped.</summary>
    /// <param name="TransformationRule">The rule being applied.</param>
    /// <param name="OldValue">The amount as text, culture-invariant or in the current format.</param>
    /// <param name="NewValue">The amount with its sign swapped, culture-invariant.</param>
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text)
    var
        TempAmount: Decimal;
    begin
        if OldValue = '' then
            NewValue := ''
        else
            if Evaluate(TempAmount, OldValue, 9) then
                NewValue := Format(-TempAmount, 0, 9)
            else
                if Evaluate(TempAmount, OldValue) then
                    NewValue := Format(-TempAmount, 0, 9)
                else
                    NewValue := OldValue;
    end;

    /// <summary>Swap Amount Sign has no data format settings.</summary>
    /// <returns>Always false.</returns>
    procedure IsDataFormatUpdateAllowed(): Boolean
    begin
        exit(false);
    end;

    /// <summary>Swap Amount Sign has no mandatory fields.</summary>
    /// <param name="TransformationRule">The rule being checked.</param>
    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule")
    begin
    end;

    /// <summary>Swap Amount Sign does not validate rule fields.</summary>
    /// <param name="FieldNo">The field being validated.</param>
    /// <param name="TransformationRule">The rule.</param>
    /// <param name="xTransformationRule">The rule before the change.</param>
    /// <returns>Always false.</returns>
    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean
    begin
        exit(false);
    end;

    /// <summary>Swap Amount Sign shows no extra field groups.</summary>
    /// <param name="TransformationRule">The rule.</param>
    /// <param name="VisibleTransformationRuleGroups">Unchanged.</param>
    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
    end;
}
