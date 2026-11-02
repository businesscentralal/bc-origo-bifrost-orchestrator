namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// The worked examples of Help.Orchestrator.Get ("Worked Playbook Examples"), built step by step with the same
/// templates, conditions and gates the help prints. The templates are public functions so a test can check that the
/// help carries their base64 text.
/// </summary>
codeunit 96438 "Playbook Example Library ori"
{
    Access = Internal;

    var
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>
    /// Builds example 1 (CREDIT-CTRL): read customers (10), a Check per customer (30), a write per customer (40) and a notice (90).
    /// With <c>GateStepNo</c> 0 it is example 3, the anti-pattern.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    /// <param name="GateStepNo">Skip If Step Failed of step 40: 30 is the corrected shape, 0 the ungated write.</param>
    procedure BuildCreditControl(PlaybookCode: Code[20]; GateStepNo: Integer)
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", CreditReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", CreditDecideTemplate(), 10, 'result', 0);
        Lib.AddStep(PlaybookCode, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", CreditBlockTemplate(), 10, 'result', GateStepNo);
        Lib.AddStep(PlaybookCode, 90, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", CreditNoticeTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'noOfRecords>customerCount');
        Lib.SetNextSteps(PlaybookCode, 10, 30, 0);
        Lib.SetNextSteps(PlaybookCode, 30, 40, 40);
        Lib.SetNextSteps(PlaybookCode, 40, 90, 90);
        Lib.SetNextSteps(PlaybookCode, 90, 0, 0);
        Lib.SetExcludeFromRunStatus(PlaybookCode, 90);

        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCode, 10);
        Lib.AddStatusSuccessCondition(PlaybookCode, 30);
        Lib.AddNoOfRecordsCondition(PlaybookCode, 30);
        Lib.AddStatusSuccessCondition(PlaybookCode, 40);
        Lib.AddCondition(PlaybookCode, 90, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        Lib.AddStatusSuccessCondition(PlaybookCode, 90);
    end;

    /// <summary>
    /// Builds example 2 (OVERDUE-REPORT): count the customers with an overdue balance and send the number. No write step.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    procedure BuildOverdueReport(PlaybookCode: Code[20])
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", ReportReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", ReportNoticeTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'noOfRecords>overdueCount');
        Lib.SetNextSteps(PlaybookCode, 10, 20, 20);
        Lib.SetNextSteps(PlaybookCode, 20, 0, 0);

        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddCondition(PlaybookCode, 20, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        Lib.AddStatusSuccessCondition(PlaybookCode, 20);
    end;

    /// <summary>The request template of step 10 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditReadTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(Blocked=CONST( ))"}');
    end;

    /// <summary>The request template of step 30 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditDecideTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1],"tableView":"WHERE(No.=CONST(@_current.primaryKey.No_),Balance Due (LCY)=FILTER(>0))"}');
    end;

    /// <summary>The request template of step 40 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditBlockTemplate(): Text
    begin
        exit('{"tableName":"Customer","data":[{"id":"@_current.id","fields":{"Blocked":"Invoice"}}]}');
    end;

    /// <summary>The request template of step 90 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditNoticeTemplate(): Text
    begin
        exit('{"message":"Credit control: @10.customerCount customers checked, @_steps.40.items.succeeded blocked."}');
    end;

    /// <summary>The request template of step 10 of example 2.</summary>
    /// <returns>The JSON text.</returns>
    procedure ReportReadTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(Balance Due (LCY)=FILTER(>0))"}');
    end;

    /// <summary>The request template of step 20 of example 2.</summary>
    /// <returns>The JSON text.</returns>
    procedure ReportNoticeTemplate(): Text
    begin
        exit('{"message":"Customers with an overdue balance: @10.overdueCount"}');
    end;
}
