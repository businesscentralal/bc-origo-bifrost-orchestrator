namespace Origo.Bifrost.Orchestrator.Test;

/// <summary>Session state of the artifact mock: what storage serves and what the mock email target received.</summary>
codeunit 96461 "Artifact Mock State ori"
{
    SingleInstance = true;

    var
        ArtifactText: Text;
        SanitizeCap: Integer;
        EmailCount: Integer;
        SanitizeCount: Integer;
        AskCount: Integer;
        LastAttachmentText: Text;
        LastAskQuestion: Text;

    /// <summary>Resets the mock and sets the artifact the storage mock serves.</summary>
    /// <param name="NewArtifactText">The HTML text served by the storage mock.</param>
    /// <param name="NewSanitizeCap">The largest HTML text the sanitize mock accepts; 0 means no cap.</param>
    procedure Setup(NewArtifactText: Text; NewSanitizeCap: Integer)
    begin
        Reset();
        ArtifactText := NewArtifactText;
        SanitizeCap := NewSanitizeCap;
    end;

    /// <summary>Clears every counter and text.</summary>
    procedure Reset()
    begin
        Clear(ArtifactText);
        Clear(SanitizeCap);
        Clear(EmailCount);
        Clear(SanitizeCount);
        Clear(AskCount);
        Clear(LastAttachmentText);
        Clear(LastAskQuestion);
    end;

    procedure GetArtifactText(): Text
    begin
        exit(ArtifactText);
    end;

    procedure GetSanitizeCap(): Integer
    begin
        exit(SanitizeCap);
    end;

    procedure CountEmail(AttachmentText: Text)
    begin
        EmailCount += 1;
        LastAttachmentText := AttachmentText;
    end;

    procedure CountSanitize()
    begin
        SanitizeCount += 1;
    end;

    procedure CountAsk(Question: Text)
    begin
        AskCount += 1;
        LastAskQuestion := Question;
    end;

    procedure GetEmailCount(): Integer
    begin
        exit(EmailCount);
    end;

    procedure GetSanitizeCount(): Integer
    begin
        exit(SanitizeCount);
    end;

    procedure GetAskCount(): Integer
    begin
        exit(AskCount);
    end;

    procedure GetLastAttachmentText(): Text
    begin
        exit(LastAttachmentText);
    end;
}
