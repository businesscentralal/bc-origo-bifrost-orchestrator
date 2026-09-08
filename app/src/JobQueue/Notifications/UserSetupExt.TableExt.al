namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

tableextension 10035584 "User Setup Ext ori" extends "User Setup ori"
{
    fields
    {
        field(10035535; "Telegram Chat ID ori"; Text[50])
        {
            Caption = 'Telegram Chat ID', Comment = 'is-IS=Telegram spjallauðkenni';
            DataClassification = CustomerContent;
        }
    }
}
