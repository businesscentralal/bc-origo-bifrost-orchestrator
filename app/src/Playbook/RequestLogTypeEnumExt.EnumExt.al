namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

/// <summary>
/// Adds the playbook request-log type so that steps executed by the playbook runner are
/// classified separately from the Bifrost Foundation log types.
/// </summary>
enumextension 10035605 "RequestLogType.EnumExt ori" extends "Request Log Type ori"
{
    value(10035605; "Nornir Playbook")
    {
        Caption = 'Nornir Playbook', Comment = 'is-IS=Bifröst keðja';
    }
}
