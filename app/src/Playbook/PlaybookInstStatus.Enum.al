/// <summary>
/// Status enum for playbook execution instances.
/// </summary>
namespace Origo.Bifrost.Nornir;

enum 10035539 "Playbook Inst. Status ori"
{
    Extensible = false;
    Caption = 'Playbook Instan"Bifrost Status', Comment = 'is-IS=Staða keðjukeyrslu';

    value(0; Draft)
    {
        Caption = 'Draft', Comment = 'is-IS=Drög';
    }
    value(1; Running)
    {
        Caption = 'Running', Comment = 'is-IS=Í keyrslu';
    }
    value(2; Completed)
    {
        Caption = 'Completed', Comment = 'is-IS=Lokið';
    }
    value(3; Failed)
    {
        Caption = 'Failed', Comment = 'is-IS=Mistókst';
    }
    value(4; Cancelled)
    {
        Caption = 'Cancelled', Comment = 'is-IS=Hætt við';
    }
}
