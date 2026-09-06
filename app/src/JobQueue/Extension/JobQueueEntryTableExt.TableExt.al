namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>
/// Extends the Job Queue Entry table with the Bifrost Orchestrator scheduling flag.
/// </summary>
tableextension 10035535 "JobQueueEntry.TableExt ori" extends "Job Queue Entry"
{
    fields
    {
        field(10035535; "Scheduler Enabled ori"; Boolean)
        {
            CalcFormula = exist("Scheduled Entry ori" where(ID = field(ID)));
            Caption = 'Scheduler Enabled', Comment = 'is-IS=Tímaröðun virk';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
