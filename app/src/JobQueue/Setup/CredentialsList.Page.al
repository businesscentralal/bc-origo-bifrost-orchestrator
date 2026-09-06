namespace Origo.Bifrost.Nornir;

/// <summary>
/// List page for managing Client Credentials records.
/// </summary>
page 10035546 "Credentials List ori"
{
    ApplicationArea = All;
    Caption = 'Client Credentials', Comment = 'is-IS=Auðkenni biðlara';
    ContextSensitiveHelpPage = 'credentials-list';
    PageType = List;
    SourceTable = "Client Credentials ori";
    UsageCategory = None;
    CardPageId = "Credentials Card ori";
    ShowFilter = false;
    Editable = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this client credential pair.', Comment = 'is-IS=Tilgreinir einstæðan kóða fyrir þetta auðkennispar.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this client credential pair.', Comment = 'is-IS=Tilgreinir lýsingu á ýessu auðkennispari.';
                }
            }
        }
    }
}
