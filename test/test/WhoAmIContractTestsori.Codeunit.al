namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Checks the installed WhoAmI subscriber's public response contract for issue 63.</summary>
codeunit 96408 "WhoAmI Contract Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Building the real contract invokes the automatic subscriber exactly once.</summary>
    [Test]
    procedure TelegramFieldDescribesCallerSetup()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Response: JsonToken;
        Fields: JsonToken;
        Field: JsonToken;
        Value: JsonToken;
        Description: Text;
        Found: Integer;
    begin
        Assert.IsTrue(ContractMgt.GetContract("Message Type ori"::"Help.WhoAmI.Get", Contract), 'WhoAmI has a contract');
        Assert.IsTrue(Contract.Get('response', Response), 'Response chapter');
        Assert.IsTrue(Response.AsObject().Get('fields', Fields), 'Response fields');
        foreach Field in Fields.AsArray() do
            if Field.AsObject().Get('name', Value) then
                if Value.AsValue().AsText() = 'telegramChatId' then begin
                    Found += 1;
                    Assert.IsTrue(Field.AsObject().Get('type', Value), 'Field type');
                    Assert.AreEqual('string', Value.AsValue().AsText(), 'Telegram chat ID type');
                    Assert.IsTrue(Field.AsObject().Get('description', Value), 'Field description');
                    Description := Value.AsValue().AsText();
                    Assert.IsTrue(Description.Contains('calling user'), 'Caller-specific source');
                    Assert.IsTrue(Description.Contains('Bifrost user setup'), 'Setup source');
                    Assert.IsTrue(Description.Contains('empty string'), 'Missing value behavior');
                    Assert.IsTrue(Description.Contains('only while Bifrost Orchestrator is installed'), 'Installation scope');
                    Assert.IsTrue(Description.Contains('@_who.telegramChatId'), 'Playbook reference');
                end;
        Assert.AreEqual(1, Found, 'One field from the automatic installed subscriber');
        Assert.IsTrue(Contract.Contains('errors'), 'Foundation error chapter retained');
        Assert.IsTrue(Contract.Contains('metering'), 'Foundation metering chapter retained');
    end;
}
