namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>
/// Issue #189: stand-in for an irreversible type. Without expectedCount it answers ConfirmationRequired with the
/// configured preview in <c>expected</c> (the shape Foundation answers, observed on Purchase.Document.Post); with the
/// matching expectedCount it "executes" by counting the call; with another count it refuses. It changes no data, so a
/// test proves exactly how often the irreversible part ran.
/// </summary>
codeunit 96488 "Preview Count Fixture Msg ori" implements "Msg Interface ori"
{
    SingleInstance = true;

    var
        PreviewText: Text;
        AnswersWithoutConfirmation: Boolean;
        ExecutedCalls: Integer;
        PreviewCalls: Integer;
        LastConfirmedCount: Integer;
        ConfirmationFormatTok: Label '{"status":"Error","code":"ConfirmationRequired","error":"This call cannot be undone and was not run. Nothing was changed.","parameter":"expectedCount","expected":%1,"nextStep":"Send the same request again with expectedCount."}', Locked = true;
        ConfirmationNoCountTok: Label '{"status":"Error","code":"ConfirmationRequired","error":"This call cannot be undone and was not run. Nothing was changed.","parameter":"expectedCount","nextStep":"Send the same request again with expectedCount."}', Locked = true;
        MismatchTok: Label '{"status":"Error","code":"ConfirmationMismatch","error":"expectedCount does not match the count of this call. Nothing was changed.","parameter":"expectedCount"}', Locked = true;

    /// <summary>Sets the answer for the next calls and clears the counters.</summary>
    /// <param name="NewPreview">The JSON value of expected, for example 3 or "3"; empty leaves expected out.</param>
    /// <param name="NewAnswersWithoutConfirmation">True makes the type execute without asking for a confirmation.</param>
    procedure Configure(NewPreview: Text; NewAnswersWithoutConfirmation: Boolean)
    begin
        PreviewText := NewPreview;
        AnswersWithoutConfirmation := NewAnswersWithoutConfirmation;
        ExecutedCalls := 0;
        PreviewCalls := 0;
        LastConfirmedCount := -1;
    end;

    /// <summary>The number of times the irreversible part ran.</summary>
    /// <returns>The executed calls since Configure.</returns>
    procedure Executed(): Integer
    begin
        exit(ExecutedCalls);
    end;

    /// <summary>The number of calls that answered ConfirmationRequired.</summary>
    /// <returns>The preview calls since Configure.</returns>
    procedure Previews(): Integer
    begin
        exit(PreviewCalls);
    end;

    /// <summary>The expectedCount of the last executed call.</summary>
    /// <returns>The confirmed count, or -1 when none ran.</returns>
    procedure ConfirmedCount(): Integer
    begin
        exit(LastConfirmedCount);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Test-only irreversible stand-in');
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Request: JsonObject;
        CountToken: JsonToken;
        Sent: Integer;
    begin
        Request := Argument.GetRequestJson();
        if AnswersWithoutConfirmation or Request.Get('expectedCount', CountToken) then begin
            if not AnswersWithoutConfirmation then begin
                Sent := CountToken.AsValue().AsInteger();
                if Format(Sent) <> DelChr(PreviewText, '=', '"') then begin
                    Argument.SetResponseText(MismatchTok);
                    exit;
                end;
                LastConfirmedCount := Sent;
            end;
            ExecutedCalls += 1;
            Argument.SetResponseText('{"status":"Success","executed":true}');
            exit;
        end;
        PreviewCalls += 1;
        if PreviewText = '' then
            Argument.SetResponseText(ConfirmationNoCountTok)
        else
            Argument.SetResponseText(StrSubstNo(ConfirmationFormatTok, PreviewText));
    end;
}
