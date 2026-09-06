namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

pageextension 10035584 "User Setup Ext ori" extends "User Setup Editor ori"
{
    layout
    {
        addafter("Location Code")
        {
            field("Telegram Chat ID ori"; Rec."Telegram Chat ID ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Telegram Chat ID for this user, used for Telegram notifications.', Comment = 'is-IS=Tilgreinir Telegram-spjallauðkenni þessa notanda, notað fyrir Telegram-tilkynningar.';
            }
        }
    }
}
