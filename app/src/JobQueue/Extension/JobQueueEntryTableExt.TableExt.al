namespace Origo.Bifrost.Nornir;

using System.Threading;

/// <summary>
/// Extends the Job Queue Entry table with orchestrator-specific fields.
/// </summary>
tableextension 10035535 "JobQueueEntry.TableExt ori" extends "Job Queue Entry"
{
    fields
    {
        field(10035535; "Orchestrator Enabled ori"; Boolean)
        {
            CalcFormula = exist("Scheduled Entry ori" where(ID = field(ID)));
            Caption = 'Orchestrator Enabled', Comment = 'is-IS=Vinnsluraðari virk';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
