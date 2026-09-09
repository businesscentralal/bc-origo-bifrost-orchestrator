namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035599 "Report Layout Set Msg ori" implements "Msg Interface ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Creates or replaces a user-defined report layout via the BC layout import path.', Comment = 'is-IS=Býr til eða skiptir út notandaskilgreindu skýrsluútliti um innflutningsleið BC.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    begin
        Argument.SetResponseMarkdown(
            '# Orchestrator.ReportLayout.Set\n\n' +
            'Creates or replaces a **user-defined** tenant report layout from base64.\n\n' +
            'Uses the platform layout Media import path (`Tenant Report Layout`.Layout.ImportStream). ' +
            'Does **not** use Bifrost `Data.Records.Set` on tables 2000000232 / 2000000233.\n\n' +
            '## Request\n\n' +
            '```json\n' +
            '{\n' +
            '  "reportId": 1316,\n' +
            '  "name": "origo test",\n' +
            '  "layoutFormat": "Word",\n' +
            '  "layoutBase64": "...",\n' +
            '  "description": "optional",\n' +
            '  "companyName": ""\n' +
            '}\n' +
            '```\n\n' +
            '`setAsDefault` is deferred to `Orchestrator.ReportLayout.SetDefault` ' +
            '(codeunit *Report Layouts Impl.* SetDefault is Access=Internal).');
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSet(Argument);
    end;

    var
        Handler: Codeunit "Report Layout Handler ori";
}
