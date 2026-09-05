/// <summary>
/// Permission set granting management access to the Bifrost Nornir.
/// </summary>
namespace Origo.Bifrost.Nornir;

permissionset 10035537 "BIFROST NrnMgt ori"
{
    Assignable = true;
    Caption = 'Bifrost Nornir Management', MaxLength = 30, Comment = 'is-IS=Stjórnun vinnsluraðara';
    Permissions =
        tabledata "Scheduled Entry ori" = RMID,
        tabledata "Scheduler Setup ori" = R,
        tabledata "Recurring Template ori" = R,
        tabledata "Client Credentials ori" = R,
        page "Scheduled Entry Card ori" = X;
}
