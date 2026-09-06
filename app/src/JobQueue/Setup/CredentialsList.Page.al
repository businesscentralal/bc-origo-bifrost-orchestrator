namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// List page for managing Client Credentials records. The Secrets column reports whether both the
/// client id and the client secret of the row have been entered in the Bifröst secret store.
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
                    ToolTip = 'Specifies a description for this client credential pair.', Comment = 'is-IS=Tilgreinir lýsingu á þessu auðkennispari.';
                }
                field(SecretsStatusField; SecretsStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secrets', Comment = 'is-IS=Leyndarmál';
                    Editable = false;
                    StyleExpr = SecretsStyleExpr;
                    ToolTip = 'Specifies whether both the client id and the client secret have been entered. Open the card to enter them.', Comment = 'is-IS=Tilgreinir hvort bæði biðlaraauðkenni og leyniorð biðlara hafi verið skráð. Opnaðu spjaldið til að skrá þau.';
                }
            }
        }
    }

    var
        SecretsStatus: Text;
        SecretsStyleExpr: Text;
        AttentionStyleTok: Label 'Unfavorable', Locked = true;
        FavorableStyleTok: Label 'Favorable', Locked = true;
        NotSetLbl: Label 'Not set', Comment = 'is-IS=Ekki skráð';
        SetLbl: Label 'Set', Comment = 'is-IS=Skráð';

    trigger OnAfterGetRecord()
    begin
        if Rec.IsComplete() then begin
            SecretsStatus := SetLbl;
            SecretsStyleExpr := FavorableStyleTok;
            exit;
        end;
        SecretsStatus := NotSetLbl;
        SecretsStyleExpr := AttentionStyleTok;
    end;
}
