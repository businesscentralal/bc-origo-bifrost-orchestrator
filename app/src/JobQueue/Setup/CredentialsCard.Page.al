namespace Origo.Bifrost.Nornir;

using System.Utilities;

/// <summary>
/// Card page for viewing and editing a single Client Credentials record.
/// </summary>
page 10035545 "Credentials Card ori"
{
    Caption = 'Client Credentials Card', Comment = 'is-IS=Spjald auðkenni biðlara';
    ContextSensitiveHelpPage = 'Credentials Card ori".html';
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
                    ToolTip = 'Specifies a description for this client credential pair.', Comment = 'is-IS=Tilgreinir lýsingu á ýessu auðkennispari.';
                }
                field("Client ID"; ClientId)
                {
                    Caption = 'Client ID', Comment = 'is-IS=Auðkenni biðlara';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the client identifier.', Comment = 'is-IS=Tilgreinir auðkenni biðlarans.';
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        if (ClientId <> SecrectContentLbl) and (ClientId <> '') then begin
                            Rec.SetClientId(ClientId);
                            ClientId := SecrectContentLbl;
                        end;
                    end;
                }
                field("Client Secret"; ClientSecret)
                {
                    Caption = 'Client Secret', Comment = 'is-IS=Leyniorð biðlara';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the client secret.', Comment = 'is-IS=Tilgreinir leyniorð biðlarans.';
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        if (ClientSecret <> SecrectContentLbl) and (ClientSecret <> '') then begin
                            Rec.SetClientSecret(ClientSecret);
                            ClientSecret := SecrectContentLbl;
                        end;
                    end;
                }
            }
        }
    }

    var
        [NonDebuggable]
        ClientId: Text;
        [NonDebuggable]
        ClientSecret: Text;
        SecrectContentLbl: Label '***', Locked = true;
        ConfirmClosePageQst: Label 'The Client ID and Client Secret must be provided. Do you want to exit without these information?', Comment = 'is-IS=Auðkenni og leyniorð biðlara verður að vera til staðar. Viltu loka án þessara upplýsinga?';

    trigger OnOpenPage()
    begin
        if not IsNullGuid(Rec."Client ID") then
            ClientId := SecrectContentLbl;
        if not IsNullGuid(Rec."Client Secret") then
            ClientSecret := SecrectContentLbl;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IsNullGuid(Rec."Client ID") or IsNullGuid(Rec."Client Secret") then
            exit(ConfirmManagement.GetResponseOrDefault(ConfirmClosePageQst, true));
    end;
}
