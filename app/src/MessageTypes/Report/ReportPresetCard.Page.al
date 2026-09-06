namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

page 10035591 "Report Preset Card ori"
{
    Caption = 'Report Request Preset', Comment = 'is-IS=Forsendur skýrslu';
    ContextSensitiveHelpPage = 'report-preset-card';
    PageType = Card;
    SourceTable = "Report Request Preset ori";
    Permissions = TableData "Report Request Preset ori" = RIMD;
    InsertAllowed = true;
    DeleteAllowed = true;
    UsageCategory = None;
    ShowFilter = false;

    DataCaptionExpression = DataCaptionText;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The report object ID.', Comment = 'is-IS=Auðkennisnúmer skýrsluhlutarins.';

                    trigger OnValidate()
                    var
                        AllObj: Record AllObjWithCaption;
                    begin
                        AllObj.SetLoadFields("Object Caption");
                        if AllObj.Get(AllObj."Object Type"::Report, Rec."Report ID") then begin
                            ReportCaptionText := AllObj."Object Caption";
                            if Rec.Description = '' then
                                Rec.Description := CopyStr(AllObj."Object Caption", 1, MaxStrLen(Rec.Description));
                        end;
                        UpdateDataCaption();
                    end;
                }
                field(ReportCaption; ReportCaptionText)
                {
                    ApplicationArea = All;
                    Caption = 'Report Caption', Comment = 'is-IS=Heiti skýrslu';
                    Editable = false;
                    ToolTip = 'The caption of the report.', Comment = 'is-IS=Heiti skýrslunnar.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Description of this preset.', Comment = 'is-IS=Lýsing á þessum forsendum.';
                }
                field(HasXml; Rec.HasRequestPageXml())
                {
                    ApplicationArea = All;
                    Caption = 'Has Request Page XML', Comment = 'is-IS=Beiðnisíðu-XML til staðar';
                    Editable = false;
                    ToolTip = 'Whether request page parameters have been captured.', Comment = 'is-IS=Hvort forsendur beiðnisíðu hafi verið vistaðar.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CaptureRequestPage)
            {
                ApplicationArea = All;
                Caption = 'Capture Request Page', Comment = 'is-IS=Vista forsendur';
                Image = Setup;
                ToolTip = 'Opens the report request page so you can configure filters and options, then saves the parameters.', Comment = 'is-IS=Opnar beiðnisíðu skýrslu svo hægt sé að stilla síur og valkosti og vistar þá forsendur.';
                Enabled = Rec."Report ID" <> 0;

                trigger OnAction()
                begin
                    CaptureFromRequestPage();
                end;
            }
            action(ClearPreset)
            {
                ApplicationArea = All;
                Caption = 'Clear Preset', Comment = 'is-IS=Hreinsa forsendur';
                Image = ClearFilter;
                ToolTip = 'Removes the saved request page parameters.', Comment = 'is-IS=Fjarlægir vistaðar forsendur beiðnisíðu.';

                trigger OnAction()
                begin
                    Clear(Rec."Request Page XML");
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CaptureRequestPageRef; CaptureRequestPage) { }
        }
    }

    trigger OnAfterGetRecord()
    var
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetLoadFields("Object Caption");
        if AllObj.Get(AllObj."Object Type"::Report, Rec."Report ID") then
            ReportCaptionText := AllObj."Object Caption"
        else
            ReportCaptionText := '';
        UpdateDataCaption();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."User Security ID" := UserSecurityId();
        UpdateDataCaption();
    end;

    local procedure UpdateDataCaption()
    begin
        if Rec."Report ID" <> 0 then
            DataCaptionText := StrSubstNo('%1 · %2', Rec."Report ID", ReportCaptionText)
        else
            DataCaptionText := EnterReportIdTok;
    end;

    local procedure CaptureFromRequestPage()
    var
        ExistingXml: Text;
        NewXml: Text;
        CancelledErr: Label 'Request page was cancelled.', Comment = 'is-IS=Hætt var við beiðnisíðu.';
    begin
        ExistingXml := Rec.GetRequestPageXml();
        NewXml := Report.RunRequestPage(Rec."Report ID", ExistingXml);
        if NewXml = '' then
            Error(CancelledErr);
        Rec.SetRequestPageXml(NewXml);
        Rec.Modify(true);
        CurrPage.Update(false);
    end;

    var
        ReportCaptionText: Text;
        DataCaptionText: Text;
        EnterReportIdTok: Label 'Enter a Report ID to begin', Comment = 'is-IS=Sláðu inn skýrsluauðkenni til að byrja';
}
