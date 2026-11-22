namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Progress dialog of Copy Table Data. Does nothing when there is no UI (job queue, tests)
/// (port of Tools for Power Users "Copy Table Progress Dialog").
/// </summary>
codeunit 10035580 "Copy Table Progress Dialog ori"
{
    Access = Public;

    var
        WindowUpdateDateTime: DateTime;
        ProgressWindow: Dialog;
        CurrentRecCount: Integer;
        WindowOpen: Boolean;
        ProgressCopyCountMaxMsg: Label 'Copying #1###### #2###### out of #3#######', Comment = '#1######=Type of object copied; #2######=amount copied; #3#######=total amount to copy, is-IS=Afritar #1###### #2###### af #3#######';
        ProgressCopyCountMsg: Label 'Copying #1###### #2######', Comment = '#1######=Type of object copied; #2######=amount copied, is-IS=Afritar #1###### #2######';

    /// <summary>Opens the dialog without a total.</summary>
    /// <param name="Type">What is copied.</param>
    procedure OpenCopyCount(Type: Text)
    begin
        CurrentRecCount := 0;
        if GuiAllowed() then begin
            ProgressWindow.Open(ProgressCopyCountMsg, Type, CurrentRecCount);
            WindowOpen := true;
        end;
        WindowUpdateDateTime := CurrentDateTime();
    end;

    /// <summary>Opens the dialog with a total.</summary>
    /// <param name="Type">What is copied.</param>
    /// <param name="MaxCount">The number of records to copy.</param>
    procedure OpenCopyCountMax(Type: Text; MaxCount: Integer)
    begin
        CurrentRecCount := 0;
        if GuiAllowed() then begin
            ProgressWindow.Open(ProgressCopyCountMaxMsg, Type, CurrentRecCount, MaxCount);
            WindowOpen := true;
        end;
        WindowUpdateDateTime := CurrentDateTime();
    end;

    /// <summary>Counts one more copied record.</summary>
    procedure UpdateCopyCount()
    begin
        CurrentRecCount += 1;
        if CurrentDateTime() - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime();
            if WindowOpen then
                ProgressWindow.Update(2, CurrentRecCount);
            OnAfterProgressUpdate(CurrentRecCount);
        end;
    end;

    /// <summary>Shows what is being copied.</summary>
    /// <param name="Type">What is copied.</param>
    procedure UpdateType(Type: Text)
    begin
        if WindowOpen then
            ProgressWindow.Update(1, Type);
    end;

    /// <summary>Returns the number of records counted so far.</summary>
    /// <returns>The copy count.</returns>
    procedure GetCopyCount(): Integer
    begin
        exit(CurrentRecCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProgressUpdate(CurrentRecCount: Integer)
    begin
    end;
}
