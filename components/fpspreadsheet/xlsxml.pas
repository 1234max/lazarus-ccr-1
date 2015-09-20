unit xlsxml;

{$ifdef fpc}
  {$mode objfpc}{$H+}
{$endif}

interface

uses
  Classes, SysUtils,
  laz2_xmlread, laz2_DOM,
  fpsTypes, fpspreadsheet, fpsReaderWriter, xlsCommon;

type

  { TsSpreadExcelXMLWriter }

  TsSpreadExcelXMLWriter = class(TsCustomSpreadWriter)
  private
    FDateMode: TDateMode;
    FPointSeparatorSettings: TFormatSettings;
    function GetCommentStr(ACell: PCell): String;
    function GetHyperlinkStr(ACell: PCell): String;
    function GetIndexStr(AIndex: Integer): String;
    function GetMergeStr(ACell: PCell): String;
    function GetStyleStr(ACell: PCell): String;
    procedure WriteCells(AStream: TStream; AWorksheet: TsWorksheet);
    procedure WriteExcelWorkbook(AStream: TStream);
    procedure WriteStyle(AStream: TStream; AIndex: Integer);
    procedure WriteStyles(AStream: TStream);
    procedure WriteWorksheet(AStream: TStream; AWorksheet: TsWorksheet);
    procedure WriteWorksheets(AStream: TStream);

  protected
    procedure WriteBlank(AStream: TStream; const ARow, ACol: Cardinal;
      ACell: PCell); override;
    procedure WriteBool(AStream: TStream; const ARow, ACol: Cardinal;
      const AValue: boolean; ACell: PCell); override;
    procedure WriteCellToStream(AStream: TStream; ACell: PCell); override;
    procedure WriteDateTime(AStream: TStream; const ARow, ACol: Cardinal;
      const AValue: TDateTime; ACell: PCell); override;
    procedure WriteError(AStream: TStream; const ARow, ACol: Cardinal;
      const AValue: TsErrorValue; ACell: PCell); override;
    procedure WriteLabel(AStream: TStream; const ARow, ACol: Cardinal;
      const AValue: string; ACell: PCell); override;
    procedure WriteNumber(AStream: TStream; const ARow, ACol: Cardinal;
      const AValue: double; ACell: PCell); override;

  public
    constructor Create(AWorkbook: TsWorkbook); override;
    procedure WriteToFile(const AFileName: string; const AOverwriteExisting: Boolean = False); override;
    procedure WriteToStream(AStream: TStream); override;

  end;

  TExcelXmlSettings = record
    DateMode: TDateMode;
  end;

var
  ExcelXmlSettings: TExcelXmlSettings = (
    DateMode: dm1900;
  );


implementation

uses
  StrUtils, Math,
  fpsStrings, fpsUtils, fpsStreams, fpsNumFormat, fpsHTMLUtils;

const
  FMT_OFFSET = 61;

const
  { TsFillStyle = (
    fsNoFill, fsSolidFill,
    fsGray75, fsGray50, fsGray25, fsGray12, fsGray6,
    fsStripeHor, fsStripeVert, fsStripeDiagUp, fsStripeDiagDown,
    fsThinStripeHor, fsThinStripeVert, fsThinStripeDiagUp, fsThinStripeDiagDown,
    fsHatchDiag, fsThinHatchDiag, fsThickHatchDiag, fsThinHatchHor) }
  FILL_NAMES: array[TsFillStyle] of string = (
    '', 'Solid',
    'Gray75', 'Gray50', 'Gray25', 'Gray12', 'Gray0625',
    'HorzStripe', 'VertStripe', 'DiagStripe', 'ReverseDiagStripe',
    'ThinHorzStripe', 'ThinVertStripe', 'ThinDiagStripe', 'ThinReverseDiagStripe',
    'DiagCross', 'ThinDiagCross', 'ThickDiagCross', 'ThinHorzCross'
  );

  {TsCellBorder = (cbNorth, cbWest, cbEast, cbSouth, cbDiagUp, cbDiagDown); }
  BORDER_NAMES: array[TsCellBorder] of string = (
    'Top', 'Left', 'Right', 'Bottom', 'DiagonalRight', 'DiagonalLeft'
  );

  { TsLineStyle = (
    lsThin, lsMedium, lsDashed, lsDotted, lsThick, lsDouble, lsHair,
    lsMediumDash, lsDashDot, lsMediumDashDot, lsDashDotDot, lsMediumDashDotDot,
    lsSlantDashDot) }
  LINE_STYLES: array[TsLineStyle] of string = (
    'Continuous', 'Continuous', 'Dash', 'Dot', 'Continuous', 'Double', 'Continuous',
    'Dash', 'DashDot', 'DashDot', 'DashDotDot', 'DashDotDot',
    'SlantDashDot'
  );
  LINE_WIDTHS: array[TsLineStyle] of Integer = (
    1, 2, 1, 1, 3, 3, 0,
    2, 1, 2, 1, 2,
    2
  );

function GetCellContentTypeStr(ACell: PCell): String;
begin
  case ACell^.ContentType of
    cctNumber     : Result := 'Number';
    cctUTF8String : Result := 'String';
    cctDateTime   : Result := 'DateTime';
    cctBool       : Result := 'Boolean';
    cctError      : Result := 'Error';
  else
    raise Exception.Create('Content type error in cell ' + GetCellString(ACell^.Row, ACell^.Col));
  end;
end;

{@@ ----------------------------------------------------------------------------
  Constructor of the ExcelXML writer

  Defines the date mode and the limitations of the file format.
  Initializes the format settings to be used when writing to xml.
-------------------------------------------------------------------------------}
constructor TsSpreadExcelXMLWriter.Create(AWorkbook: TsWorkbook);
begin
  inherited Create(AWorkbook);

  // Initial base date in case it won't be set otherwise.
  // Use 1900 to get a bit more range between 1900..1904.
  FDateMode := ExcelXMLSettings.DateMode;

  // Special version of FormatSettings using a point decimal separator for sure.
  FPointSeparatorSettings := DefaultFormatSettings;
  FPointSeparatorSettings.DecimalSeparator := '.';

  // http://en.wikipedia.org/wiki/List_of_spreadsheet_software#Specifications
  FLimitations.MaxColCount := 256;
  FLimitations.MaxRowCount := 65536;
end;

function TsSpreadExcelXMLWriter.GetCommentStr(ACell: PCell): String;
var
  comment: PsComment;
begin
  Result := '';
  comment := FWorksheet.FindComment(ACell);
  if Assigned(comment) then
    Result := '<Comment><Data>' + comment^.Text + '</Data></Comment>';
  // If there will be some rich-text-like formatting in the future, use
  //  Result := '<Comment><ss:Data xmlns="http://www.w3.org/TR/REC-html40">'+comment^.Text+'</ss:Data></Comment>':
end;

function TsSpreadExcelXMLWriter.GetHyperlinkStr(ACell: PCell): String;
var
  hyperlink: PsHyperlink;
begin
  Result := '';
  hyperlink := FWorksheet.FindHyperlink(ACell);
  if Assigned(hyperlink) then
    Result := ' ss:HRef="' + hyperlink^.Target + '"';
end;

function TsSpreadExcelXMLWriter.GetIndexStr(AIndex: Integer): String;
begin
  Result := Format(' ss:Index="%d"', [AIndex]);
end;

function TsSpreadExcelXMLWriter.GetMergeStr(ACell: PCell): String;
var
  r1, c1, r2, c2: Cardinal;
begin
  Result := '';
  if FWorksheet.IsMerged(ACell) then begin
    FWorksheet.FindMergedRange(ACell, r1, c1, r2, c2);
    if c2 > c1 then
      Result := Result + Format(' ss:MergeAcross="%d"', [c2-c1]);
    if r2 > r1 then
      Result := Result + Format(' ss:MergeDown="%d"', [r2-r1]);
  end;
end;

function TsSpreadExcelXMLWriter.GetStyleStr(ACell: PCell): String;
begin
  Result := '';
  if ACell^.FormatIndex > 0 then
    Result := Format(' ss:StyleID="s%d"', [ACell^.FormatIndex + FMT_OFFSET]);
end;

procedure TsSpreadExcelXMLWriter.WriteBlank(AStream: TStream;
  const ARow, ACol: Cardinal; ACell: PCell);
begin
  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s>' +              // colIndex, style, hyperlink, merge
           '%s' +                       // Comment <Comment>...</Comment>
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), GetHyperlinkStr(ACell), GetMergeStr(ACell),
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteBool(AStream: TStream;
  const ARow, ACol: Cardinal; const AValue: boolean; ACell: PCell);
var
  valueStr: String;
  formulaStr: String;
  cctStr: String;
begin
  valueStr := StrUtils.IfThen(AValue, '1', '0');
  cctStr := 'Boolean';
  formulaStr := '';
  if HasFormula(ACell) then
  begin
    formulaStr := Format(' ss:Formula="=%s"', [ACell^.FormulaValue]);
    cctStr := GetCellContentTypeStr(ACell);
  end;

  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s%s>' +          // colIndex, style, formula, hyperlink, merge
           '<Data ss:Type="%s">' +    // data type
             '%s' +                   // value string
           '</Data>' +
           '%s' +                     // Comment <Comment>...</Comment>
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), formulaStr, GetHyperlinkStr(ACell), GetMergeStr(ACell),
    cctStr,
    valueStr,
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteCells(AStream: TStream; AWorksheet: TsWorksheet);
var
  c, c1, c2: Cardinal;
  r, r1, r2: Cardinal;
  cell: PCell;
begin
  r1 := 0;
  c1 := 0;
  r2 := AWorksheet.GetLastRowIndex;
  c2 := AWorksheet.GetLastColIndex;
  AppendToStream(AStream,
          '<Table>' + LineEnding);
  for c := c1 to c2 do
    AppendToStream(AStream,
          '  <Column ss:Width="80" />' + LineEnding);

  for r := r1 to r2 do
  begin
    AppendToStream(AStream,
          '  <Row>' + LineEnding);
    for c := c1 to c2 do
    begin
      cell := AWorksheet.FindCell(r, c);
      if cell <> nil then
      begin
        if FWorksheet.IsMerged(cell) and not FWorksheet.IsMergeBase(cell) then
          Continue;
        WriteCellToStream(AStream, cell);
      end;
    end;
    AppendToStream(AStream,
          '  </Row>' + LineEnding);
  end;

  AppendToStream(AStream,
          '</Table>' + LineEnding);
end;

procedure TsSpreadExcelXMLWriter.WriteCellToStream(AStream: TStream; ACell: PCell);
begin
  case ACell^.ContentType of
    cctBool:
      WriteBool(AStream, ACell^.Row, ACell^.Col, ACell^.BoolValue, ACell);
    cctDateTime:
      WriteDateTime(AStream, ACell^.Row, ACell^.Col, ACell^.DateTimeValue, ACell);
    cctEmpty:
      WriteBlank(AStream, ACell^.Row, ACell^.Col, ACell);
    cctError:
      WriteError(AStream, ACell^.Row, ACell^.Col, ACell^.ErrorValue, ACell);
    cctNumber:
      WriteNumber(AStream, ACell^.Row, ACell^.Col, ACell^.NumberValue, ACell);
    cctUTF8String:
      WriteLabel(AStream, ACell^.Row, ACell^.Col, ACell^.UTF8StringValue, ACell);
  end;

  if FWorksheet.ReadComment(ACell) <> '' then
    WriteComment(AStream, ACell);
end;

procedure TsSpreadExcelXMLWriter.WriteDateTime(AStream: TStream;
  const ARow, ACol: Cardinal; const AValue: TDateTime; ACell: PCell);
var
  valueStr: String;
  formulaStr: String;
  cctStr: String;
  ExcelDate: TDateTime;
  nfp: TsNumFormatParams;
  fmt: PsCellFormat;
begin
  ExcelDate := AValue;
  fmt := FWorkbook.GetPointerToCellFormat(ACell^.FormatIndex);
  // Times have an offset of 1 day!
  if (fmt <> nil) and (uffNumberFormat in fmt^.UsedFormattingFields) then
  begin
    nfp := FWorkbook.GetNumberFormat(fmt^.NumberFormatIndex);
    if IsTimeIntervalFormat(nfp) or IsTimeFormat(nfp) then
      case FDateMode of
        dm1900: ExcelDate := AValue + DATEMODE_1900_BASE;
        dm1904: ExcelDate := AValue + DATEMODE_1904_BASE;
      end;
  end;
  valueStr := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', ExcelDate);

  cctStr := 'DateTime';
  formulaStr := '';
  if HasFormula(ACell) then
  begin
    formulaStr := Format(' ss:Formula="=%s"', [ACell^.FormulaValue]);
    cctStr := GetCellContentTypeStr(ACell);
  end;

  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s%s>' +          // colIndex, style, formula, hyperlink, merge
           '<Data ss:Type="%s">' +    // data type
             '%s' +                   // value string
           '</Data>' +
           '%s' +                     // Comment <Comment>...</Comment>
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), formulaStr, GetHyperlinkStr(ACell), GetMergeStr(ACell),
    cctStr,
    valueStr,
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteError(AStream: TStream;
  const ARow, ACol: Cardinal; const AValue: TsErrorValue; ACell: PCell);
var
  valueStr: String;
  cctStr: String;
  formulaStr: String;
begin
  valueStr := GetErrorValueStr(AValue);

  formulaStr := '';
  cctStr := 'Error';
  if HasFormula(ACell) then
  begin
    cctStr := GetCellContentTypeStr(ACell);
    formulaStr := Format(' ss:Formula="=%s"', [ACell^.FormulaValue]);
  end;

  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s%s>' +        // colIndex, style, formula, hyperlink, merge
           '<Data ss:Type="%s">' +  // data type
             '%s' +                 // value string
           '</Data>' +
           '%s' +                   // Comment <Comment>...</Comment>
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), formulaStr, GetHyperlinkStr(ACell), GetMergeStr(ACell),
    cctStr,
    valueStr,
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteExcelWorkbook(AStream: TStream);
var
  datemodeStr: String;
begin
  if FDateMode = dm1904 then
    datemodeStr := '  <Date1904/>' + LineEnding else
    datemodeStr := '';

  AppendToStream(AStream,
    '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">' + LineEnding +
      datemodeStr +
      '<ProtectStructure>False</ProtectStructure>' + LineEnding +
      '<ProtectWindows>False</ProtectWindows>' + LineEnding +
    '</ExcelWorkbook>' + LineEnding);
end;

procedure TsSpreadExcelXMLWriter.WriteLabel(AStream: TStream; const ARow,
  ACol: Cardinal; const AValue: string; ACell: PCell);
var
  valueStr: String;
  cctStr: String;
  formulaStr: String;
  xmlnsStr: String;
  dataTagStr: String;
begin
  if Length(ACell^.RichTextParams) > 0 then
  begin
    RichTextToHTML(
      FWorkbook,
      FWorksheet.ReadCellFont(ACell),
      AValue,
      ACell^.RichTextParams,
      valueStr,             // html-formatted rich text
      'html:', tcProperCase
    );
    xmlnsStr := ' xmlns="http://www.w3.org/TR/REC-html40"';
    dataTagStr := 'ss:';
  end else
  begin
    valueStr := AValue;
    if not ValidXMLText(valueStr) then
      Workbook.AddErrorMsg(
        rsInvalidCharacterInCell, [
        GetCellString(ARow, ACol)
      ]);
    xmlnsStr := '';
    dataTagStr := '';
  end;

  cctStr := 'String';
  if HasFormula(ACell) then
  begin
    cctStr := GetCellContentTypeStr(ACell);
    formulaStr := Format(' ss:Formula="=%s"', [ACell^.FormulaValue]);
  end;

  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s%s>' +           // colIndex, style, formula, hyperlink, merge
           '<%sData ss:Type="%s"%s>'+  // "ss:", data type, "xmlns=.."
             '%s' +                    // value string
           '</%sData>' +               // "ss:"
           '%s' +                      // Comment
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), formulaStr, GetHyperlinkStr(ACell), GetMergeStr(ACell),
    dataTagStr, cctStr, xmlnsStr,
    valueStr,
    dataTagStr,
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteNumber(AStream: TStream; const ARow, ACol: Cardinal;
  const AValue: double; ACell: PCell);
var
  formulaStr: String;
  cctStr: String;
begin
  cctStr := 'Number';
  if HasFormula(ACell) then
  begin
    cctStr := GetCellContentTypeStr(ACell);
    formulaStr := Format(' ss:Formula="=%s"', [ACell^.FormulaValue]);
  end;

  AppendToStream(AStream, Format(
    '    <Cell%s%s%s%s%s>' +        // colIndex, style, formula, hyperlink, merge
           '<Data ss:Type="%s">' +  // data type
             '%g' +                 // value
           '</Data>' +
           '%s' +                   // Comment <Comment>...</Comment>
         '</Cell>' + LineEnding, [
    GetIndexStr(ACol+1), GetStyleStr(ACell), formulaStr, GetHyperlinkStr(ACell), GetMergeStr(ACell),
    cctStr,
    AValue,
    GetCommentStr(ACell)
  ]));
end;

procedure TsSpreadExcelXMLWriter.WriteStyle(AStream: TStream; AIndex: Integer);
var
  fmt: PsCellFormat;
  deffnt, fnt: TsFont;
  s, fmtVert, fmtHor, fmtWrap, fmtRot: String;
  nfp: TsNumFormatParams;
  fill: TsFillPattern;
  cb: TsCellBorder;
  cbs: TsCellBorderStyle;
begin
  deffnt := FWorkbook.GetDefaultFont;
  if AIndex = 0 then
  begin
    AppendToStream(AStream, Format(
      '  <Style ss:ID="Default" ss:Name="Normal">' + LineEnding +
      '    <Aligment ss:Vertical="Bottom" />' + LineEnding +
      '    <Borders />' + LineEnding +
      '    <Font ss:FontName="%s" x:Family="Swiss" ss:Size="%d" ss:Color="%s" />' + LineEnding +
      '    <Interior />' + LineEnding +
      '    <NumberFormat />' + LineEnding +
      '    <Protection />' + LineEnding +
      '  </Style>' + LineEnding,
      [deffnt.FontName, round(deffnt.Size), ColorToHTMLColorStr(deffnt.Color)] )
    )
  end else
  begin
    AppendToStream(AStream, Format(
      '  <Style ss:ID="s%d">' + LineEnding, [AIndex + FMT_OFFSET]));

    fmt := FWorkbook.GetPointerToCellFormat(AIndex);

    // Horizontal alignment
    fmtHor := '';
    if uffHorAlign in fmt^.UsedFormattingFields then
      case fmt^.HorAlignment of
        haDefault: ;
        haLeft   : fmtHor := 'ss:Horizontal="Left" ';
        haCenter : fmtHor := 'ss:Horizontal="Center" ';
        haRight  : fmtHor := 'ss:Horizontal="Right" ';
        else
          raise Exception.Create('[TsSpreadXMLWriter.WriteStyle] Horizontal alignment cannot be handled.');
      end;

    // Vertical alignment
    fmtVert := 'ss:Vertical="Bottom" ';
    if uffVertAlign in fmt^.UsedFormattingFields then
      case fmt^.VertAlignment of
        vaDefault: ;
        vaTop    : fmtVert := 'ss:Vertical="Top" ';
        vaCenter : fmtVert := 'ss:Vertical="Center" ';
        vaBottom : ;
        else
          raise Exception.Create('[TsSpreadXMLWriter.WriteStyle] Vertical alignment cannot be handled.');
      end;

    // Wrap text
    if uffWordwrap in fmt^.UsedFormattingFields then
      fmtWrap := 'ss:WrapText="1" ' else
      fmtWrap := '';

    // Text rotation
    fmtRot := '';
    if uffTextRotation in fmt^.UsedFormattingFields then
      case fmt^.TextRotation of
        rt90DegreeClockwiseRotation        : fmtRot := 'ss:Rotate="-90" ';
        rt90DegreeCounterClockwiseRotation : fmtRot := 'ss:Rotate="90" ';
        rtStacked                          : fmtRot := 'ss:VerticalText="1" ';
      end;

    // Write all the alignment, text rotation and wordwrap attributes to stream
    AppendToStream(AStream, Format(
      '    <Alignment %s%s%s%s />' + LineEnding,
      [fmtHor, fmtVert, fmtWrap, fmtRot])
    );

    // Font
    if (uffFont in fmt^.UsedFormattingFields) then
    begin
      fnt := FWorkbook.GetFont(fmt^.FontIndex);
      s := '';
      if fnt.FontName <> deffnt.FontName then
        s := s + Format('ss:FontName="%s" ', [fnt.FontName]);
      if not SameValue(fnt.Size, deffnt.Size, 1E-3) then
        s := s + Format('ss:Size="%g" ', [fnt.Size], FPointSeparatorSettings);
      if fnt.Color <> deffnt.Color then
        s := s + Format('ss:Color="%s" ', [ColorToHTMLColorStr(fnt.Color)]);
      if fssBold in fnt.Style then
        s := s + 'ss:Bold="1" ';
      if fssItalic in fnt.Style then
        s := s + 'ss:Italic="1" ';
      if fssUnderline in fnt.Style then
        s := s + 'ss:Underline="Single" ';    // or "Double", not supported by fps
      if fssStrikeout in fnt.Style then
        s := s + 'ss:StrikeThrough="1" ';
      if s <> '' then
        AppendToStream(AStream,
          '    <Font ' + s + '/>' + LineEnding);
    end;

    // Number Format
    if (uffNumberFormat in fmt^.UsedFormattingFields) then
    begin
      nfp := FWorkbook.GetNumberFormat(fmt^.NumberFormatIndex);
      AppendToStream(AStream, Format(
        '    <NumberFormat ss:Format="%s"/>' + LineEnding, [nfp.NumFormatStr]));
    end;

    // Background
    if (uffBackground in fmt^.UsedFormattingFields) then
    begin
      fill := fmt^.Background;
      s := 'ss:Color="' + ColorToHTMLColorStr(fill.BgColor) + '" ';
      if not (fill.Style in [fsNoFill, fsSolidFill]) then
        s := s + 'ss:PatternColor="' + ColorToHTMLColorStr(fill.FgColor) + '" ';
      s := s + 'ss:Pattern="' + FILL_NAMES[fill.Style] + '"';
      AppendToStream(AStream,
        '    <Interior ' + s + '/>')
    end;

    // Borders
    if (uffBorder in fmt^.UsedFormattingFields) then
    begin
      s := '';
      for cb in TsCellBorder do
        if cb in fmt^.Border then begin
          cbs := fmt^.BorderStyles[cb];
          s := s + Format('      <Border ss:Position="%s" ss:LineStyle="%s"', [
            BORDER_NAMES[cb], LINE_STYLES[cbs.LineStyle]]);
          if fmt^.BorderStyles[cb].LineStyle <> lsHair then
            s := Format('%s ss:Weight="%d"', [s, LINE_WIDTHS[cbs.LineStyle]]);
          if fmt^.BorderStyles[cb].Color <> scBlack then
            s := Format('%s ss:Color="%s"', [s, ColorToHTMLColorStr(cbs.Color)]);
          s := s + '/>' + LineEnding;
        end;
      if s <> '' then
        AppendToStream(AStream,
          '    <Borders>' + LineEnding + s +
          '    </Borders>' + LineEnding);
    end;

    AppendToStream(AStream,
      '  </Style>' + LineEnding);
  end;
end;

procedure TsSpreadExcelXMLWriter.WriteStyles(AStream: TStream);
var
  i: Integer;
begin
  AppendToStream(AStream,
    '<Styles>' + LineEnding);
  for i:=0 to FWorkbook.GetNumCellFormats-1 do WriteStyle(AStream, i);
  AppendToStream(AStream,
    '</Styles>' + LineEnding);
end;

{@@ ----------------------------------------------------------------------------
  Writes an ExcelXML document to the file
-------------------------------------------------------------------------------}
procedure TsSpreadExcelXMLWriter.WriteToFile(const AFileName: string;
  const AOverwriteExisting: Boolean);
var
  stream: TStream;
  mode: word;
begin
  mode := fmCreate or fmShareDenyNone;
  if AOverwriteExisting
    then mode := mode or fmOpenWrite;

  if (boBufStream in Workbook.Options) then
    stream := TBufStream.Create(AFileName, mode)
  else
    stream := TFileStream.Create(AFileName, mode);

  try
    WriteToStream(stream);
  finally
    FreeAndNil(stream);
  end;
end;

{@@ ----------------------------------------------------------------------------
  Writes an ExcelXML document to a stream
-------------------------------------------------------------------------------}
procedure TsSpreadExcelXMLWriter.WriteToStream(AStream: TStream);
begin
  AppendToStream(AStream,
    '<?xml version="1.0"?>' + LineEnding +
    '<?mso-application progid="Excel.Sheet"?>' + LineEnding
  );
  AppendToStream(AStream,
    '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' + LineEnding +
    ' xmlns:o="urn:schemas-microsoft-com:office:office"' + LineEnding +
    ' xmlns:x="urn:schemas-microsoft-com:office:excel"' + LineEnding +
    ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' + LineEnding +
    ' xmlns:html="http://www.w3.org/TR/REC-html40">' + LineEnding);

  WriteExcelWorkbook(AStream);
  WriteStyles(AStream);
  WriteWorksheets(AStream);

  AppendToStream(AStream,
    '</Workbook>');
end;

procedure TsSpreadExcelXMLWriter.WriteWorksheet(AStream: TStream;
  AWorksheet: TsWorksheet);
begin
  FWorksheet := AWorksheet;
  AppendToStream(AStream, Format(
    '<Worksheet ss:Name="%s">' + LineEnding, [AWorksheet.Name])
  );
  WriteCells(AStream, AWorksheet);
  AppendToStream(AStream,
    '</Worksheet>' + LineEnding
  );
end;

procedure TsSpreadExcelXMLWriter.WriteWorksheets(AStream: TStream);
var
  i: Integer;
begin
  for i:=0 to FWorkbook.GetWorksheetCount-1 do
    WriteWorksheet(AStream, FWorkbook.GetWorksheetByIndex(i));
end;


initialization

  // Registers this reader / writer in fpSpreadsheet
  RegisterSpreadFormat(nil, TsSpreadExcelXMLWriter, sfExcelXML);

end.