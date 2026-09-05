namespace Origo.Bifrost.Nornir;

/// <summary>
/// Full permission set for the Bifrost Nornir extension.
/// </summary>
permissionset 10035535 "BIFROST Nornir ori"
{
    Assignable = true;
    Caption = 'Bifrost Nornir', Comment = 'is-IS=Vinnsluraðari';
    Permissions = tabledata "Scheduled Entry ori" = R,
    tabledata "Scheduler Setup ori" = R,
    tabledata "Recurring Template ori" = R,
    tabledata "Client Credentials ori" = R,
    page "Scheduled Entry Card ori" = X;
}
