/// <summary>
/// Operators for evaluating playbook step success conditions against response JSON values.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

enum 10035538 "Playbook Cond. Operator ori"
{
    Extensible = false;
    Caption = 'Playbook Condition Operator', Comment = 'is-IS=Virkni keðjuskilyrðis';

    value(0; Equals)
    {
        Caption = 'Equals', Comment = 'is-IS=Jafnt';
    }
    value(1; NotEquals)
    {
        Caption = 'Not Equals', Comment = 'is-IS=Ekki jafnt';
    }
    value(2; GreaterThan)
    {
        Caption = 'Greater Than', Comment = 'is-IS=Stærra en';
    }
    value(3; LessThan)
    {
        Caption = 'Less Than', Comment = 'is-IS=Minna en';
    }
    value(4; GreaterOrEqual)
    {
        Caption = 'Greater or Equal', Comment = 'is-IS=Stærra eða jafnt';
    }
    value(5; LessOrEqual)
    {
        Caption = 'Less or Equal', Comment = 'is-IS=Minna eða jafnt';
    }
    value(6; Contains)
    {
        Caption = 'Contains', Comment = 'is-IS=Inniheldur';
    }
    value(7; Exists)
    {
        Caption = 'Exists', Comment = 'is-IS=Er til';
    }
}
