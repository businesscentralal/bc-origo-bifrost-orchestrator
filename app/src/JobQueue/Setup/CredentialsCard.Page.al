namespace Origo.Bifrost.Nornir;

using System.Utilities;

/// <summary>
/// Card page for one Client Credentials record. The client id and the client secret are never shown
/// or edited here: the page reports whether each value is stored in the Bifröst Foundation secret
/// store and offers Set and Clear actions that go through the shared masked dialog.
/// </summary>
page 10035545 "Credentials Card ori"
{
    Caption = 'Client Credentials Card', Comment = 'is-IS=Spjald auðkenni biðlara';
    ContextSensitiveHelpPage = 'credentials-card';
    PageType = Card;
    SourceTable = "Client Credentials ori";
    UsageCategory = None;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique code for this client credential pair.', Comment = 'is-IS=Tilgreinir einstæðan kóða fyrir þetta auðkennispar.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this client credential pair.', Comment = 'is-IS=Tilgreinir lýsingu á þessu auðkennispari.';
                }
            }
            group(SecretsGroup)
            {
                Caption = 'Secrets', Comment = 'is-IS=Leyndarmál';
                field(ClientIdStatusField; ClientIdStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Client ID', Comment = 'is-IS=Auðkenni biðlara';
                    Editable = false;
                    StyleExpr = ClientIdStyleExpr;
                    ToolTip = 'Specifies whether the OAuth 2.0 client id has been entered. Use Set Client ID to enter it.', Comment = 'is-IS=Tilgreinir hvort OAuth 2.0 biðlaraauðkenni hafi verið skráð. Notaðu Skrá auðkenni biðlara til að skrá það.';
                }
                field(ClientSecretStatusField; ClientSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret', Comment = 'is-IS=Leyniorð biðlara';
                    Editable = false;
                    StyleExpr = ClientSecretStyleExpr;
                    ToolTip = 'Specifies whether the OAuth 2.0 client secret has been entered. Use Set Client Secret to enter it.', Comment = 'is-IS=Tilgreinir hvort OAuth 2.0 leyniorð biðlara hafi verið skráð. Notaðu Skrá leyniorð biðlara til að skrá það.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(SecretActions)
            {
                Caption = 'Secrets', Comment = 'is-IS=Leyndarmál';
                Image = EncryptionKeys;
                action(SetClientId)
                {
                    ApplicationArea = All;
                    Caption = 'Set Client ID', Comment = 'is-IS=Skrá auðkenni biðlara';
                    Image = EncryptionKeys;
                    ToolTip = 'Enter the OAuth 2.0 client id. The value is stored in the Bifrost secret store and is never shown again.', Comment = 'is-IS=Skrá OAuth 2.0 biðlaraauðkenni. Gildið er geymt í leyndarmálageymslu Bifröst og er aldrei sýnt aftur.';

                    trigger OnAction()
                    begin
                        Rec.TestField(Code);
                        if Secrets.SetClientIdFromDialog(Rec.Code) then begin
                            RefreshStatus();
                            ShowSecretsMissingNotification();
                        end;
                    end;
                }
                action(SetClientSecret)
                {
                    ApplicationArea = All;
                    Caption = 'Set Client Secret', Comment = 'is-IS=Skrá leyniorð biðlara';
                    Image = EncryptionKeys;
                    ToolTip = 'Enter the OAuth 2.0 client secret. The value is stored in the Bifrost secret store and is never shown again.', Comment = 'is-IS=Skrá OAuth 2.0 leyniorð biðlara. Gildið er geymt í leyndarmálageymslu Bifröst og er aldrei sýnt aftur.';

                    trigger OnAction()
                    begin
                        Rec.TestField(Code);
                        if Secrets.SetClientSecretFromDialog(Rec.Code) then begin
                            RefreshStatus();
                            ShowSecretsMissingNotification();
                        end;
                    end;
                }
                action(ClearSecrets)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Secrets', Comment = 'is-IS=Hreinsa leyndarmál';
                    Image = ClearLog;
                    ToolTip = 'Remove the stored client id and client secret of this credential pair.', Comment = 'is-IS=Fjarlægja geymt biðlaraauðkenni og leyniorð biðlara fyrir þetta auðkennispar.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField(Code);
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmClearSecretsQst, Rec.Code), false) then
                            exit;
                        Secrets.ClearCredential(Rec.Code);
                        RefreshStatus();
                        ShowSecretsMissingNotification();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'is-IS=Vinna';

                actionref(SetClientId_Promoted; SetClientId) { }
                actionref(SetClientSecret_Promoted; SetClientSecret) { }
                actionref(ClearSecrets_Promoted; ClearSecrets) { }
            }
        }
    }

    var
        Secrets: Codeunit "Secrets ori";
        ClientIdStatus: Text;
        ClientIdStyleExpr: Text;
        ClientSecretStatus: Text;
        ClientSecretStyleExpr: Text;
        AttentionStyleTok: Label 'Unfavorable', Locked = true;
        ConfirmClearSecretsQst: Label 'Remove the stored client id and client secret of client credentials %1?', Comment = '%1 = client credentials code, is-IS=Fjarlægja geymt biðlaraauðkenni og leyniorð biðlara fyrir auðkenni biðlara %1?';
        FavorableStyleTok: Label 'Favorable', Locked = true;
        NotSetLbl: Label 'Not set', Comment = 'is-IS=Ekki skráð';
        SecretsMissingMsg: Label 'The client id and the client secret must be entered once. They are not copied from the published Origo Cloud Events Orchestrator application.', Comment = 'is-IS=Skrá verður biðlaraauðkenni og leyniorð biðlara einu sinni. Þau eru ekki afrituð úr útgefna forritinu Origo Cloud Events Orchestrator.';
        SetLbl: Label 'Set', Comment = 'is-IS=Skráð';

    trigger OnOpenPage()
    begin
        RefreshStatus();
        ShowSecretsMissingNotification();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshStatus();
    end;

    local procedure RefreshStatus()
    begin
        SetStatusText(Secrets.IsClientIdSet(Rec.Code), ClientIdStatus, ClientIdStyleExpr);
        SetStatusText(Secrets.IsClientSecretSet(Rec.Code), ClientSecretStatus, ClientSecretStyleExpr);
    end;

    local procedure SetStatusText(IsSet: Boolean; var StatusText: Text; var StyleExpr: Text)
    begin
        if IsSet then begin
            StatusText := SetLbl;
            StyleExpr := FavorableStyleTok;
            exit;
        end;
        StatusText := NotSetLbl;
        StyleExpr := AttentionStyleTok;
    end;

    local procedure ShowSecretsMissingNotification()
    var
        SecretsNotification: Notification;
    begin
        if Rec.Code = '' then
            exit;
        if Rec.IsComplete() then
            exit;

        SecretsNotification.Id := '5f6c1c9e-3f2e-4a41-9f5b-1c2b7d84a610';
        SecretsNotification.Scope := NotificationScope::LocalScope;
        SecretsNotification.Message := SecretsMissingMsg;
        SecretsNotification.Send();
    end;
}
