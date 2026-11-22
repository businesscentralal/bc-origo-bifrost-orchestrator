namespace Origo.Bifrost.Orchestrator;

using System.IO;

/// <summary>
/// Worksheet page for interactively viewing and editing the records of one table as scrollable matrix columns
/// (port of "Tools Edit Table" from Tools for Power Users, #261). Cell values are read through Foundation's
/// "Serializer ori" and saved through "Table Data Mgt ori".SaveField, so a restricted table, a restricted field and a
/// write-once field are refused exactly as in every other Orchestrator write. Delete Selected Lines passes the same guard.
/// The original "Skip Field and Record Validation" option is not ported: Foundation offers no guarded equivalent.
/// </summary>
page 10035628 "Table Data Editor ori"
{
    ApplicationArea = All;
    Caption = 'Edit Table', Comment = 'is-IS=Breyta töflu';
    DataCaptionExpression = ThisPageCaption;
    DeleteAllowed = false;
    Extensible = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Table Data Edit ori";
    UsageCategory = None;
    ContextSensitiveHelpPage = 'playbooks';
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;

                field("Record System Id"; Rec."Record System Id")
                {
                    ApplicationArea = All;
                    Caption = 'SystemId', Comment = 'is-IS=Kerfiskenni';
                    Editable = false;
                    ToolTip = 'Specifies the value of the SystemId field.', Comment = 'is-IS=Tilgreinir gildi kerfiskennis.';
                    Visible = false;
                }
                field(Field1; MatrixCellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    Editable = Field1Editable;
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
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
                    ToolTip = 'Specifies the value of the table field.', Comment = 'is-IS=Tilgreinir gildi töflureitsins.';
                    Visible = Field200Visible;
                    trigger OnValidate()
                    begin
                        ValidatePackageData(200);
                    end;
                }
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
                ToolTip = 'Deletes the selected lines from the source table', Comment = 'is-IS=Eyðir völdum færslum úr upprunatöflu';
                trigger OnAction()
                var
                    TempSelectedEntries: Record "Table Data Edit ori" temporary;
                    EditMgt: Codeunit "Table Data Edit Mgt ori";
                    DeleteQst: Label 'Delete %1 entries from %2', Comment = '%1 = selected record count, %2 = table caption, is-IS=Eyða %1 færslum úr %2';
                begin
                    TempSelectedEntries.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempSelectedEntries);
                    if not Confirm(DeleteQst, false, TempSelectedEntries.Count, ThisPageCaption) then
                        exit;
                    EditMgt.AssertCanDelete(TableNo);
                    if TempSelectedEntries.FindSet() then
                        repeat
                            EditMgt.DeleteRecord(TableNo, TempSelectedEntries."Record System Id");
                            TempSelectedEntries.Delete();
                        until TempSelectedEntries.Next() = 0;
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
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        EditMgt.GetColumnValues(MatrixColumnOrdinal, MatrixCellData, RecordColumnField, Rec, ShowAuditFields);
    end;

    trigger OnClosePage()
    begin
        ClearAll();
    end;

    var

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
        RecordColumnReadOnly: array[1000] of Boolean;
        ShowAuditFields: Boolean;
        MatrixColumnOrdinal: Integer;
        RecordColumnField: array[1000] of Integer;
        TableNo: Integer;
        MatrixColumnCaptions: array[1000] of Text[100];
        MatrixCellData: array[1000] of Text[250];
        ThisPageCaption: Text[1024];

    /// <summary>
    /// Rebuilds the column caption array by reading field captions for the currently loaded table.
    /// </summary>
    procedure LoadColumnCaptions()
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        CopyArray(MatrixColumnCaptions, EditMgt.GetColumnCaptions(TableNo, ShowAuditFields), 1);
    end;

    /// <summary>
    /// Rebuilds the read-only column indicator array, marking primary key fields and system fields as non-editable.
    /// </summary>
    procedure LoadRecordColumnReadOnly()
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        CopyArray(RecordColumnReadOnly, EditMgt.GetIfRecordColumnReadOnly(TableNo, ShowAuditFields), 1);
    end;

    /// <summary>
    /// Sets whether audit fields (SystemCreatedAt, SystemModifiedAt, etc.) should be included as visible columns.
    /// </summary>
    /// <param name="NewShowAuditFields">When true, audit fields are shown as columns on the page.</param>
    procedure SetShowAuditFields(NewShowAuditFields: Boolean)
    begin
        ShowAuditFields := NewShowAuditFields;
    end;

    /// <summary>
    /// Sets the table number to display and the caption shown in the page title.
    /// </summary>
    /// <param name="TableNoIn">The ID of the table to display and edit.</param>
    /// <param name="PageCaptionIn">The text to use as the page caption.</param>
    procedure SetTableNo(TableNoIn: Integer; PageCaptionIn: Text)
    begin
        TableNo := TableNoIn;
        ThisPageCaption := CopyStr(PageCaptionIn, 1, MaxStrLen(ThisPageCaption));
    end;

    /// <summary>
    /// Loads all records matching the filter into the page's temporary source table.
    /// </summary>
    /// <param name="Filters">Serialized request page filter XML to restrict which records are loaded.</param>
    /// <param name="TempFilter">A Tools Edit Table record with additional date/time range filter values.</param>
    internal procedure InitRecords(Filters: Text; var TempFilter: Record "Table Data Edit ori")
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        EditMgt.InitRecords(TableNo, Filters, TempFilter, Rec);
    end;

    local procedure GetFieldsCount(): Integer
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        exit(EditMgt.GetFieldsCount(TableNo, ShowAuditFields));
    end;

    local procedure SetFieldsEditable()
    begin
        Field1Editable := not RecordColumnReadOnly[1];
        Field2Editable := not RecordColumnReadOnly[2];
        Field3Editable := not RecordColumnReadOnly[3];
        Field4Editable := not RecordColumnReadOnly[4];
        Field5Editable := not RecordColumnReadOnly[5];
        Field6Editable := not RecordColumnReadOnly[6];
        Field7Editable := not RecordColumnReadOnly[7];
        Field8Editable := not RecordColumnReadOnly[8];
        Field9Editable := not RecordColumnReadOnly[9];
        Field10Editable := not RecordColumnReadOnly[10];
        Field11Editable := not RecordColumnReadOnly[11];
        Field12Editable := not RecordColumnReadOnly[12];
        Field13Editable := not RecordColumnReadOnly[13];
        Field14Editable := not RecordColumnReadOnly[14];
        Field15Editable := not RecordColumnReadOnly[15];
        Field16Editable := not RecordColumnReadOnly[16];
        Field17Editable := not RecordColumnReadOnly[17];
        Field18Editable := not RecordColumnReadOnly[18];
        Field19Editable := not RecordColumnReadOnly[19];
        Field20Editable := not RecordColumnReadOnly[20];
        Field21Editable := not RecordColumnReadOnly[21];
        Field22Editable := not RecordColumnReadOnly[22];
        Field23Editable := not RecordColumnReadOnly[23];
        Field24Editable := not RecordColumnReadOnly[24];
        Field25Editable := not RecordColumnReadOnly[25];
        Field26Editable := not RecordColumnReadOnly[26];
        Field27Editable := not RecordColumnReadOnly[27];
        Field28Editable := not RecordColumnReadOnly[28];
        Field29Editable := not RecordColumnReadOnly[29];
        Field30Editable := not RecordColumnReadOnly[30];
        Field31Editable := not RecordColumnReadOnly[31];
        Field32Editable := not RecordColumnReadOnly[32];
        Field33Editable := not RecordColumnReadOnly[33];
        Field34Editable := not RecordColumnReadOnly[34];
        Field35Editable := not RecordColumnReadOnly[35];
        Field36Editable := not RecordColumnReadOnly[36];
        Field37Editable := not RecordColumnReadOnly[37];
        Field38Editable := not RecordColumnReadOnly[38];
        Field39Editable := not RecordColumnReadOnly[39];
        Field40Editable := not RecordColumnReadOnly[40];
        Field41Editable := not RecordColumnReadOnly[41];
        Field42Editable := not RecordColumnReadOnly[42];
        Field43Editable := not RecordColumnReadOnly[43];
        Field44Editable := not RecordColumnReadOnly[44];
        Field45Editable := not RecordColumnReadOnly[45];
        Field46Editable := not RecordColumnReadOnly[46];
        Field47Editable := not RecordColumnReadOnly[47];
        Field48Editable := not RecordColumnReadOnly[48];
        Field49Editable := not RecordColumnReadOnly[49];
        Field50Editable := not RecordColumnReadOnly[50];
        Field51Editable := not RecordColumnReadOnly[51];
        Field52Editable := not RecordColumnReadOnly[52];
        Field53Editable := not RecordColumnReadOnly[53];
        Field54Editable := not RecordColumnReadOnly[54];
        Field55Editable := not RecordColumnReadOnly[55];
        Field56Editable := not RecordColumnReadOnly[56];
        Field57Editable := not RecordColumnReadOnly[57];
        Field58Editable := not RecordColumnReadOnly[58];
        Field59Editable := not RecordColumnReadOnly[59];
        Field60Editable := not RecordColumnReadOnly[60];
        Field61Editable := not RecordColumnReadOnly[61];
        Field62Editable := not RecordColumnReadOnly[62];
        Field63Editable := not RecordColumnReadOnly[63];
        Field64Editable := not RecordColumnReadOnly[64];
        Field65Editable := not RecordColumnReadOnly[65];
        Field66Editable := not RecordColumnReadOnly[66];
        Field67Editable := not RecordColumnReadOnly[67];
        Field68Editable := not RecordColumnReadOnly[68];
        Field69Editable := not RecordColumnReadOnly[69];
        Field70Editable := not RecordColumnReadOnly[70];
        Field71Editable := not RecordColumnReadOnly[71];
        Field72Editable := not RecordColumnReadOnly[72];
        Field73Editable := not RecordColumnReadOnly[73];
        Field74Editable := not RecordColumnReadOnly[74];
        Field75Editable := not RecordColumnReadOnly[75];
        Field76Editable := not RecordColumnReadOnly[76];
        Field77Editable := not RecordColumnReadOnly[77];
        Field78Editable := not RecordColumnReadOnly[78];
        Field79Editable := not RecordColumnReadOnly[79];
        Field80Editable := not RecordColumnReadOnly[80];
        Field81Editable := not RecordColumnReadOnly[81];
        Field82Editable := not RecordColumnReadOnly[82];
        Field83Editable := not RecordColumnReadOnly[83];
        Field84Editable := not RecordColumnReadOnly[84];
        Field85Editable := not RecordColumnReadOnly[85];
        Field86Editable := not RecordColumnReadOnly[86];
        Field87Editable := not RecordColumnReadOnly[87];
        Field88Editable := not RecordColumnReadOnly[88];
        Field89Editable := not RecordColumnReadOnly[89];
        Field90Editable := not RecordColumnReadOnly[90];
        Field91Editable := not RecordColumnReadOnly[91];
        Field92Editable := not RecordColumnReadOnly[92];
        Field93Editable := not RecordColumnReadOnly[93];
        Field94Editable := not RecordColumnReadOnly[94];
        Field95Editable := not RecordColumnReadOnly[95];
        Field96Editable := not RecordColumnReadOnly[96];
        Field97Editable := not RecordColumnReadOnly[97];
        Field98Editable := not RecordColumnReadOnly[98];
        Field99Editable := not RecordColumnReadOnly[99];
        Field100Editable := not RecordColumnReadOnly[100];
        Field101Editable := not RecordColumnReadOnly[101];
        Field102Editable := not RecordColumnReadOnly[102];
        Field103Editable := not RecordColumnReadOnly[103];
        Field104Editable := not RecordColumnReadOnly[104];
        Field105Editable := not RecordColumnReadOnly[105];
        Field106Editable := not RecordColumnReadOnly[106];
        Field107Editable := not RecordColumnReadOnly[107];
        Field108Editable := not RecordColumnReadOnly[108];
        Field109Editable := not RecordColumnReadOnly[109];
        Field110Editable := not RecordColumnReadOnly[110];
        Field111Editable := not RecordColumnReadOnly[111];
        Field112Editable := not RecordColumnReadOnly[112];
        Field113Editable := not RecordColumnReadOnly[113];
        Field114Editable := not RecordColumnReadOnly[114];
        Field115Editable := not RecordColumnReadOnly[115];
        Field116Editable := not RecordColumnReadOnly[116];
        Field117Editable := not RecordColumnReadOnly[117];
        Field118Editable := not RecordColumnReadOnly[118];
        Field119Editable := not RecordColumnReadOnly[119];
        Field120Editable := not RecordColumnReadOnly[120];
        Field121Editable := not RecordColumnReadOnly[121];
        Field122Editable := not RecordColumnReadOnly[122];
        Field123Editable := not RecordColumnReadOnly[123];
        Field124Editable := not RecordColumnReadOnly[124];
        Field125Editable := not RecordColumnReadOnly[125];
        Field126Editable := not RecordColumnReadOnly[126];
        Field127Editable := not RecordColumnReadOnly[127];
        Field128Editable := not RecordColumnReadOnly[128];
        Field129Editable := not RecordColumnReadOnly[129];
        Field130Editable := not RecordColumnReadOnly[130];
        Field131Editable := not RecordColumnReadOnly[131];
        Field132Editable := not RecordColumnReadOnly[132];
        Field133Editable := not RecordColumnReadOnly[133];
        Field134Editable := not RecordColumnReadOnly[134];
        Field135Editable := not RecordColumnReadOnly[135];
        Field136Editable := not RecordColumnReadOnly[136];
        Field137Editable := not RecordColumnReadOnly[137];
        Field138Editable := not RecordColumnReadOnly[138];
        Field139Editable := not RecordColumnReadOnly[139];
        Field140Editable := not RecordColumnReadOnly[140];
        Field141Editable := not RecordColumnReadOnly[141];
        Field142Editable := not RecordColumnReadOnly[142];
        Field143Editable := not RecordColumnReadOnly[143];
        Field144Editable := not RecordColumnReadOnly[144];
        Field145Editable := not RecordColumnReadOnly[145];
        Field146Editable := not RecordColumnReadOnly[146];
        Field147Editable := not RecordColumnReadOnly[147];
        Field148Editable := not RecordColumnReadOnly[148];
        Field149Editable := not RecordColumnReadOnly[149];
        Field150Editable := not RecordColumnReadOnly[150];
        Field151Editable := not RecordColumnReadOnly[151];
        Field152Editable := not RecordColumnReadOnly[152];
        Field153Editable := not RecordColumnReadOnly[153];
        Field154Editable := not RecordColumnReadOnly[154];
        Field155Editable := not RecordColumnReadOnly[155];
        Field156Editable := not RecordColumnReadOnly[156];
        Field157Editable := not RecordColumnReadOnly[157];
        Field158Editable := not RecordColumnReadOnly[158];
        Field159Editable := not RecordColumnReadOnly[159];
        Field160Editable := not RecordColumnReadOnly[160];
        Field161Editable := not RecordColumnReadOnly[161];
        Field162Editable := not RecordColumnReadOnly[162];
        Field163Editable := not RecordColumnReadOnly[163];
        Field164Editable := not RecordColumnReadOnly[164];
        Field165Editable := not RecordColumnReadOnly[165];
        Field166Editable := not RecordColumnReadOnly[166];
        Field167Editable := not RecordColumnReadOnly[167];
        Field168Editable := not RecordColumnReadOnly[168];
        Field169Editable := not RecordColumnReadOnly[169];
        Field170Editable := not RecordColumnReadOnly[170];
        Field171Editable := not RecordColumnReadOnly[171];
        Field172Editable := not RecordColumnReadOnly[172];
        Field173Editable := not RecordColumnReadOnly[173];
        Field174Editable := not RecordColumnReadOnly[174];
        Field175Editable := not RecordColumnReadOnly[175];
        Field176Editable := not RecordColumnReadOnly[176];
        Field177Editable := not RecordColumnReadOnly[177];
        Field178Editable := not RecordColumnReadOnly[178];
        Field179Editable := not RecordColumnReadOnly[179];
        Field180Editable := not RecordColumnReadOnly[180];
        Field181Editable := not RecordColumnReadOnly[181];
        Field182Editable := not RecordColumnReadOnly[182];
        Field183Editable := not RecordColumnReadOnly[183];
        Field184Editable := not RecordColumnReadOnly[184];
        Field185Editable := not RecordColumnReadOnly[185];
        Field186Editable := not RecordColumnReadOnly[186];
        Field187Editable := not RecordColumnReadOnly[187];
        Field188Editable := not RecordColumnReadOnly[188];
        Field189Editable := not RecordColumnReadOnly[189];
        Field190Editable := not RecordColumnReadOnly[190];
        Field191Editable := not RecordColumnReadOnly[191];
        Field192Editable := not RecordColumnReadOnly[192];
        Field193Editable := not RecordColumnReadOnly[193];
        Field194Editable := not RecordColumnReadOnly[194];
        Field195Editable := not RecordColumnReadOnly[195];
        Field196Editable := not RecordColumnReadOnly[196];
        Field197Editable := not RecordColumnReadOnly[197];
        Field198Editable := not RecordColumnReadOnly[198];
        Field199Editable := not RecordColumnReadOnly[199];
        Field200Editable := not RecordColumnReadOnly[200];
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

    local procedure ValidatePackageData(ColumnID: Integer)
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        MatrixCellData[ColumnID] := DelChr(MatrixCellData[ColumnID], '<>', ' ');
        EditMgt.SaveCell(Rec."Table ID", Rec."Record System Id", RecordColumnField[ColumnID], MatrixCellData[ColumnID]);
        CurrPage.Update();
    end;
}
