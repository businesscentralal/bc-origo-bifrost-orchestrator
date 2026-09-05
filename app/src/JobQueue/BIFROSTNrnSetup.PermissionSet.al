/// <summary>
/// Permission set granting setup access to the Bifrost Nornir.
/// </summary>
namespace Origo.Bifrost.Nornir;

permissionset 10035536 "BIFROST NrnSetup ori"
{
    Assignable = true;
    Caption = 'Bifrost Nornir Setup', MaxLength = 30, Comment = 'is-IS=Uppsetning vinnsluraðara';
    Permissions =
        tabledata "Scheduled Entry ori" = RMID,
        tabledata "Scheduler Setup ori" = RMID,
        tabledata "Recurring Template ori" = RIMD,
        tabledata "Client Credentials ori" = RIMD,
        page "Scheduled Entry Card ori" = X;
}
