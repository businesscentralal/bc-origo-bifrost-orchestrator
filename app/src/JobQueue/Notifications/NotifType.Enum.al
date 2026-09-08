/// <summary>
/// Notification type enum for the Job Queue Orchestrator with interface implementation.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

enum 10035535 "Notif. Type ori" implements "Notification ori"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None', Comment = 'is-IS=Engin';
        Implementation = "Notification ori" = "None Notification ori";
    }
    value(1; EMail)
    {
        Caption = 'EMail', Comment = 'is-IS=Tölvupóstur';
        Implementation = "Notification ori" = "Email Notification ori";
    }
    value(2; Telegram)
    {
        Caption = 'Telegram', Locked = true;
        Implementation = "Notification ori" = "Telegram Notif. ori";
    }
}
