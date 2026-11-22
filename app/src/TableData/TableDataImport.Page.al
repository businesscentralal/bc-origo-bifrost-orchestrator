namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Worksheet page for previewing an Excel file before it is imported into a table (port of "Tools Import Table" from
/// Tools for Power Users, #261). The page only edits the in-memory sheet; the rows are written by "Table Data Excel Import ori"
/// through Foundation's guards. The original "Skip Record Validation" option is not ported: Foundation offers no guarded equivalent.
/// </summary>
page 10035629 "Table Data Import ori"
{
    ApplicationArea = All;
    Caption = 'Import Table', Comment = 'is-IS=Flytja inn töflu';
    DataCaptionExpression = ThisPageCaption;
    DeleteAllowed = false;
    Extensible = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Integer";
    SourceTableTemporary = true;
    UsageCategory = None;
    ContextSensitiveHelpPage = 'playbooks';
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Field1; MatrixCellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    Editable = Field1Editable;
                    StyleExpr = Field1Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field1Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(1);
                    end;
                }
                field(Field2; MatrixCellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    Editable = Field2Editable;
                    StyleExpr = Field2Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field2Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(2);
                    end;
                }
                field(Field3; MatrixCellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    Editable = Field3Editable;
                    StyleExpr = Field3Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field3Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(3);
                    end;
                }
                field(Field4; MatrixCellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    Editable = Field4Editable;
                    StyleExpr = Field4Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field4Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(4);
                    end;
                }
                field(Field5; MatrixCellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    Editable = Field5Editable;
                    StyleExpr = Field5Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field5Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(5);
                    end;
                }
                field(Field6; MatrixCellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    Editable = Field6Editable;
                    StyleExpr = Field6Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field6Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(6);
                    end;
                }
                field(Field7; MatrixCellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    Editable = Field7Editable;
                    StyleExpr = Field7Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field7Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(7);
                    end;
                }
                field(Field8; MatrixCellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    Editable = Field8Editable;
                    StyleExpr = Field8Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field8Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(8);
                    end;
                }
                field(Field9; MatrixCellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    Editable = Field9Editable;
                    StyleExpr = Field9Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field9Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(9);
                    end;
                }
                field(Field10; MatrixCellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    Editable = Field10Editable;
                    StyleExpr = Field10Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field10Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(10);
                    end;
                }
                field(Field11; MatrixCellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    Editable = Field11Editable;
                    StyleExpr = Field11Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field11Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(11);
                    end;
                }
                field(Field12; MatrixCellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    Editable = Field12Editable;
                    StyleExpr = Field12Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field12Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(12);
                    end;
                }
                field(Field13; MatrixCellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    Editable = Field13Editable;
                    StyleExpr = Field13Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field13Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(13);
                    end;
                }
                field(Field14; MatrixCellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    Editable = Field14Editable;
                    StyleExpr = Field14Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field14Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(14);
                    end;
                }
                field(Field15; MatrixCellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    Editable = Field15Editable;
                    StyleExpr = Field15Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field15Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(15);
                    end;
                }
                field(Field16; MatrixCellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    Editable = Field16Editable;
                    StyleExpr = Field16Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field16Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(16);
                    end;
                }
                field(Field17; MatrixCellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    Editable = Field17Editable;
                    StyleExpr = Field17Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field17Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(17);
                    end;
                }
                field(Field18; MatrixCellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    Editable = Field18Editable;
                    StyleExpr = Field18Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field18Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(18);
                    end;
                }
                field(Field19; MatrixCellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    Editable = Field19Editable;
                    StyleExpr = Field19Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field19Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(19);
                    end;
                }
                field(Field20; MatrixCellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    Editable = Field20Editable;
                    StyleExpr = Field20Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field20Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(20);
                    end;
                }
                field(Field21; MatrixCellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    Editable = Field21Editable;
                    StyleExpr = Field21Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field21Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(21);
                    end;
                }
                field(Field22; MatrixCellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    Editable = Field22Editable;
                    StyleExpr = Field22Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field22Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(22);
                    end;
                }
                field(Field23; MatrixCellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    Editable = Field23Editable;
                    StyleExpr = Field23Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field23Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(23);
                    end;
                }
                field(Field24; MatrixCellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    Editable = Field24Editable;
                    StyleExpr = Field24Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field24Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(24);
                    end;
                }
                field(Field25; MatrixCellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    Editable = Field25Editable;
                    StyleExpr = Field25Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field25Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(25);
                    end;
                }
                field(Field26; MatrixCellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    Editable = Field26Editable;
                    StyleExpr = Field26Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field26Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(26);
                    end;
                }
                field(Field27; MatrixCellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    Editable = Field27Editable;
                    StyleExpr = Field27Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field27Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(27);
                    end;
                }
                field(Field28; MatrixCellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    Editable = Field28Editable;
                    StyleExpr = Field28Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field28Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(28);
                    end;
                }
                field(Field29; MatrixCellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    Editable = Field29Editable;
                    StyleExpr = Field29Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field29Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(29);
                    end;
                }
                field(Field30; MatrixCellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    Editable = Field30Editable;
                    StyleExpr = Field30Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field30Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(30);
                    end;
                }
                field(Field31; MatrixCellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    Editable = Field31Editable;
                    StyleExpr = Field31Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field31Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(31);
                    end;
                }
                field(Field32; MatrixCellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    Editable = Field32Editable;
                    StyleExpr = Field32Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field32Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(32);
                    end;
                }
                field(Field33; MatrixCellData[33])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[33];
                    Editable = Field33Editable;
                    StyleExpr = Field33Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field33Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(33);
                    end;
                }
                field(Field34; MatrixCellData[34])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[34];
                    Editable = Field34Editable;
                    StyleExpr = Field34Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field34Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(34);
                    end;
                }
                field(Field35; MatrixCellData[35])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[35];
                    Editable = Field35Editable;
                    StyleExpr = Field35Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field35Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(35);
                    end;
                }
                field(Field36; MatrixCellData[36])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[36];
                    Editable = Field36Editable;
                    StyleExpr = Field36Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field36Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(36);
                    end;
                }
                field(Field37; MatrixCellData[37])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[37];
                    Editable = Field37Editable;
                    StyleExpr = Field37Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field37Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(37);
                    end;
                }
                field(Field38; MatrixCellData[38])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[38];
                    Editable = Field38Editable;
                    StyleExpr = Field38Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field38Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(38);
                    end;
                }
                field(Field39; MatrixCellData[39])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[39];
                    Editable = Field39Editable;
                    StyleExpr = Field39Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field39Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(39);
                    end;
                }
                field(Field40; MatrixCellData[40])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[40];
                    Editable = Field40Editable;
                    StyleExpr = Field40Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field40Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(40);
                    end;
                }
                field(Field41; MatrixCellData[41])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[41];
                    Editable = Field41Editable;
                    StyleExpr = Field41Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field41Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(41);
                    end;
                }
                field(Field42; MatrixCellData[42])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[42];
                    Editable = Field42Editable;
                    StyleExpr = Field42Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field42Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(42);
                    end;
                }
                field(Field43; MatrixCellData[43])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[43];
                    Editable = Field43Editable;
                    StyleExpr = Field43Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field43Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(43);
                    end;
                }
                field(Field44; MatrixCellData[44])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[44];
                    Editable = Field44Editable;
                    StyleExpr = Field44Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field44Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(44);
                    end;
                }
                field(Field45; MatrixCellData[45])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[45];
                    Editable = Field45Editable;
                    StyleExpr = Field45Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field45Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(45);
                    end;
                }
                field(Field46; MatrixCellData[46])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[46];
                    Editable = Field46Editable;
                    StyleExpr = Field46Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field46Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(46);
                    end;
                }
                field(Field47; MatrixCellData[47])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[47];
                    Editable = Field47Editable;
                    StyleExpr = Field47Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field47Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(47);
                    end;
                }
                field(Field48; MatrixCellData[48])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[48];
                    Editable = Field48Editable;
                    StyleExpr = Field48Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field48Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(48);
                    end;
                }
                field(Field49; MatrixCellData[49])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[49];
                    Editable = Field49Editable;
                    StyleExpr = Field49Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field49Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(49);
                    end;
                }
                field(Field50; MatrixCellData[50])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[50];
                    Editable = Field50Editable;
                    StyleExpr = Field50Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field50Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(50);
                    end;
                }
                field(Field51; MatrixCellData[51])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[51];
                    Editable = Field51Editable;
                    StyleExpr = Field51Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field51Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(51);
                    end;
                }
                field(Field52; MatrixCellData[52])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[52];
                    Editable = Field52Editable;
                    StyleExpr = Field52Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field52Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(52);
                    end;
                }
                field(Field53; MatrixCellData[53])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[53];
                    Editable = Field53Editable;
                    StyleExpr = Field53Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field53Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(53);
                    end;
                }
                field(Field54; MatrixCellData[54])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[54];
                    Editable = Field54Editable;
                    StyleExpr = Field54Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field54Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(54);
                    end;
                }
                field(Field55; MatrixCellData[55])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[55];
                    Editable = Field55Editable;
                    StyleExpr = Field55Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field55Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(55);
                    end;
                }
                field(Field56; MatrixCellData[56])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[56];
                    Editable = Field56Editable;
                    StyleExpr = Field56Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field56Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(56);
                    end;
                }
                field(Field57; MatrixCellData[57])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[57];
                    Editable = Field57Editable;
                    StyleExpr = Field57Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field57Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(57);
                    end;
                }
                field(Field58; MatrixCellData[58])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[58];
                    Editable = Field58Editable;
                    StyleExpr = Field58Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field58Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(58);
                    end;
                }
                field(Field59; MatrixCellData[59])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[59];
                    Editable = Field59Editable;
                    StyleExpr = Field59Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field59Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(59);
                    end;
                }
                field(Field60; MatrixCellData[60])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[60];
                    Editable = Field60Editable;
                    StyleExpr = Field60Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field60Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(60);
                    end;
                }
                field(Field61; MatrixCellData[61])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[61];
                    Editable = Field61Editable;
                    StyleExpr = Field61Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field61Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(61);
                    end;
                }
                field(Field62; MatrixCellData[62])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[62];
                    Editable = Field62Editable;
                    StyleExpr = Field62Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field62Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(62);
                    end;
                }
                field(Field63; MatrixCellData[63])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[63];
                    Editable = Field63Editable;
                    StyleExpr = Field63Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field63Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(63);
                    end;
                }
                field(Field64; MatrixCellData[64])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[64];
                    Editable = Field64Editable;
                    StyleExpr = Field64Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field64Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(64);
                    end;
                }
                field(Field65; MatrixCellData[65])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[65];
                    Editable = Field65Editable;
                    StyleExpr = Field65Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field65Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(65);
                    end;
                }
                field(Field66; MatrixCellData[66])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[66];
                    Editable = Field66Editable;
                    StyleExpr = Field66Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field66Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(66);
                    end;
                }
                field(Field67; MatrixCellData[67])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[67];
                    Editable = Field67Editable;
                    StyleExpr = Field67Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field67Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(67);
                    end;
                }
                field(Field68; MatrixCellData[68])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[68];
                    Editable = Field68Editable;
                    StyleExpr = Field68Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field68Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(68);
                    end;
                }
                field(Field69; MatrixCellData[69])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[69];
                    Editable = Field69Editable;
                    StyleExpr = Field69Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field69Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(69);
                    end;
                }
                field(Field70; MatrixCellData[70])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[70];
                    Editable = Field70Editable;
                    StyleExpr = Field70Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field70Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(70);
                    end;
                }
                field(Field71; MatrixCellData[71])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[71];
                    Editable = Field71Editable;
                    StyleExpr = Field71Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field71Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(71);
                    end;
                }
                field(Field72; MatrixCellData[72])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[72];
                    Editable = Field72Editable;
                    StyleExpr = Field72Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field72Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(72);
                    end;
                }
                field(Field73; MatrixCellData[73])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[73];
                    Editable = Field73Editable;
                    StyleExpr = Field73Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field73Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(73);
                    end;
                }
                field(Field74; MatrixCellData[74])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[74];
                    Editable = Field74Editable;
                    StyleExpr = Field74Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field74Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(74);
                    end;
                }
                field(Field75; MatrixCellData[75])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[75];
                    Editable = Field75Editable;
                    StyleExpr = Field75Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field75Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(75);
                    end;
                }
                field(Field76; MatrixCellData[76])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[76];
                    Editable = Field76Editable;
                    StyleExpr = Field76Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field76Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(76);
                    end;
                }
                field(Field77; MatrixCellData[77])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[77];
                    Editable = Field77Editable;
                    StyleExpr = Field77Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field77Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(77);
                    end;
                }
                field(Field78; MatrixCellData[78])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[78];
                    Editable = Field78Editable;
                    StyleExpr = Field78Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field78Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(78);
                    end;
                }
                field(Field79; MatrixCellData[79])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[79];
                    Editable = Field79Editable;
                    StyleExpr = Field79Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field79Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(79);
                    end;
                }
                field(Field80; MatrixCellData[80])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[80];
                    Editable = Field80Editable;
                    StyleExpr = Field80Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field80Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(80);
                    end;
                }
                field(Field81; MatrixCellData[81])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[81];
                    Editable = Field81Editable;
                    StyleExpr = Field81Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field81Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(81);
                    end;
                }
                field(Field82; MatrixCellData[82])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[82];
                    Editable = Field82Editable;
                    StyleExpr = Field82Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field82Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(82);
                    end;
                }
                field(Field83; MatrixCellData[83])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[83];
                    Editable = Field83Editable;
                    StyleExpr = Field83Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field83Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(83);
                    end;
                }
                field(Field84; MatrixCellData[84])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[84];
                    Editable = Field84Editable;
                    StyleExpr = Field84Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field84Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(84);
                    end;
                }
                field(Field85; MatrixCellData[85])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[85];
                    Editable = Field85Editable;
                    StyleExpr = Field85Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field85Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(85);
                    end;
                }
                field(Field86; MatrixCellData[86])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[86];
                    Editable = Field86Editable;
                    StyleExpr = Field86Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field86Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(86);
                    end;
                }
                field(Field87; MatrixCellData[87])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[87];
                    Editable = Field87Editable;
                    StyleExpr = Field87Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field87Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(87);
                    end;
                }
                field(Field88; MatrixCellData[88])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[88];
                    Editable = Field88Editable;
                    StyleExpr = Field88Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field88Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(88);
                    end;
                }
                field(Field89; MatrixCellData[89])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[89];
                    Editable = Field89Editable;
                    StyleExpr = Field89Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field89Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(89);
                    end;
                }
                field(Field90; MatrixCellData[90])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[90];
                    Editable = Field90Editable;
                    StyleExpr = Field90Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field90Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(90);
                    end;
                }
                field(Field91; MatrixCellData[91])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[91];
                    Editable = Field91Editable;
                    StyleExpr = Field91Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field91Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(91);
                    end;
                }
                field(Field92; MatrixCellData[92])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[92];
                    Editable = Field92Editable;
                    StyleExpr = Field92Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field92Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(92);
                    end;
                }
                field(Field93; MatrixCellData[93])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[93];
                    Editable = Field93Editable;
                    StyleExpr = Field93Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field93Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(93);
                    end;
                }
                field(Field94; MatrixCellData[94])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[94];
                    Editable = Field94Editable;
                    StyleExpr = Field94Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field94Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(94);
                    end;
                }
                field(Field95; MatrixCellData[95])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[95];
                    Editable = Field95Editable;
                    StyleExpr = Field95Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field95Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(95);
                    end;
                }
                field(Field96; MatrixCellData[96])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[96];
                    Editable = Field96Editable;
                    StyleExpr = Field96Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field96Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(96);
                    end;
                }
                field(Field97; MatrixCellData[97])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[97];
                    Editable = Field97Editable;
                    StyleExpr = Field97Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field97Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(97);
                    end;
                }
                field(Field98; MatrixCellData[98])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[98];
                    Editable = Field98Editable;
                    StyleExpr = Field98Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field98Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(98);
                    end;
                }
                field(Field99; MatrixCellData[99])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[99];
                    Editable = Field99Editable;
                    StyleExpr = Field99Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field99Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(99);
                    end;
                }
                field(Field100; MatrixCellData[100])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[100];
                    Editable = Field100Editable;
                    StyleExpr = Field100Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field100Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(100);
                    end;
                }
                field(Field101; MatrixCellData[101])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[101];
                    Editable = Field101Editable;
                    StyleExpr = Field101Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field101Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(101);
                    end;
                }
                field(Field102; MatrixCellData[102])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[102];
                    Editable = Field102Editable;
                    StyleExpr = Field102Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field102Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(102);
                    end;
                }
                field(Field103; MatrixCellData[103])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[103];
                    Editable = Field103Editable;
                    StyleExpr = Field103Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field103Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(103);
                    end;
                }
                field(Field104; MatrixCellData[104])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[104];
                    Editable = Field104Editable;
                    StyleExpr = Field104Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field104Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(104);
                    end;
                }
                field(Field105; MatrixCellData[105])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[105];
                    Editable = Field105Editable;
                    StyleExpr = Field105Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field105Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(105);
                    end;
                }
                field(Field106; MatrixCellData[106])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[106];
                    Editable = Field106Editable;
                    StyleExpr = Field106Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field106Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(106);
                    end;
                }
                field(Field107; MatrixCellData[107])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[107];
                    Editable = Field107Editable;
                    StyleExpr = Field107Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field107Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(107);
                    end;
                }
                field(Field108; MatrixCellData[108])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[108];
                    Editable = Field108Editable;
                    StyleExpr = Field108Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field108Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(108);
                    end;
                }
                field(Field109; MatrixCellData[109])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[109];
                    Editable = Field109Editable;
                    StyleExpr = Field109Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field109Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(109);
                    end;
                }
                field(Field110; MatrixCellData[110])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[110];
                    Editable = Field110Editable;
                    StyleExpr = Field110Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field110Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(110);
                    end;
                }
                field(Field111; MatrixCellData[111])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[111];
                    Editable = Field111Editable;
                    StyleExpr = Field111Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field111Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(111);
                    end;
                }
                field(Field112; MatrixCellData[112])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[112];
                    Editable = Field112Editable;
                    StyleExpr = Field112Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field112Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(112);
                    end;
                }
                field(Field113; MatrixCellData[113])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[113];
                    Editable = Field113Editable;
                    StyleExpr = Field113Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field113Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(113);
                    end;
                }
                field(Field114; MatrixCellData[114])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[114];
                    Editable = Field114Editable;
                    StyleExpr = Field114Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field114Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(114);
                    end;
                }
                field(Field115; MatrixCellData[115])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[115];
                    Editable = Field115Editable;
                    StyleExpr = Field115Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field115Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(115);
                    end;
                }
                field(Field116; MatrixCellData[116])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[116];
                    Editable = Field116Editable;
                    StyleExpr = Field116Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field116Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(116);
                    end;
                }
                field(Field117; MatrixCellData[117])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[117];
                    Editable = Field117Editable;
                    StyleExpr = Field117Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field117Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(117);
                    end;
                }
                field(Field118; MatrixCellData[118])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[118];
                    Editable = Field118Editable;
                    StyleExpr = Field118Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field118Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(118);
                    end;
                }
                field(Field119; MatrixCellData[119])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[119];
                    Editable = Field119Editable;
                    StyleExpr = Field119Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field119Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(119);
                    end;
                }
                field(Field120; MatrixCellData[120])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[120];
                    Editable = Field120Editable;
                    StyleExpr = Field120Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field120Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(120);
                    end;
                }
                field(Field121; MatrixCellData[121])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[121];
                    Editable = Field121Editable;
                    StyleExpr = Field121Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field121Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(121);
                    end;
                }
                field(Field122; MatrixCellData[122])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[122];
                    Editable = Field122Editable;
                    StyleExpr = Field122Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field122Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(122);
                    end;
                }
                field(Field123; MatrixCellData[123])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[123];
                    Editable = Field123Editable;
                    StyleExpr = Field123Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field123Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(123);
                    end;
                }
                field(Field124; MatrixCellData[124])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[124];
                    Editable = Field124Editable;
                    StyleExpr = Field124Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field124Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(124);
                    end;
                }
                field(Field125; MatrixCellData[125])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[125];
                    Editable = Field125Editable;
                    StyleExpr = Field125Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field125Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(125);
                    end;
                }
                field(Field126; MatrixCellData[126])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[126];
                    Editable = Field126Editable;
                    StyleExpr = Field126Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field126Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(126);
                    end;
                }
                field(Field127; MatrixCellData[127])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[127];
                    Editable = Field127Editable;
                    StyleExpr = Field127Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field127Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(127);
                    end;
                }
                field(Field128; MatrixCellData[128])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[128];
                    Editable = Field128Editable;
                    StyleExpr = Field128Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field128Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(128);
                    end;
                }
                field(Field129; MatrixCellData[129])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[129];
                    Editable = Field129Editable;
                    StyleExpr = Field129Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field129Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(129);
                    end;
                }
                field(Field130; MatrixCellData[130])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[130];
                    Editable = Field130Editable;
                    StyleExpr = Field130Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field130Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(130);
                    end;
                }
                field(Field131; MatrixCellData[131])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[131];
                    Editable = Field131Editable;
                    StyleExpr = Field131Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field131Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(131);
                    end;
                }
                field(Field132; MatrixCellData[132])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[132];
                    Editable = Field132Editable;
                    StyleExpr = Field132Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field132Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(132);
                    end;
                }
                field(Field133; MatrixCellData[133])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[133];
                    Editable = Field133Editable;
                    StyleExpr = Field133Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field133Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(133);
                    end;
                }
                field(Field134; MatrixCellData[134])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[134];
                    Editable = Field134Editable;
                    StyleExpr = Field134Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field134Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(134);
                    end;
                }
                field(Field135; MatrixCellData[135])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[135];
                    Editable = Field135Editable;
                    StyleExpr = Field135Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field135Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(135);
                    end;
                }
                field(Field136; MatrixCellData[136])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[136];
                    Editable = Field136Editable;
                    StyleExpr = Field136Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field136Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(136);
                    end;
                }
                field(Field137; MatrixCellData[137])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[137];
                    Editable = Field137Editable;
                    StyleExpr = Field137Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field137Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(137);
                    end;
                }
                field(Field138; MatrixCellData[138])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[138];
                    Editable = Field138Editable;
                    StyleExpr = Field138Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field138Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(138);
                    end;
                }
                field(Field139; MatrixCellData[139])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[139];
                    Editable = Field139Editable;
                    StyleExpr = Field139Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field139Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(139);
                    end;
                }
                field(Field140; MatrixCellData[140])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[140];
                    Editable = Field140Editable;
                    StyleExpr = Field140Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field140Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(140);
                    end;
                }
                field(Field141; MatrixCellData[141])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[141];
                    Editable = Field141Editable;
                    StyleExpr = Field141Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field141Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(141);
                    end;
                }
                field(Field142; MatrixCellData[142])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[142];
                    Editable = Field142Editable;
                    StyleExpr = Field142Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field142Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(142);
                    end;
                }
                field(Field143; MatrixCellData[143])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[143];
                    Editable = Field143Editable;
                    StyleExpr = Field143Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field143Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(143);
                    end;
                }
                field(Field144; MatrixCellData[144])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[144];
                    Editable = Field144Editable;
                    StyleExpr = Field144Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field144Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(144);
                    end;
                }
                field(Field145; MatrixCellData[145])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[145];
                    Editable = Field145Editable;
                    StyleExpr = Field145Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field145Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(145);
                    end;
                }
                field(Field146; MatrixCellData[146])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[146];
                    Editable = Field146Editable;
                    StyleExpr = Field146Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field146Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(146);
                    end;
                }
                field(Field147; MatrixCellData[147])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[147];
                    Editable = Field147Editable;
                    StyleExpr = Field147Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field147Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(147);
                    end;
                }
                field(Field148; MatrixCellData[148])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[148];
                    Editable = Field148Editable;
                    StyleExpr = Field148Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field148Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(148);
                    end;
                }
                field(Field149; MatrixCellData[149])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[149];
                    Editable = Field149Editable;
                    StyleExpr = Field149Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field149Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(149);
                    end;
                }
                field(Field150; MatrixCellData[150])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[150];
                    Editable = Field150Editable;
                    StyleExpr = Field150Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field150Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(150);
                    end;
                }
                field(Field151; MatrixCellData[151])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[151];
                    Editable = Field151Editable;
                    StyleExpr = Field151Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field151Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(151);
                    end;
                }
                field(Field152; MatrixCellData[152])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[152];
                    Editable = Field152Editable;
                    StyleExpr = Field152Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field152Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(152);
                    end;
                }
                field(Field153; MatrixCellData[153])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[153];
                    Editable = Field153Editable;
                    StyleExpr = Field153Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field153Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(153);
                    end;
                }
                field(Field154; MatrixCellData[154])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[154];
                    Editable = Field154Editable;
                    StyleExpr = Field154Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field154Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(154);
                    end;
                }
                field(Field155; MatrixCellData[155])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[155];
                    Editable = Field155Editable;
                    StyleExpr = Field155Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field155Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(155);
                    end;
                }
                field(Field156; MatrixCellData[156])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[156];
                    Editable = Field156Editable;
                    StyleExpr = Field156Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field156Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(156);
                    end;
                }
                field(Field157; MatrixCellData[157])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[157];
                    Editable = Field157Editable;
                    StyleExpr = Field157Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field157Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(157);
                    end;
                }
                field(Field158; MatrixCellData[158])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[158];
                    Editable = Field158Editable;
                    StyleExpr = Field158Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field158Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(158);
                    end;
                }
                field(Field159; MatrixCellData[159])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[159];
                    Editable = Field159Editable;
                    StyleExpr = Field159Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field159Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(159);
                    end;
                }
                field(Field160; MatrixCellData[160])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[160];
                    Editable = Field160Editable;
                    StyleExpr = Field160Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field160Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(160);
                    end;
                }
                field(Field161; MatrixCellData[161])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[161];
                    Editable = Field161Editable;
                    StyleExpr = Field161Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field161Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(161);
                    end;
                }
                field(Field162; MatrixCellData[162])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[162];
                    Editable = Field162Editable;
                    StyleExpr = Field162Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field162Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(162);
                    end;
                }
                field(Field163; MatrixCellData[163])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[163];
                    Editable = Field163Editable;
                    StyleExpr = Field163Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field163Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(163);
                    end;
                }
                field(Field164; MatrixCellData[164])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[164];
                    Editable = Field164Editable;
                    StyleExpr = Field164Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field164Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(164);
                    end;
                }
                field(Field165; MatrixCellData[165])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[165];
                    Editable = Field165Editable;
                    StyleExpr = Field165Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field165Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(165);
                    end;
                }
                field(Field166; MatrixCellData[166])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[166];
                    Editable = Field166Editable;
                    StyleExpr = Field166Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field166Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(166);
                    end;
                }
                field(Field167; MatrixCellData[167])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[167];
                    Editable = Field167Editable;
                    StyleExpr = Field167Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field167Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(167);
                    end;
                }
                field(Field168; MatrixCellData[168])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[168];
                    Editable = Field168Editable;
                    StyleExpr = Field168Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field168Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(168);
                    end;
                }
                field(Field169; MatrixCellData[169])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[169];
                    Editable = Field169Editable;
                    StyleExpr = Field169Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field169Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(169);
                    end;
                }
                field(Field170; MatrixCellData[170])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[170];
                    Editable = Field170Editable;
                    StyleExpr = Field170Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field170Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(170);
                    end;
                }
                field(Field171; MatrixCellData[171])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[171];
                    Editable = Field171Editable;
                    StyleExpr = Field171Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field171Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(171);
                    end;
                }
                field(Field172; MatrixCellData[172])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[172];
                    Editable = Field172Editable;
                    StyleExpr = Field172Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field172Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(172);
                    end;
                }
                field(Field173; MatrixCellData[173])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[173];
                    Editable = Field173Editable;
                    StyleExpr = Field173Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field173Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(173);
                    end;
                }
                field(Field174; MatrixCellData[174])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[174];
                    Editable = Field174Editable;
                    StyleExpr = Field174Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field174Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(174);
                    end;
                }
                field(Field175; MatrixCellData[175])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[175];
                    Editable = Field175Editable;
                    StyleExpr = Field175Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field175Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(175);
                    end;
                }
                field(Field176; MatrixCellData[176])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[176];
                    Editable = Field176Editable;
                    StyleExpr = Field176Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field176Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(176);
                    end;
                }
                field(Field177; MatrixCellData[177])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[177];
                    Editable = Field177Editable;
                    StyleExpr = Field177Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field177Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(177);
                    end;
                }
                field(Field178; MatrixCellData[178])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[178];
                    Editable = Field178Editable;
                    StyleExpr = Field178Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field178Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(178);
                    end;
                }
                field(Field179; MatrixCellData[179])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[179];
                    Editable = Field179Editable;
                    StyleExpr = Field179Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field179Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(179);
                    end;
                }
                field(Field180; MatrixCellData[180])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[180];
                    Editable = Field180Editable;
                    StyleExpr = Field180Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field180Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(180);
                    end;
                }
                field(Field181; MatrixCellData[181])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[181];
                    Editable = Field181Editable;
                    StyleExpr = Field181Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field181Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(181);
                    end;
                }
                field(Field182; MatrixCellData[182])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[182];
                    Editable = Field182Editable;
                    StyleExpr = Field182Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field182Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(182);
                    end;
                }
                field(Field183; MatrixCellData[183])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[183];
                    Editable = Field183Editable;
                    StyleExpr = Field183Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field183Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(183);
                    end;
                }
                field(Field184; MatrixCellData[184])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[184];
                    Editable = Field184Editable;
                    StyleExpr = Field184Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field184Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(184);
                    end;
                }
                field(Field185; MatrixCellData[185])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[185];
                    Editable = Field185Editable;
                    StyleExpr = Field185Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field185Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(185);
                    end;
                }
                field(Field186; MatrixCellData[186])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[186];
                    Editable = Field186Editable;
                    StyleExpr = Field186Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field186Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(186);
                    end;
                }
                field(Field187; MatrixCellData[187])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[187];
                    Editable = Field187Editable;
                    StyleExpr = Field187Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field187Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(187);
                    end;
                }
                field(Field188; MatrixCellData[188])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[188];
                    Editable = Field188Editable;
                    StyleExpr = Field188Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field188Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(188);
                    end;
                }
                field(Field189; MatrixCellData[189])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[189];
                    Editable = Field189Editable;
                    StyleExpr = Field189Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field189Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(189);
                    end;
                }
                field(Field190; MatrixCellData[190])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[190];
                    Editable = Field190Editable;
                    StyleExpr = Field190Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field190Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(190);
                    end;
                }
                field(Field191; MatrixCellData[191])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[191];
                    Editable = Field191Editable;
                    StyleExpr = Field191Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field191Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(191);
                    end;
                }
                field(Field192; MatrixCellData[192])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[192];
                    Editable = Field192Editable;
                    StyleExpr = Field192Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field192Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(192);
                    end;
                }
                field(Field193; MatrixCellData[193])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[193];
                    Editable = Field193Editable;
                    StyleExpr = Field193Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field193Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(193);
                    end;
                }
                field(Field194; MatrixCellData[194])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[194];
                    Editable = Field194Editable;
                    StyleExpr = Field194Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field194Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(194);
                    end;
                }
                field(Field195; MatrixCellData[195])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[195];
                    Editable = Field195Editable;
                    StyleExpr = Field195Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field195Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(195);
                    end;
                }
                field(Field196; MatrixCellData[196])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[196];
                    Editable = Field196Editable;
                    StyleExpr = Field196Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field196Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(196);
                    end;
                }
                field(Field197; MatrixCellData[197])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[197];
                    Editable = Field197Editable;
                    StyleExpr = Field197Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field197Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(197);
                    end;
                }
                field(Field198; MatrixCellData[198])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[198];
                    Editable = Field198Editable;
                    StyleExpr = Field198Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field198Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(198);
                    end;
                }
                field(Field199; MatrixCellData[199])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[199];
                    Editable = Field199Editable;
                    StyleExpr = Field199Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field199Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(199);
                    end;
                }
                field(Field200; MatrixCellData[200])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[200];
                    Editable = Field200Editable;
                    StyleExpr = Field200Style;
                    ToolTip = 'Specifies the value to be imported into this field.', Comment = 'is-IS=Tilgreinir gildið sem flutt verður inn í töflureitinn.';
                    Visible = Field200Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(200);
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(ValidatedFieldsPart; "Validated Fields ori")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DeleteEntries)
            {
                ApplicationArea = All;
                Caption = 'Delete Selected Lines', Comment = 'is-IS=Eyða völdum línum';
                Image = DeleteRow;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Deletes the selected lines from the import data', Comment = 'is-IS=Eyðir völdum færslum úr innfluttum gögnum';
                trigger OnAction()
                var
                    TempSelectedEntries: Record "Integer" temporary;
                    DeleteQst: Label 'Delete %1 entries from %2 import data', Comment = '%1 = selected record count, %2 = table caption, is-IS=Eyða %1 færslum úr %2 innflutningsgögnum';
                begin
                    TempSelectedEntries.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempSelectedEntries);
                    if not Confirm(DeleteQst, false, TempSelectedEntries.Count, ThisPageCaption) then exit;
                    TempSelectedEntries.FindSet();
                    repeat
                        TempExcelBuffer.SetRange("Row No.", TempSelectedEntries.Number);
                        TempExcelBuffer.DeleteAll();
                    until TempSelectedEntries.Next() = 0;
                    TempSelectedEntries.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        SetFieldsVisibility(200);
    end;

    trigger OnOpenPage()
    var
    begin
        SetFieldsVisibility(GetFieldsCount());
        SetFieldsEditable();
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(MatrixCellData);
        GetColumnValues();
        SetStyle();
    end;

    trigger OnClosePage()
    begin
        ClearAll();
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempFieldErrors: Record "Excel Buffer" temporary;

        Field1Editable: Boolean;
        Field1Visible: Boolean;

        Field2Editable: Boolean;

        Field2Visible: Boolean;

        Field3Editable: Boolean;

        Field3Visible: Boolean;

        Field4Editable: Boolean;

        Field4Visible: Boolean;

        Field5Editable: Boolean;

        Field5Visible: Boolean;

        Field6Editable: Boolean;

        Field6Visible: Boolean;

        Field7Editable: Boolean;

        Field7Visible: Boolean;

        Field8Editable: Boolean;

        Field8Visible: Boolean;

        Field9Editable: Boolean;

        Field9Visible: Boolean;

        Field10Editable: Boolean;

        Field10Visible: Boolean;

        Field11Editable: Boolean;

        Field11Visible: Boolean;

        Field12Editable: Boolean;

        Field12Visible: Boolean;

        Field13Editable: Boolean;

        Field13Visible: Boolean;

        Field14Editable: Boolean;

        Field14Visible: Boolean;

        Field15Editable: Boolean;

        Field15Visible: Boolean;

        Field16Editable: Boolean;

        Field16Visible: Boolean;

        Field17Editable: Boolean;

        Field17Visible: Boolean;

        Field18Editable: Boolean;

        Field18Visible: Boolean;

        Field19Editable: Boolean;

        Field19Visible: Boolean;

        Field20Editable: Boolean;

        Field20Visible: Boolean;

        Field21Editable: Boolean;

        Field21Visible: Boolean;

        Field22Editable: Boolean;

        Field22Visible: Boolean;

        Field23Editable: Boolean;

        Field23Visible: Boolean;

        Field24Editable: Boolean;

        Field24Visible: Boolean;

        Field25Editable: Boolean;

        Field25Visible: Boolean;

        Field26Editable: Boolean;

        Field26Visible: Boolean;

        Field27Editable: Boolean;

        Field27Visible: Boolean;

        Field28Editable: Boolean;

        Field28Visible: Boolean;

        Field29Editable: Boolean;

        Field29Visible: Boolean;

        Field30Editable: Boolean;

        Field30Visible: Boolean;

        Field31Editable: Boolean;

        Field31Visible: Boolean;

        Field32Editable: Boolean;

        Field32Visible: Boolean;

        Field33Editable: Boolean;

        Field33Visible: Boolean;

        Field34Editable: Boolean;

        Field34Visible: Boolean;

        Field35Editable: Boolean;

        Field35Visible: Boolean;

        Field36Editable: Boolean;

        Field36Visible: Boolean;

        Field37Editable: Boolean;

        Field37Visible: Boolean;

        Field38Editable: Boolean;

        Field38Visible: Boolean;

        Field39Editable: Boolean;

        Field39Visible: Boolean;

        Field40Editable: Boolean;

        Field40Visible: Boolean;

        Field41Editable: Boolean;

        Field41Visible: Boolean;

        Field42Editable: Boolean;

        Field42Visible: Boolean;

        Field43Editable: Boolean;

        Field43Visible: Boolean;

        Field44Editable: Boolean;

        Field44Visible: Boolean;

        Field45Editable: Boolean;

        Field45Visible: Boolean;

        Field46Editable: Boolean;

        Field46Visible: Boolean;

        Field47Editable: Boolean;

        Field47Visible: Boolean;

        Field48Editable: Boolean;

        Field48Visible: Boolean;

        Field49Editable: Boolean;

        Field49Visible: Boolean;

        Field50Editable: Boolean;

        Field50Visible: Boolean;

        Field51Editable: Boolean;

        Field51Visible: Boolean;

        Field52Editable: Boolean;

        Field52Visible: Boolean;

        Field53Editable: Boolean;

        Field53Visible: Boolean;

        Field54Editable: Boolean;

        Field54Visible: Boolean;

        Field55Editable: Boolean;

        Field55Visible: Boolean;

        Field56Editable: Boolean;

        Field56Visible: Boolean;

        Field57Editable: Boolean;

        Field57Visible: Boolean;

        Field58Editable: Boolean;

        Field58Visible: Boolean;

        Field59Editable: Boolean;

        Field59Visible: Boolean;

        Field60Editable: Boolean;

        Field60Visible: Boolean;

        Field61Editable: Boolean;

        Field61Visible: Boolean;

        Field62Editable: Boolean;

        Field62Visible: Boolean;

        Field63Editable: Boolean;

        Field63Visible: Boolean;

        Field64Editable: Boolean;

        Field64Visible: Boolean;

        Field65Editable: Boolean;

        Field65Visible: Boolean;

        Field66Editable: Boolean;

        Field66Visible: Boolean;

        Field67Editable: Boolean;

        Field67Visible: Boolean;

        Field68Editable: Boolean;

        Field68Visible: Boolean;

        Field69Editable: Boolean;

        Field69Visible: Boolean;

        Field70Editable: Boolean;

        Field70Visible: Boolean;

        Field71Editable: Boolean;

        Field71Visible: Boolean;

        Field72Editable: Boolean;

        Field72Visible: Boolean;

        Field73Editable: Boolean;

        Field73Visible: Boolean;

        Field74Editable: Boolean;

        Field74Visible: Boolean;

        Field75Editable: Boolean;

        Field75Visible: Boolean;

        Field76Editable: Boolean;

        Field76Visible: Boolean;

        Field77Editable: Boolean;

        Field77Visible: Boolean;

        Field78Editable: Boolean;

        Field78Visible: Boolean;

        Field79Editable: Boolean;

        Field79Visible: Boolean;

        Field80Editable: Boolean;

        Field80Visible: Boolean;

        Field81Editable: Boolean;

        Field81Visible: Boolean;

        Field82Editable: Boolean;

        Field82Visible: Boolean;

        Field83Editable: Boolean;

        Field83Visible: Boolean;

        Field84Editable: Boolean;

        Field84Visible: Boolean;

        Field85Editable: Boolean;

        Field85Visible: Boolean;

        Field86Editable: Boolean;

        Field86Visible: Boolean;

        Field87Editable: Boolean;

        Field87Visible: Boolean;

        Field88Editable: Boolean;

        Field88Visible: Boolean;

        Field89Editable: Boolean;

        Field89Visible: Boolean;

        Field90Editable: Boolean;

        Field90Visible: Boolean;

        Field91Editable: Boolean;

        Field91Visible: Boolean;

        Field92Editable: Boolean;

        Field92Visible: Boolean;

        Field93Editable: Boolean;

        Field93Visible: Boolean;

        Field94Editable: Boolean;

        Field94Visible: Boolean;

        Field95Editable: Boolean;

        Field95Visible: Boolean;

        Field96Editable: Boolean;

        Field96Visible: Boolean;

        Field97Editable: Boolean;

        Field97Visible: Boolean;

        Field98Editable: Boolean;

        Field98Visible: Boolean;

        Field99Editable: Boolean;

        Field99Visible: Boolean;

        Field100Editable: Boolean;

        Field100Visible: Boolean;
        Field101Editable: Boolean;
        Field102Editable: Boolean;
        Field103Editable: Boolean;
        Field104Editable: Boolean;
        Field105Editable: Boolean;
        Field106Editable: Boolean;
        Field107Editable: Boolean;
        Field108Editable: Boolean;
        Field109Editable: Boolean;
        Field110Editable: Boolean;
        Field111Editable: Boolean;
        Field112Editable: Boolean;
        Field113Editable: Boolean;
        Field114Editable: Boolean;
        Field115Editable: Boolean;
        Field116Editable: Boolean;
        Field117Editable: Boolean;
        Field118Editable: Boolean;
        Field119Editable: Boolean;
        Field120Editable: Boolean;
        Field121Editable: Boolean;
        Field122Editable: Boolean;
        Field123Editable: Boolean;
        Field124Editable: Boolean;
        Field125Editable: Boolean;
        Field126Editable: Boolean;
        Field127Editable: Boolean;
        Field128Editable: Boolean;
        Field129Editable: Boolean;
        Field130Editable: Boolean;
        Field131Editable: Boolean;
        Field132Editable: Boolean;
        Field133Editable: Boolean;
        Field134Editable: Boolean;
        Field135Editable: Boolean;
        Field136Editable: Boolean;
        Field137Editable: Boolean;
        Field138Editable: Boolean;
        Field139Editable: Boolean;
        Field140Editable: Boolean;
        Field141Editable: Boolean;
        Field142Editable: Boolean;
        Field143Editable: Boolean;
        Field144Editable: Boolean;
        Field145Editable: Boolean;
        Field146Editable: Boolean;
        Field147Editable: Boolean;
        Field148Editable: Boolean;
        Field149Editable: Boolean;
        Field150Editable: Boolean;
        Field151Editable: Boolean;
        Field152Editable: Boolean;
        Field153Editable: Boolean;
        Field154Editable: Boolean;
        Field155Editable: Boolean;
        Field156Editable: Boolean;
        Field157Editable: Boolean;
        Field158Editable: Boolean;
        Field159Editable: Boolean;
        Field160Editable: Boolean;
        Field161Editable: Boolean;
        Field162Editable: Boolean;
        Field163Editable: Boolean;
        Field164Editable: Boolean;
        Field165Editable: Boolean;
        Field166Editable: Boolean;
        Field167Editable: Boolean;
        Field168Editable: Boolean;
        Field169Editable: Boolean;
        Field170Editable: Boolean;
        Field171Editable: Boolean;
        Field172Editable: Boolean;
        Field173Editable: Boolean;
        Field174Editable: Boolean;
        Field175Editable: Boolean;
        Field176Editable: Boolean;
        Field177Editable: Boolean;
        Field178Editable: Boolean;
        Field179Editable: Boolean;
        Field180Editable: Boolean;
        Field181Editable: Boolean;
        Field182Editable: Boolean;
        Field183Editable: Boolean;
        Field184Editable: Boolean;
        Field185Editable: Boolean;
        Field186Editable: Boolean;
        Field187Editable: Boolean;
        Field188Editable: Boolean;
        Field189Editable: Boolean;
        Field190Editable: Boolean;
        Field191Editable: Boolean;
        Field192Editable: Boolean;
        Field193Editable: Boolean;
        Field194Editable: Boolean;
        Field195Editable: Boolean;
        Field196Editable: Boolean;
        Field197Editable: Boolean;
        Field198Editable: Boolean;
        Field199Editable: Boolean;
        Field200Editable: Boolean;
        Field101Visible: Boolean;
        Field102Visible: Boolean;
        Field103Visible: Boolean;
        Field104Visible: Boolean;
        Field105Visible: Boolean;
        Field106Visible: Boolean;
        Field107Visible: Boolean;
        Field108Visible: Boolean;
        Field109Visible: Boolean;
        Field110Visible: Boolean;
        Field111Visible: Boolean;
        Field112Visible: Boolean;
        Field113Visible: Boolean;
        Field114Visible: Boolean;
        Field115Visible: Boolean;
        Field116Visible: Boolean;
        Field117Visible: Boolean;
        Field118Visible: Boolean;
        Field119Visible: Boolean;
        Field120Visible: Boolean;
        Field121Visible: Boolean;
        Field122Visible: Boolean;
        Field123Visible: Boolean;
        Field124Visible: Boolean;
        Field125Visible: Boolean;
        Field126Visible: Boolean;
        Field127Visible: Boolean;
        Field128Visible: Boolean;
        Field129Visible: Boolean;
        Field130Visible: Boolean;
        Field131Visible: Boolean;
        Field132Visible: Boolean;
        Field133Visible: Boolean;
        Field134Visible: Boolean;
        Field135Visible: Boolean;
        Field136Visible: Boolean;
        Field137Visible: Boolean;
        Field138Visible: Boolean;
        Field139Visible: Boolean;
        Field140Visible: Boolean;
        Field141Visible: Boolean;
        Field142Visible: Boolean;
        Field143Visible: Boolean;
        Field144Visible: Boolean;
        Field145Visible: Boolean;
        Field146Visible: Boolean;
        Field147Visible: Boolean;
        Field148Visible: Boolean;
        Field149Visible: Boolean;
        Field150Visible: Boolean;
        Field151Visible: Boolean;
        Field152Visible: Boolean;
        Field153Visible: Boolean;
        Field154Visible: Boolean;
        Field155Visible: Boolean;
        Field156Visible: Boolean;
        Field157Visible: Boolean;
        Field158Visible: Boolean;
        Field159Visible: Boolean;
        Field160Visible: Boolean;
        Field161Visible: Boolean;
        Field162Visible: Boolean;
        Field163Visible: Boolean;
        Field164Visible: Boolean;
        Field165Visible: Boolean;
        Field166Visible: Boolean;
        Field167Visible: Boolean;
        Field168Visible: Boolean;
        Field169Visible: Boolean;
        Field170Visible: Boolean;
        Field171Visible: Boolean;
        Field172Visible: Boolean;
        Field173Visible: Boolean;
        Field174Visible: Boolean;
        Field175Visible: Boolean;
        Field176Visible: Boolean;
        Field177Visible: Boolean;
        Field178Visible: Boolean;
        Field179Visible: Boolean;
        Field180Visible: Boolean;
        Field181Visible: Boolean;
        Field182Visible: Boolean;
        Field183Visible: Boolean;
        Field184Visible: Boolean;
        Field185Visible: Boolean;
        Field186Visible: Boolean;
        Field187Visible: Boolean;
        Field188Visible: Boolean;
        Field189Visible: Boolean;
        Field190Visible: Boolean;
        Field191Visible: Boolean;
        Field192Visible: Boolean;
        Field193Visible: Boolean;
        Field194Visible: Boolean;
        Field195Visible: Boolean;
        Field196Visible: Boolean;
        Field197Visible: Boolean;
        Field198Visible: Boolean;
        Field199Visible: Boolean;
        Field200Visible: Boolean;

        Field1Style: Text;

        Field2Style: Text;

        Field3Style: Text;

        Field4Style: Text;

        Field5Style: Text;

        Field6Style: Text;

        Field7Style: Text;

        Field8Style: Text;

        Field9Style: Text;

        Field10Style: Text;

        Field11Style: Text;

        Field12Style: Text;

        Field13Style: Text;

        Field14Style: Text;

        Field15Style: Text;

        Field16Style: Text;

        Field17Style: Text;

        Field18Style: Text;

        Field19Style: Text;

        Field20Style: Text;

        Field21Style: Text;

        Field22Style: Text;

        Field23Style: Text;

        Field24Style: Text;

        Field25Style: Text;

        Field26Style: Text;

        Field27Style: Text;

        Field28Style: Text;

        Field29Style: Text;

        Field30Style: Text;

        Field31Style: Text;

        Field32Style: Text;

        Field33Style: Text;

        Field34Style: Text;

        Field35Style: Text;

        Field36Style: Text;

        Field37Style: Text;

        Field38Style: Text;

        Field39Style: Text;

        Field40Style: Text;

        Field41Style: Text;

        Field42Style: Text;

        Field43Style: Text;

        Field44Style: Text;

        Field45Style: Text;

        Field46Style: Text;

        Field47Style: Text;

        Field48Style: Text;

        Field49Style: Text;

        Field50Style: Text;

        Field51Style: Text;

        Field52Style: Text;

        Field53Style: Text;

        Field54Style: Text;

        Field55Style: Text;

        Field56Style: Text;

        Field57Style: Text;

        Field58Style: Text;

        Field59Style: Text;

        Field60Style: Text;

        Field61Style: Text;

        Field62Style: Text;

        Field63Style: Text;

        Field64Style: Text;

        Field65Style: Text;

        Field66Style: Text;

        Field67Style: Text;

        Field68Style: Text;

        Field69Style: Text;

        Field70Style: Text;

        Field71Style: Text;

        Field72Style: Text;

        Field73Style: Text;

        Field74Style: Text;

        Field75Style: Text;

        Field76Style: Text;

        Field77Style: Text;

        Field78Style: Text;

        Field79Style: Text;

        Field80Style: Text;

        Field81Style: Text;

        Field82Style: Text;

        Field83Style: Text;

        Field84Style: Text;

        Field85Style: Text;

        Field86Style: Text;

        Field87Style: Text;

        Field88Style: Text;

        Field89Style: Text;

        Field90Style: Text;

        Field91Style: Text;

        Field92Style: Text;

        Field93Style: Text;

        Field94Style: Text;

        Field95Style: Text;

        Field96Style: Text;

        Field97Style: Text;

        Field98Style: Text;

        Field99Style: Text;

        Field100Style: Text;
        Field101Style: Text;
        Field102Style: Text;
        Field103Style: Text;
        Field104Style: Text;
        Field105Style: Text;
        Field106Style: Text;
        Field107Style: Text;
        Field108Style: Text;
        Field109Style: Text;
        Field110Style: Text;
        Field111Style: Text;
        Field112Style: Text;
        Field113Style: Text;
        Field114Style: Text;
        Field115Style: Text;
        Field116Style: Text;
        Field117Style: Text;
        Field118Style: Text;
        Field119Style: Text;
        Field120Style: Text;
        Field121Style: Text;
        Field122Style: Text;
        Field123Style: Text;
        Field124Style: Text;
        Field125Style: Text;
        Field126Style: Text;
        Field127Style: Text;
        Field128Style: Text;
        Field129Style: Text;
        Field130Style: Text;
        Field131Style: Text;
        Field132Style: Text;
        Field133Style: Text;
        Field134Style: Text;
        Field135Style: Text;
        Field136Style: Text;
        Field137Style: Text;
        Field138Style: Text;
        Field139Style: Text;
        Field140Style: Text;
        Field141Style: Text;
        Field142Style: Text;
        Field143Style: Text;
        Field144Style: Text;
        Field145Style: Text;
        Field146Style: Text;
        Field147Style: Text;
        Field148Style: Text;
        Field149Style: Text;
        Field150Style: Text;
        Field151Style: Text;
        Field152Style: Text;
        Field153Style: Text;
        Field154Style: Text;
        Field155Style: Text;
        Field156Style: Text;
        Field157Style: Text;
        Field158Style: Text;
        Field159Style: Text;
        Field160Style: Text;
        Field161Style: Text;
        Field162Style: Text;
        Field163Style: Text;
        Field164Style: Text;
        Field165Style: Text;
        Field166Style: Text;
        Field167Style: Text;
        Field168Style: Text;
        Field169Style: Text;
        Field170Style: Text;
        Field171Style: Text;
        Field172Style: Text;
        Field173Style: Text;
        Field174Style: Text;
        Field175Style: Text;
        Field176Style: Text;
        Field177Style: Text;
        Field178Style: Text;
        Field179Style: Text;
        Field180Style: Text;
        Field181Style: Text;
        Field182Style: Text;
        Field183Style: Text;
        Field184Style: Text;
        Field185Style: Text;
        Field186Style: Text;
        Field187Style: Text;
        Field188Style: Text;
        Field189Style: Text;
        Field190Style: Text;
        Field191Style: Text;
        Field192Style: Text;
        Field193Style: Text;
        Field194Style: Text;
        Field195Style: Text;
        Field196Style: Text;
        Field197Style: Text;
        Field198Style: Text;
        Field199Style: Text;
        Field200Style: Text;
        MatrixColumnCaptions: array[1000] of Text[100];
        MatrixCellData: array[1000] of Text[250];
        ThisPageCaption: Text[1024];

    /// <summary>
    /// Builds the column caption array by resolving field numbers from TempFieldMapping back to field captions for the given table.
    /// </summary>
    /// <param name="TableID">The ID of the table whose fields to look up.</param>
    /// <param name="TempFieldMapping">The mapping linking Excel column positions to field numbers.</param>
    procedure LoadColumnCaptions(TableID: Integer; var TempFieldMapping: Record "Line Number Buffer")
    var
        TableField: Record "Field";
    begin
        Clear(MatrixColumnCaptions);
        TableField.SetRange(TableNo, TableID);
        TableField.SetRange(Class, TableField.Class::Normal);
        TableField.SetRange(Enabled, true);
        TableField.SetRange(ObsoleteState, TableField.ObsoleteState::No);
        TempExcelBuffer.SetRange("Row No.", 1);
        if TempFieldMapping.FindSet() then
            repeat
                TableField.SetRange("No.", TempFieldMapping."New Line Number");
                TableField.FindFirst();
                MatrixColumnCaptions[TempFieldMapping."Old Line Number"] := TableField."Field Caption";
            until TempFieldMapping.Next() = 0;
    end;

    /// <summary>
    /// Refreshes the Validated Fields FactBox, showing which fields have validation enabled for the import.
    /// </summary>
    /// <param name="TableID">The ID of the table being imported.</param>
    /// <param name="TempFieldMapping">The mapping of Excel columns to field numbers.</param>
    /// <param name="FieldValidateBuffer">An Integer record containing field numbers that have validation enabled.</param>
    procedure LoadFactbox(TableID: Integer; var TempFieldMapping: Record "Line Number Buffer"; var FieldValidateBuffer: Record "Integer")
    begin
        CurrPage.ValidatedFieldsPart.Page.Load(TableID, TempFieldMapping, FieldValidateBuffer);
    end;

    /// <summary>
    /// Populates the page's temporary source records with rows from the Excel buffer, setting the page caption and making rows available for preview.
    /// </summary>
    /// <param name="ExcelBuffer">The Excel Buffer containing the imported spreadsheet data.</param>
    /// <param name="FieldErrors">An Excel Buffer containing any field-level import errors to highlight.</param>
    /// <param name="TableCaption">The table caption shown in the page header.</param>
    /// <param name="LastRowNo">The last Excel row number containing data.</param>
    procedure LoadRows(var ExcelBuffer: Record "Excel Buffer"; var FieldErrors: Record "Excel Buffer"; TableCaption: Text[1024]; LastRowNo: Integer)
    var
        Row: Record "Integer";
    begin
        ThisPageCaption := TableCaption;
        TempExcelBuffer.Copy(ExcelBuffer, true);
        TempFieldErrors.Copy(FieldErrors, true);
        Row.SetRange(Number, 2, LastRowNo);
        if Row.FindSet() then
            repeat
                TempExcelBuffer.SetRange("Row No.", Row.Number);
                if not TempExcelBuffer.IsEmpty() then begin
                    Rec.Number := Row.Number;
                    Rec.Insert();
                end
            until Row.Next() = 0;
    end;

    local procedure GetColumnValues()
    begin
        TempExcelBuffer.SetRange("Row No.", Rec.Number);
        if TempExcelBuffer.FindSet() then
            repeat
                MatrixCellData[TempExcelBuffer."Column No."] := TempExcelBuffer."Cell Value as Text";
            until TempExcelBuffer.Next() = 0;
    end;

    local procedure GetFieldsCount(): Integer
    begin
        TempExcelBuffer.SetRange("Row No.", 1);
        exit(TempExcelBuffer.Count);
    end;

    local procedure GetFieldStyle(ColumnID: Integer): Text
    var
        UnfavorableTok: Label 'Unfavorable', Locked = true;
    begin
        if TempFieldErrors.Get(Rec.Number, ColumnID) then
            exit(UnfavorableTok);
    end;

    local procedure SetFieldsEditable()
    begin
        Field1Editable := true;
        Field2Editable := true;
        Field3Editable := true;
        Field4Editable := true;
        Field5Editable := true;
        Field6Editable := true;
        Field7Editable := true;
        Field8Editable := true;
        Field9Editable := true;
        Field10Editable := true;
        Field11Editable := true;
        Field12Editable := true;
        Field13Editable := true;
        Field14Editable := true;
        Field15Editable := true;
        Field16Editable := true;
        Field17Editable := true;
        Field18Editable := true;
        Field19Editable := true;
        Field20Editable := true;
        Field21Editable := true;
        Field22Editable := true;
        Field23Editable := true;
        Field24Editable := true;
        Field25Editable := true;
        Field26Editable := true;
        Field27Editable := true;
        Field28Editable := true;
        Field29Editable := true;
        Field30Editable := true;
        Field31Editable := true;
        Field32Editable := true;
        Field33Editable := true;
        Field34Editable := true;
        Field35Editable := true;
        Field36Editable := true;
        Field37Editable := true;
        Field38Editable := true;
        Field39Editable := true;
        Field40Editable := true;
        Field41Editable := true;
        Field42Editable := true;
        Field43Editable := true;
        Field44Editable := true;
        Field45Editable := true;
        Field46Editable := true;
        Field47Editable := true;
        Field48Editable := true;
        Field49Editable := true;
        Field50Editable := true;
        Field51Editable := true;
        Field52Editable := true;
        Field53Editable := true;
        Field54Editable := true;
        Field55Editable := true;
        Field56Editable := true;
        Field57Editable := true;
        Field58Editable := true;
        Field59Editable := true;
        Field60Editable := true;
        Field61Editable := true;
        Field62Editable := true;
        Field63Editable := true;
        Field64Editable := true;
        Field65Editable := true;
        Field66Editable := true;
        Field67Editable := true;
        Field68Editable := true;
        Field69Editable := true;
        Field70Editable := true;
        Field71Editable := true;
        Field72Editable := true;
        Field73Editable := true;
        Field74Editable := true;
        Field75Editable := true;
        Field76Editable := true;
        Field77Editable := true;
        Field78Editable := true;
        Field79Editable := true;
        Field80Editable := true;
        Field81Editable := true;
        Field82Editable := true;
        Field83Editable := true;
        Field84Editable := true;
        Field85Editable := true;
        Field86Editable := true;
        Field87Editable := true;
        Field88Editable := true;
        Field89Editable := true;
        Field90Editable := true;
        Field91Editable := true;
        Field92Editable := true;
        Field93Editable := true;
        Field94Editable := true;
        Field95Editable := true;
        Field96Editable := true;
        Field97Editable := true;
        Field98Editable := true;
        Field99Editable := true;
        Field100Editable := true;
        Field101Editable := true;
        Field102Editable := true;
        Field103Editable := true;
        Field104Editable := true;
        Field105Editable := true;
        Field106Editable := true;
        Field107Editable := true;
        Field108Editable := true;
        Field109Editable := true;
        Field110Editable := true;
        Field111Editable := true;
        Field112Editable := true;
        Field113Editable := true;
        Field114Editable := true;
        Field115Editable := true;
        Field116Editable := true;
        Field117Editable := true;
        Field118Editable := true;
        Field119Editable := true;
        Field120Editable := true;
        Field121Editable := true;
        Field122Editable := true;
        Field123Editable := true;
        Field124Editable := true;
        Field125Editable := true;
        Field126Editable := true;
        Field127Editable := true;
        Field128Editable := true;
        Field129Editable := true;
        Field130Editable := true;
        Field131Editable := true;
        Field132Editable := true;
        Field133Editable := true;
        Field134Editable := true;
        Field135Editable := true;
        Field136Editable := true;
        Field137Editable := true;
        Field138Editable := true;
        Field139Editable := true;
        Field140Editable := true;
        Field141Editable := true;
        Field142Editable := true;
        Field143Editable := true;
        Field144Editable := true;
        Field145Editable := true;
        Field146Editable := true;
        Field147Editable := true;
        Field148Editable := true;
        Field149Editable := true;
        Field150Editable := true;
        Field151Editable := true;
        Field152Editable := true;
        Field153Editable := true;
        Field154Editable := true;
        Field155Editable := true;
        Field156Editable := true;
        Field157Editable := true;
        Field158Editable := true;
        Field159Editable := true;
        Field160Editable := true;
        Field161Editable := true;
        Field162Editable := true;
        Field163Editable := true;
        Field164Editable := true;
        Field165Editable := true;
        Field166Editable := true;
        Field167Editable := true;
        Field168Editable := true;
        Field169Editable := true;
        Field170Editable := true;
        Field171Editable := true;
        Field172Editable := true;
        Field173Editable := true;
        Field174Editable := true;
        Field175Editable := true;
        Field176Editable := true;
        Field177Editable := true;
        Field178Editable := true;
        Field179Editable := true;
        Field180Editable := true;
        Field181Editable := true;
        Field182Editable := true;
        Field183Editable := true;
        Field184Editable := true;
        Field185Editable := true;
        Field186Editable := true;
        Field187Editable := true;
        Field188Editable := true;
        Field189Editable := true;
        Field190Editable := true;
        Field191Editable := true;
        Field192Editable := true;
        Field193Editable := true;
        Field194Editable := true;
        Field195Editable := true;
        Field196Editable := true;
        Field197Editable := true;
        Field198Editable := true;
        Field199Editable := true;
        Field200Editable := true;
    end;

    local procedure SetFieldsVisibility(NoOfFields: Integer)
    begin
        Field1Visible := NoOfFields >= 1;
        Field2Visible := NoOfFields >= 2;
        Field3Visible := NoOfFields >= 3;
        Field4Visible := NoOfFields >= 4;
        Field5Visible := NoOfFields >= 5;
        Field6Visible := NoOfFields >= 6;
        Field7Visible := NoOfFields >= 7;
        Field8Visible := NoOfFields >= 8;
        Field9Visible := NoOfFields >= 9;
        Field10Visible := NoOfFields >= 10;
        Field11Visible := NoOfFields >= 11;
        Field12Visible := NoOfFields >= 12;
        Field13Visible := NoOfFields >= 13;
        Field14Visible := NoOfFields >= 14;
        Field15Visible := NoOfFields >= 15;
        Field16Visible := NoOfFields >= 16;
        Field17Visible := NoOfFields >= 17;
        Field18Visible := NoOfFields >= 18;
        Field19Visible := NoOfFields >= 19;
        Field20Visible := NoOfFields >= 20;
        Field21Visible := NoOfFields >= 21;
        Field22Visible := NoOfFields >= 22;
        Field23Visible := NoOfFields >= 23;
        Field24Visible := NoOfFields >= 24;
        Field25Visible := NoOfFields >= 25;
        Field26Visible := NoOfFields >= 26;
        Field27Visible := NoOfFields >= 27;
        Field28Visible := NoOfFields >= 28;
        Field29Visible := NoOfFields >= 29;
        Field30Visible := NoOfFields >= 30;
        Field31Visible := NoOfFields >= 31;
        Field32Visible := NoOfFields >= 32;
        Field33Visible := NoOfFields >= 33;
        Field34Visible := NoOfFields >= 34;
        Field35Visible := NoOfFields >= 35;
        Field36Visible := NoOfFields >= 36;
        Field37Visible := NoOfFields >= 37;
        Field38Visible := NoOfFields >= 38;
        Field39Visible := NoOfFields >= 39;
        Field40Visible := NoOfFields >= 40;
        Field41Visible := NoOfFields >= 41;
        Field42Visible := NoOfFields >= 42;
        Field43Visible := NoOfFields >= 43;
        Field44Visible := NoOfFields >= 44;
        Field45Visible := NoOfFields >= 45;
        Field46Visible := NoOfFields >= 46;
        Field47Visible := NoOfFields >= 47;
        Field48Visible := NoOfFields >= 48;
        Field49Visible := NoOfFields >= 49;
        Field50Visible := NoOfFields >= 50;
        Field51Visible := NoOfFields >= 51;
        Field52Visible := NoOfFields >= 52;
        Field53Visible := NoOfFields >= 53;
        Field54Visible := NoOfFields >= 54;
        Field55Visible := NoOfFields >= 55;
        Field56Visible := NoOfFields >= 56;
        Field57Visible := NoOfFields >= 57;
        Field58Visible := NoOfFields >= 58;
        Field59Visible := NoOfFields >= 59;
        Field60Visible := NoOfFields >= 60;
        Field61Visible := NoOfFields >= 61;
        Field62Visible := NoOfFields >= 62;
        Field63Visible := NoOfFields >= 63;
        Field64Visible := NoOfFields >= 64;
        Field65Visible := NoOfFields >= 65;
        Field66Visible := NoOfFields >= 66;
        Field67Visible := NoOfFields >= 67;
        Field68Visible := NoOfFields >= 68;
        Field69Visible := NoOfFields >= 69;
        Field70Visible := NoOfFields >= 70;
        Field71Visible := NoOfFields >= 71;
        Field72Visible := NoOfFields >= 72;
        Field73Visible := NoOfFields >= 73;
        Field74Visible := NoOfFields >= 74;
        Field75Visible := NoOfFields >= 75;
        Field76Visible := NoOfFields >= 76;
        Field77Visible := NoOfFields >= 77;
        Field78Visible := NoOfFields >= 78;
        Field79Visible := NoOfFields >= 79;
        Field80Visible := NoOfFields >= 80;
        Field81Visible := NoOfFields >= 81;
        Field82Visible := NoOfFields >= 82;
        Field83Visible := NoOfFields >= 83;
        Field84Visible := NoOfFields >= 84;
        Field85Visible := NoOfFields >= 85;
        Field86Visible := NoOfFields >= 86;
        Field87Visible := NoOfFields >= 87;
        Field88Visible := NoOfFields >= 88;
        Field89Visible := NoOfFields >= 89;
        Field90Visible := NoOfFields >= 90;
        Field91Visible := NoOfFields >= 91;
        Field92Visible := NoOfFields >= 92;
        Field93Visible := NoOfFields >= 93;
        Field94Visible := NoOfFields >= 94;
        Field95Visible := NoOfFields >= 95;
        Field96Visible := NoOfFields >= 96;
        Field97Visible := NoOfFields >= 97;
        Field98Visible := NoOfFields >= 98;
        Field99Visible := NoOfFields >= 99;
        Field100Visible := NoOfFields >= 100;
        Field101Visible := NoOfFields >= 101;
        Field102Visible := NoOfFields >= 102;
        Field103Visible := NoOfFields >= 103;
        Field104Visible := NoOfFields >= 104;
        Field105Visible := NoOfFields >= 105;
        Field106Visible := NoOfFields >= 106;
        Field107Visible := NoOfFields >= 107;
        Field108Visible := NoOfFields >= 108;
        Field109Visible := NoOfFields >= 109;
        Field110Visible := NoOfFields >= 110;
        Field111Visible := NoOfFields >= 111;
        Field112Visible := NoOfFields >= 112;
        Field113Visible := NoOfFields >= 113;
        Field114Visible := NoOfFields >= 114;
        Field115Visible := NoOfFields >= 115;
        Field116Visible := NoOfFields >= 116;
        Field117Visible := NoOfFields >= 117;
        Field118Visible := NoOfFields >= 118;
        Field119Visible := NoOfFields >= 119;
        Field120Visible := NoOfFields >= 120;
        Field121Visible := NoOfFields >= 121;
        Field122Visible := NoOfFields >= 122;
        Field123Visible := NoOfFields >= 123;
        Field124Visible := NoOfFields >= 124;
        Field125Visible := NoOfFields >= 125;
        Field126Visible := NoOfFields >= 126;
        Field127Visible := NoOfFields >= 127;
        Field128Visible := NoOfFields >= 128;
        Field129Visible := NoOfFields >= 129;
        Field130Visible := NoOfFields >= 130;
        Field131Visible := NoOfFields >= 131;
        Field132Visible := NoOfFields >= 132;
        Field133Visible := NoOfFields >= 133;
        Field134Visible := NoOfFields >= 134;
        Field135Visible := NoOfFields >= 135;
        Field136Visible := NoOfFields >= 136;
        Field137Visible := NoOfFields >= 137;
        Field138Visible := NoOfFields >= 138;
        Field139Visible := NoOfFields >= 139;
        Field140Visible := NoOfFields >= 140;
        Field141Visible := NoOfFields >= 141;
        Field142Visible := NoOfFields >= 142;
        Field143Visible := NoOfFields >= 143;
        Field144Visible := NoOfFields >= 144;
        Field145Visible := NoOfFields >= 145;
        Field146Visible := NoOfFields >= 146;
        Field147Visible := NoOfFields >= 147;
        Field148Visible := NoOfFields >= 148;
        Field149Visible := NoOfFields >= 149;
        Field150Visible := NoOfFields >= 150;
        Field151Visible := NoOfFields >= 151;
        Field152Visible := NoOfFields >= 152;
        Field153Visible := NoOfFields >= 153;
        Field154Visible := NoOfFields >= 154;
        Field155Visible := NoOfFields >= 155;
        Field156Visible := NoOfFields >= 156;
        Field157Visible := NoOfFields >= 157;
        Field158Visible := NoOfFields >= 158;
        Field159Visible := NoOfFields >= 159;
        Field160Visible := NoOfFields >= 160;
        Field161Visible := NoOfFields >= 161;
        Field162Visible := NoOfFields >= 162;
        Field163Visible := NoOfFields >= 163;
        Field164Visible := NoOfFields >= 164;
        Field165Visible := NoOfFields >= 165;
        Field166Visible := NoOfFields >= 166;
        Field167Visible := NoOfFields >= 167;
        Field168Visible := NoOfFields >= 168;
        Field169Visible := NoOfFields >= 169;
        Field170Visible := NoOfFields >= 170;
        Field171Visible := NoOfFields >= 171;
        Field172Visible := NoOfFields >= 172;
        Field173Visible := NoOfFields >= 173;
        Field174Visible := NoOfFields >= 174;
        Field175Visible := NoOfFields >= 175;
        Field176Visible := NoOfFields >= 176;
        Field177Visible := NoOfFields >= 177;
        Field178Visible := NoOfFields >= 178;
        Field179Visible := NoOfFields >= 179;
        Field180Visible := NoOfFields >= 180;
        Field181Visible := NoOfFields >= 181;
        Field182Visible := NoOfFields >= 182;
        Field183Visible := NoOfFields >= 183;
        Field184Visible := NoOfFields >= 184;
        Field185Visible := NoOfFields >= 185;
        Field186Visible := NoOfFields >= 186;
        Field187Visible := NoOfFields >= 187;
        Field188Visible := NoOfFields >= 188;
        Field189Visible := NoOfFields >= 189;
        Field190Visible := NoOfFields >= 190;
        Field191Visible := NoOfFields >= 191;
        Field192Visible := NoOfFields >= 192;
        Field193Visible := NoOfFields >= 193;
        Field194Visible := NoOfFields >= 194;
        Field195Visible := NoOfFields >= 195;
        Field196Visible := NoOfFields >= 196;
        Field197Visible := NoOfFields >= 197;
        Field198Visible := NoOfFields >= 198;
        Field199Visible := NoOfFields >= 199;
        Field200Visible := NoOfFields >= 200;
    end;

    local procedure SetStyle()
    begin
        Field1Style := GetFieldStyle(1);
        Field2Style := GetFieldStyle(2);
        Field3Style := GetFieldStyle(3);
        Field4Style := GetFieldStyle(4);
        Field5Style := GetFieldStyle(5);
        Field6Style := GetFieldStyle(6);
        Field7Style := GetFieldStyle(7);
        Field8Style := GetFieldStyle(8);
        Field9Style := GetFieldStyle(9);
        Field10Style := GetFieldStyle(10);
        Field11Style := GetFieldStyle(11);
        Field12Style := GetFieldStyle(12);
        Field13Style := GetFieldStyle(13);
        Field14Style := GetFieldStyle(14);
        Field15Style := GetFieldStyle(15);
        Field16Style := GetFieldStyle(16);
        Field17Style := GetFieldStyle(17);
        Field18Style := GetFieldStyle(18);
        Field19Style := GetFieldStyle(19);
        Field20Style := GetFieldStyle(20);
        Field21Style := GetFieldStyle(21);
        Field22Style := GetFieldStyle(22);
        Field23Style := GetFieldStyle(23);
        Field24Style := GetFieldStyle(24);
        Field25Style := GetFieldStyle(25);
        Field26Style := GetFieldStyle(26);
        Field27Style := GetFieldStyle(27);
        Field28Style := GetFieldStyle(28);
        Field29Style := GetFieldStyle(29);
        Field30Style := GetFieldStyle(30);
        Field31Style := GetFieldStyle(31);
        Field32Style := GetFieldStyle(32);
        Field33Style := GetFieldStyle(33);
        Field34Style := GetFieldStyle(34);
        Field35Style := GetFieldStyle(35);
        Field36Style := GetFieldStyle(36);
        Field37Style := GetFieldStyle(37);
        Field38Style := GetFieldStyle(38);
        Field39Style := GetFieldStyle(39);
        Field40Style := GetFieldStyle(40);
        Field41Style := GetFieldStyle(41);
        Field42Style := GetFieldStyle(42);
        Field43Style := GetFieldStyle(43);
        Field44Style := GetFieldStyle(44);
        Field45Style := GetFieldStyle(45);
        Field46Style := GetFieldStyle(46);
        Field47Style := GetFieldStyle(47);
        Field48Style := GetFieldStyle(48);
        Field49Style := GetFieldStyle(49);
        Field50Style := GetFieldStyle(50);
        Field51Style := GetFieldStyle(51);
        Field52Style := GetFieldStyle(52);
        Field53Style := GetFieldStyle(53);
        Field54Style := GetFieldStyle(54);
        Field55Style := GetFieldStyle(55);
        Field56Style := GetFieldStyle(56);
        Field57Style := GetFieldStyle(57);
        Field58Style := GetFieldStyle(58);
        Field59Style := GetFieldStyle(59);
        Field60Style := GetFieldStyle(60);
        Field61Style := GetFieldStyle(61);
        Field62Style := GetFieldStyle(62);
        Field63Style := GetFieldStyle(63);
        Field64Style := GetFieldStyle(64);
        Field65Style := GetFieldStyle(65);
        Field66Style := GetFieldStyle(66);
        Field67Style := GetFieldStyle(67);
        Field68Style := GetFieldStyle(68);
        Field69Style := GetFieldStyle(69);
        Field70Style := GetFieldStyle(70);
        Field71Style := GetFieldStyle(71);
        Field72Style := GetFieldStyle(72);
        Field73Style := GetFieldStyle(73);
        Field74Style := GetFieldStyle(74);
        Field75Style := GetFieldStyle(75);
        Field76Style := GetFieldStyle(76);
        Field77Style := GetFieldStyle(77);
        Field78Style := GetFieldStyle(78);
        Field79Style := GetFieldStyle(79);
        Field80Style := GetFieldStyle(80);
        Field81Style := GetFieldStyle(81);
        Field82Style := GetFieldStyle(82);
        Field83Style := GetFieldStyle(83);
        Field84Style := GetFieldStyle(84);
        Field85Style := GetFieldStyle(85);
        Field86Style := GetFieldStyle(86);
        Field87Style := GetFieldStyle(87);
        Field88Style := GetFieldStyle(88);
        Field89Style := GetFieldStyle(89);
        Field90Style := GetFieldStyle(90);
        Field91Style := GetFieldStyle(91);
        Field92Style := GetFieldStyle(92);
        Field93Style := GetFieldStyle(93);
        Field94Style := GetFieldStyle(94);
        Field95Style := GetFieldStyle(95);
        Field96Style := GetFieldStyle(96);
        Field97Style := GetFieldStyle(97);
        Field98Style := GetFieldStyle(98);
        Field99Style := GetFieldStyle(99);
        Field100Style := GetFieldStyle(100);
        Field101Style := GetFieldStyle(101);
        Field102Style := GetFieldStyle(102);
        Field103Style := GetFieldStyle(103);
        Field104Style := GetFieldStyle(104);
        Field105Style := GetFieldStyle(105);
        Field106Style := GetFieldStyle(106);
        Field107Style := GetFieldStyle(107);
        Field108Style := GetFieldStyle(108);
        Field109Style := GetFieldStyle(109);
        Field110Style := GetFieldStyle(110);
        Field111Style := GetFieldStyle(111);
        Field112Style := GetFieldStyle(112);
        Field113Style := GetFieldStyle(113);
        Field114Style := GetFieldStyle(114);
        Field115Style := GetFieldStyle(115);
        Field116Style := GetFieldStyle(116);
        Field117Style := GetFieldStyle(117);
        Field118Style := GetFieldStyle(118);
        Field119Style := GetFieldStyle(119);
        Field120Style := GetFieldStyle(120);
        Field121Style := GetFieldStyle(121);
        Field122Style := GetFieldStyle(122);
        Field123Style := GetFieldStyle(123);
        Field124Style := GetFieldStyle(124);
        Field125Style := GetFieldStyle(125);
        Field126Style := GetFieldStyle(126);
        Field127Style := GetFieldStyle(127);
        Field128Style := GetFieldStyle(128);
        Field129Style := GetFieldStyle(129);
        Field130Style := GetFieldStyle(130);
        Field131Style := GetFieldStyle(131);
        Field132Style := GetFieldStyle(132);
        Field133Style := GetFieldStyle(133);
        Field134Style := GetFieldStyle(134);
        Field135Style := GetFieldStyle(135);
        Field136Style := GetFieldStyle(136);
        Field137Style := GetFieldStyle(137);
        Field138Style := GetFieldStyle(138);
        Field139Style := GetFieldStyle(139);
        Field140Style := GetFieldStyle(140);
        Field141Style := GetFieldStyle(141);
        Field142Style := GetFieldStyle(142);
        Field143Style := GetFieldStyle(143);
        Field144Style := GetFieldStyle(144);
        Field145Style := GetFieldStyle(145);
        Field146Style := GetFieldStyle(146);
        Field147Style := GetFieldStyle(147);
        Field148Style := GetFieldStyle(148);
        Field149Style := GetFieldStyle(149);
        Field150Style := GetFieldStyle(150);
        Field151Style := GetFieldStyle(151);
        Field152Style := GetFieldStyle(152);
        Field153Style := GetFieldStyle(153);
        Field154Style := GetFieldStyle(154);
        Field155Style := GetFieldStyle(155);
        Field156Style := GetFieldStyle(156);
        Field157Style := GetFieldStyle(157);
        Field158Style := GetFieldStyle(158);
        Field159Style := GetFieldStyle(159);
        Field160Style := GetFieldStyle(160);
        Field161Style := GetFieldStyle(161);
        Field162Style := GetFieldStyle(162);
        Field163Style := GetFieldStyle(163);
        Field164Style := GetFieldStyle(164);
        Field165Style := GetFieldStyle(165);
        Field166Style := GetFieldStyle(166);
        Field167Style := GetFieldStyle(167);
        Field168Style := GetFieldStyle(168);
        Field169Style := GetFieldStyle(169);
        Field170Style := GetFieldStyle(170);
        Field171Style := GetFieldStyle(171);
        Field172Style := GetFieldStyle(172);
        Field173Style := GetFieldStyle(173);
        Field174Style := GetFieldStyle(174);
        Field175Style := GetFieldStyle(175);
        Field176Style := GetFieldStyle(176);
        Field177Style := GetFieldStyle(177);
        Field178Style := GetFieldStyle(178);
        Field179Style := GetFieldStyle(179);
        Field180Style := GetFieldStyle(180);
        Field181Style := GetFieldStyle(181);
        Field182Style := GetFieldStyle(182);
        Field183Style := GetFieldStyle(183);
        Field184Style := GetFieldStyle(184);
        Field185Style := GetFieldStyle(185);
        Field186Style := GetFieldStyle(186);
        Field187Style := GetFieldStyle(187);
        Field188Style := GetFieldStyle(188);
        Field189Style := GetFieldStyle(189);
        Field190Style := GetFieldStyle(190);
        Field191Style := GetFieldStyle(191);
        Field192Style := GetFieldStyle(192);
        Field193Style := GetFieldStyle(193);
        Field194Style := GetFieldStyle(194);
        Field195Style := GetFieldStyle(195);
        Field196Style := GetFieldStyle(196);
        Field197Style := GetFieldStyle(197);
        Field198Style := GetFieldStyle(198);
        Field199Style := GetFieldStyle(199);
        Field200Style := GetFieldStyle(200);
    end;

    local procedure ValidatePackageData(ColumnID: Integer)
    begin
        if TempExcelBuffer.Get(Rec.Number, ColumnID) then begin
            TempExcelBuffer."Cell Value as Text" := DelChr(MatrixCellData[ColumnID], '<>', ' ');
            TempExcelBuffer.Modify();
        end else begin
            TempExcelBuffer.Init();
            TempExcelBuffer."Row No." := Rec.Number;
            TempExcelBuffer."Column No." := ColumnID;
            TempExcelBuffer."Cell Value as Text" := DelChr(MatrixCellData[ColumnID], '<>', ' ');
            TempExcelBuffer.Insert();
        end;
        CurrPage.Update(false);
    end;
}