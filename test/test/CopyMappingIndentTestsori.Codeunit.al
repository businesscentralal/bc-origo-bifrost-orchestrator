namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// #266 regression: the AA0214 fix in Copy Table Mapping keeps the recursive indentation. Linking a mapping under a root saves the
/// new Indentation on the re-parented mapping and on the grandchild below it.
/// </summary>
codeunit 96459 "Copy Mapping Indent Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Linking a mapping that has a child under a root mapping indents it to 1 and its child to 2.</summary>
    [Test]
    procedure LinkUnderRootIndentsChildAndGrandchild()
    var
        RootMapping: Record "Copy Table Mapping ori";
        ChildMapping: Record "Copy Table Mapping ori";
        GrandchildMapping: Record "Copy Table Mapping ori";
    begin
        ResetFixtures();
        // [GIVEN] A root mapping for the parent table, a child mapping for the child table that is not linked yet, and a
        // grandchild mapping under the child table
        CreateMapping(RootMapping, Database::"Test Copy Parent ori", 0);
        CreateMapping(ChildMapping, Database::"Test Copy Child ori", 0);
        CreateMapping(GrandchildMapping, Database::"Test Run Marker", Database::"Test Copy Child ori");
        ChildMapping.Find();
        GrandchildMapping.Find();
        Assert.AreEqual(0, ChildMapping.Indentation, 'The child mapping is a root before it is linked');
        Assert.AreEqual(1, GrandchildMapping.Indentation, 'The grandchild mapping is indented under the child');

        // [WHEN] The child mapping is linked under the root mapping
        ChildMapping."Parent Source Table ID" := Database::"Test Copy Parent ori";
        ChildMapping.Modify(true);

        // [THEN] The root stays at 0 and the new indentation of the whole chain below it is saved
        RootMapping.Find();
        ChildMapping.Find();
        GrandchildMapping.Find();
        Assert.AreEqual(0, RootMapping.Indentation, 'The root mapping is not indented');
        Assert.AreEqual(1, ChildMapping.Indentation, 'The child mapping is indented under the root');
        Assert.AreEqual(2, GrandchildMapping.Indentation, 'The grandchild mapping is indented under the child');

        GrandchildMapping.Delete(true);
        ChildMapping.Delete(true);
        RootMapping.Delete(true);
        ResetFixtures();
    end;

    local procedure CreateMapping(var Mapping: Record "Copy Table Mapping ori"; SourceTableId: Integer; ParentSourceTableId: Integer)
    begin
        Clear(Mapping);
        Mapping.Init();
        Mapping.ID := CreateGuid();
        Mapping.Validate("Source Table ID", SourceTableId);
        Mapping.Validate("Destination Table ID", SourceTableId);
        Mapping."Parent Source Table ID" := ParentSourceTableId;
        Mapping."Manual Copy" := true;
        Mapping.Insert(true);
    end;

    local procedure ResetFixtures()
    var
        Mapping: Record "Copy Table Mapping ori";
        FieldMapping: Record "Copy Field Mapping ori";
    begin
        Mapping.SetFilter("Source Table ID", '%1|%2|%3', Database::"Test Copy Parent ori", Database::"Test Copy Child ori", Database::"Test Run Marker");
        if Mapping.FindSet() then
            repeat
                FieldMapping.SetRange("Copy Table Mapping ID", Mapping.ID);
                FieldMapping.DeleteAll(false);
            until Mapping.Next() = 0;
        Mapping.DeleteAll(false);
    end;
}
