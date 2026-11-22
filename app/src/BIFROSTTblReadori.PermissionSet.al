/// <summary>
/// Read-only access to the Table Data Management pages (#261): a user with this set can open the pages, view and export table
/// data as JSON and Excel, but cannot edit, delete or import, because it grants only Read on "Table Data Access ori". The
/// Foundation read guards and the user's own table permissions apply on top.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

permissionset 10035540 "BIFROST TblRead ori"
{
    Caption = 'Bifrost Table Data Read', Comment = 'is-IS=Bifröst töflugögn lestur';
    Assignable = true;

    Permissions =
        tabledata "Table Data Access ori" = R,
        tabledata "Table Data Edit ori" = RIMD,
        table "Table Data Access ori" = X,
        table "Table Data Edit ori" = X,
        page "Table Data Management ori" = X,
        page "Table Data Editor ori" = X,
        page "Table Data Permissions ori" = X,
        codeunit "Table Data Mgt ori" = X,
        codeunit "Table JSON Export ori" = X,
        codeunit "Table Data Filter Mgt ori" = X,
        codeunit "Table Data Edit Mgt ori" = X,
        codeunit "Table Data JSON Mgt ori" = X,
        codeunit "Table Data Excel Export ori" = X;
}
