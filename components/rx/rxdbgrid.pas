unit rxdbgrid;

{$I rx.inc}

interface

uses
  Classes, SysUtils, LResources, LCLType, LCLIntf, Forms, Controls,
  Graphics, Dialogs, Grids, dbutils, DBGrids, DB, PropertyStorage, vclutils,
  LMessages, types, StdCtrls;

const
  CBadQuickSearchSymbols = [VK_UNKNOWN..VK_HELP]+[VK_LWIN..VK_SLEEP]+[VK_NUMLOCK..VK_SCROLL]+[VK_LSHIFT..VK_OEM_102]+[VK_PROCESSKEY]+[VK_ATTN..VK_UNDEFINED];
  CCancelQuickSearchKeys = [VK_ESCAPE,VK_CANCEL,VK_DELETE,VK_INSERT,VK_DOWN,VK_UP,VK_NEXT,VK_PRIOR,VK_TAB,VK_RETURN,VK_HOME,VK_END,VK_SPACE,VK_MULTIPLY];

type
  TRxQuickSearchNotifyEvent = procedure(Sender: TObject; Field : TField; var AValue : string) of object;

  TSortMarker = (smNone, smDown, smUp);

  TGetBtnParamsEvent = procedure (Sender: TObject; Field: TField;
    AFont: TFont; var Background: TColor; var SortMarker: TSortMarker;
    IsDown: Boolean) of object;

  TGetCellPropsEvent = procedure (Sender: TObject; Field: TField;
    AFont: TFont; var Background: TColor) of object;

  TRxDBGridAllowedOperation = (aoInsert, aoUpdate, aoDelete, aoAppend);
  TRxDBGridAllowedOperations = set of TRxDBGridAllowedOperation;

  TFooterValueType = (fvtNon, fvtSum, fvtAvg, fvtCount, fvtFieldValue,
     fvtStaticText, fvtMax, fvtMin, fvtRecNo);

  TOptionRx = (rdgAllowColumnsForm,
               rdgAllowDialogFind,
               rdgHighlightFocusCol,          //TODO:
               rdgHighlightFocusRow,          //TODO:
               rdgDblClickOptimizeColWidth,
               rdgFooterRows,
               rdgXORColSizing,
               rdgFilter,
               rdgMultiTitleLines,
               rdgMrOkOnDblClik,
               rdgAllowQuickSearch
               );
  
  TOptionsRx = set of TOptionRx;
  
//  TDataSetClass = class of TDataSet;

  TRxColumn = class;

  TExDBGridSortEngine = class
  private
    FDataSetClass:TDataSetClass;
  public
    procedure Sort(Field:TField; ADataSet:TDataSet; Asc:boolean);virtual;abstract;
  end;
  TExDBGridSortEngineClass = class of TExDBGridSortEngine;

  TMLCaptionItem = class
    Caption:string;
    Width:integer;
    Hegth:integer;
    Next:TMLCaptionItem;
    Prior:TMLCaptionItem;
  end;

  { TRxColumnTitle }
  TRxColumnTitle = class(TColumnTitle)
  private
    FHint: string;
    FOrientation: TTextOrientation;
    FShowHint: boolean;
    FCaptionLines:TFPList;
    function GetCaptionLinesCount: integer;
    procedure SetOrientation(const AValue: TTextOrientation);
    procedure ClearCaptionML;
  protected
    procedure SetCaption(const AValue: TCaption); override;
  public
    constructor Create(TheColumn: TGridColumn); override;
    destructor Destroy; override;
    property CaptionLinesCount:integer read GetCaptionLinesCount;
    function CaptionLine(ALine:integer):TMLCaptionItem;
  published
    property Orientation:TTextOrientation read FOrientation write SetOrientation;
    property Hint: string read FHint write FHint;
    property ShowHint: boolean read FShowHint write FShowHint default false;
  end;

  { TRxColumnFooter }

  TRxColumnFooter = class(TPersistent)
  private
    FLayout: TTextLayout;
    FOwner:TRxColumn;
    FAlignment: TAlignment;
    FDisplayFormat: String;
    FFieldName: String;
    FValue: String;
    FValueType: TFooterValueType;
    FTestValue:Double;
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetDisplayFormat(const AValue: String);
    procedure SetFieldName(const AValue: String);
    procedure SetLayout(const AValue: TTextLayout);
    procedure SetValue(const AValue: String);
    procedure SetValueType(const AValue: TFooterValueType);
    function DisplayText:string;
    function GetFieldValue:string;
    function GetRecordsCount:string;
    function GetRecNo:string;
    function GetStatTotal:string;
    procedure ResetTestValue;
    procedure UpdateTestValue;
  public
    constructor Create(Owner:TRxColumn);
    property Owner:TRxColumn read FOwner;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Layout:TTextLayout read FLayout write SetLayout default tlCenter;
    property DisplayFormat: String read FDisplayFormat write SetDisplayFormat;
    property FieldName: String read FFieldName write SetFieldName;
    property Value: String read FValue write SetValue;
    property ValueType: TFooterValueType read FValueType write SetValueType default fvtNon;
  end;

  { TRxColumnFilter }

  TRxColumnFilter = class(TPersistent)
  private
    FOwner:TRxColumn;
    FValue: string;
    FValueList: TStringList;
    FEmptyValue: string;
    FEmptyFont: TFont;
    FFont: TFont;
    FAlignment: TAlignment;
    FDropDownRows: Integer;
    FColor: TColor;
    function GetItemIndex: integer;
    procedure SetColor(const AValue: TColor);
    procedure SetFont(const AValue: TFont);
    procedure SetItemIndex(const AValue: integer);
  public
    constructor Create(Owner:TRxColumn); virtual;
    destructor Destroy; override;
  published
    property Value: String read FValue write FValue;
    property Font: TFont read FFont write SetFont;
    property Alignment: TAlignment read FAlignment write FAlignment default taLeftJustify;
    property DropDownRows: Integer read FDropDownRows write FDropDownRows;
    property Color: TColor read FColor write SetColor default clWhite;
    property ValueList: TStringList read FValueList write FValueList;
    property EmptyValue: String read FEmptyValue write FEmptyValue;
    property EmptyFont: TFont read FEmptyFont write FEmptyFont;
    property ItemIndex:integer read GetItemIndex write SetItemIndex;
  end;

  { TRxColumn }

  TRxColumn = class(TColumn)
  private
    FFooter: TRxColumnFooter;
    FFilter : TRxColumnFilter;
    FImageList: TImageList;
    FKeyList:TStrings;
    FNotInKeyListIndex: Integer;
    function GetFooter: TRxColumnFooter;
    function GetKeyList: TStrings;
    procedure SetFilter(const AValue: TRxColumnFilter);
    procedure SetFooter(const AValue: TRxColumnFooter);
    procedure SetImageList(const AValue: TImageList);
    procedure SetKeyList(const AValue: TStrings);
    procedure SetNotInKeyListIndex(const AValue: Integer);
  protected
    function  CreateTitle: TGridColumnTitle; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor destroy; override;
    procedure OptimizeWidth;
  published
    property Footer:TRxColumnFooter read GetFooter write SetFooter;
    property ImageList:TImageList read FImageList write SetImageList;
    property KeyList: TStrings read GetKeyList write SetKeyList;
    property NotInKeyListIndex: Integer read FNotInKeyListIndex write SetNotInKeyListIndex default -1;
    property Filter : TRxColumnFilter read FFilter write SetFilter;
  end;
  
  { TRxDbGridColumns }
  TRxDbGridColumns = class(TDbGridColumns)
  protected
  public
    function  Add: TRxColumn;
  end;
  
  { TFilterListCellEditor }

  TFilterListCellEditor = class(TComboBox)
  private
    FGrid: TCustomGrid;
    FCol: Integer;
    FMouseFlag : boolean;
  protected
    procedure WndProc(var TheMessage : TLMessage); override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
  public
    procedure Show(Grid : TCustomGrid; Col : Integer);
    property Grid: TCustomGrid read FGrid;
    property Col: Integer read FCol;
    property MouseFlag : boolean read FMouseFlag write FMouseFlag;
  end;



  { TRxDBGrid }
  TRxDBGrid = class(TCustomDBGrid)
  private
    FInProcessCalc:integer;
    FAllowedOperations: TRxDBGridAllowedOperations;
    FFooterColor: TColor;
    FFooterRowCount: integer;
    FOnGetCellProps: TGetCellPropsEvent;
    FOptionsRx: TOptionsRx;
//    FTitleLines: Integer;
    FAutoSort: boolean;
    FMarkerUp, FMarkerDown: TBitmap;
    FOnGetBtnParams: TGetBtnParamsEvent;
    FOnFiltred : TNotifyEvent;
    //auto sort support
    FSortField:TField;
    FSortOrder:TSortMarker;
    FSortEngine:TExDBGridSortEngine;
    FPressedCol: TColumn;
    FPressed: Boolean;
    FSwapButtons: Boolean;
    FTracking: Boolean;
    //storage
    //Column resize
     FColumnResizing : Boolean;
    //
    FFilterListEditor : TFilterListCellEditor;


    FVersion: Integer;
    FPropertyStorageLink:TPropertyStorageLink;
    FRxDbGridLookupComboEditor:TCustomControl;
    FRxDbGridDateEditor:TWinControl;

    FAfterQuickSearch : TRxQuickSearchNotifyEvent;
    FBeforeQuickSearch : TRxQuickSearchNotifyEvent;
    FQuickUTF8Search : String;

    function GetColumns: TRxDbGridColumns;
    function GetPropertyStorage: TCustomPropertyStorage;
    function GetTitleButtons: boolean;
    function IsColumnsStored: boolean;
    procedure SetAutoSort(const AValue: boolean);
    procedure SetColumns(const AValue: TRxDbGridColumns);
    procedure SetFooterColor(const AValue: TColor);
    procedure SetFooterRowCount(const AValue: integer);
    procedure SetOptionsRx(const AValue: TOptionsRx);
    procedure SetPropertyStorage(const AValue: TCustomPropertyStorage);
    procedure SetTitleButtons(const AValue: boolean);
    procedure TrackButton(X, Y: Integer);
    procedure StopTracking;
    procedure CalcTitle;
    procedure ClearMLCaptionPointers;
    function getFilterRect(bRect : TRect):TRect;
    function getTitleRect(bRect : TRect):TRect;
    procedure OutCaptionCellText(aCol,aRow: Integer;const aRect: TRect; aState: TGridDrawState;const ACaption:string);
    procedure OutCaptionCellText90(aCol,aRow: Integer;const  aRect: TRect; aState: TGridDrawState;const ACaption:string;const TextOrient:TTextOrientation);
    procedure OutCaptionSortMarker(const  aRect: TRect; ASortMarker: TSortMarker);
    procedure OutCaptionMLCellText(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState; MLI:TMLCaptionItem);

    //storage
    procedure OnIniSave(Sender: TObject);
    procedure OnIniLoad(Sender: TObject);
  protected
//    procedure CreateWnd; override;
    function DatalinkActive:boolean;
    procedure DefaultDrawCellA(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DefaultDrawTitle(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DefaultDrawFilter(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DefaultDrawCellData(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DrawCell(aCol,aRow: Integer; aRect: TRect; aState:TGridDrawState); override;
    procedure LinkActive(Value: Boolean); override;
    procedure DrawFooterRows; virtual;
    procedure DoTitleClick(ACol: Longint; AField: TField); virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure UTF8KeyPress(var UTF8Key: TUTF8Char); override;
    function  CreateColumns: TGridColumns; override;
    procedure DrawCellBitmap(RxColumn:TRxColumn; aRect: TRect; aState: TGridDrawState; AImageIndex:integer); virtual;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    procedure CheckNewCachedSizes(var AGCache:TGridDataCache); override;
    procedure ColRowMoved(IsColumn: Boolean; FromIndex,ToIndex: Integer); override;
    procedure Paint;override;
    procedure UpdateActive;override;
    procedure UpdateData;override;
    procedure MoveSelection; override;
    procedure CMHintShow(var Message: TLMessage); message CM_HINTSHOW;
    procedure FFilterListEditorOnChange(Sender: TObject);
    procedure FFilterListEditorOnCloseUp(Sender: TObject);
    procedure InternalOptimizeColumnsWidth(AColList:TList);
    function IsDefaultRowHeightStored:boolean;
    procedure VisualChange; override;
    procedure SetQuickUTF8Search(AValue : String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function  EditorByStyle(Style: TColumnButtonStyle): TWinControl; override;
    procedure LayoutChanged; override;
    procedure ShowFindDialog;
    procedure ShowColumnsDialog;
    function ColumnByFieldName(AFieldName:string):TRxColumn;
    property Canvas;
    property DefaultTextStyle;
    property EditorBorderStyle;
    property EditorMode;
    property ExtendedColSizing;
    property FastEditing;
    property FocusRectVisible;
    property SelectedRows;
    procedure CalcStatTotals;
    procedure OptimizeColumnsWidth(AColList:String);
    procedure OptimizeColumnsWidthAll;
    procedure UpdateTitleHight;
    property QuickUTF8Search:String read FQuickUTF8Search write SetQuickUTF8Search;
  published
    property AfterQuickSearch: TRxQuickSearchNotifyEvent read FAfterQuickSearch write FAfterQuickSearch;
    property BeforeQuickSearch: TRxQuickSearchNotifyEvent read FBeforeQuickSearch write FBeforeQuickSearch;
    property OnGetBtnParams: TGetBtnParamsEvent read FOnGetBtnParams write FOnGetBtnParams;
    property TitleButtons: boolean read GetTitleButtons write SetTitleButtons;
    property AutoSort:boolean read FAutoSort write SetAutoSort;
    property OnGetCellProps: TGetCellPropsEvent read FOnGetCellProps
      write FOnGetCellProps;
    property Columns: TRxDbGridColumns read GetColumns write SetColumns stored IsColumnsStored;

    //storage
    property PropertyStorage:TCustomPropertyStorage read GetPropertyStorage write SetPropertyStorage;
    property Version: Integer read FVersion write FVersion default 0;
    property AllowedOperations:TRxDBGridAllowedOperations read FAllowedOperations
      write FAllowedOperations default [aoInsert, aoUpdate, aoDelete, aoAppend];
    property OptionsRx:TOptionsRx read FOptionsRx write SetOptionsRx;
    property FooterColor:TColor read FFooterColor write SetFooterColor default clWindow;
    property FooterRowCount:integer read FFooterRowCount write SetFooterRowCount  default 0;
    property OnFiltred : TNotifyEvent read FOnFiltred write FOnFiltred;
    //from DBGrid
    property Align;
    property AlternateColor;
    property Anchors;
    property AutoAdvance default aaRightDown;
    property AutoFillColumns;
    property AutoEdit;
    property BiDiMode;
    property BorderSpacing;
    property BorderStyle;
    property Color;
    property BorderColor;
    property FocusColor;
    property FixedHotColor;

    property SelectedColor;
    property GridLineColor;
    property GridLineStyle;

    property Constraints;
    property DataSource;
    property DefaultDrawing;
    property DefaultRowHeight stored IsDefaultRowHeightStored default 18 ;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FixedColor;
    property FixedCols;
    property Flat;
    property Font;
    property HeaderHotZones;
    property HeaderPushZones;
    //property ImeMode;
    //property ImeName;
    property Options;
    property OptionsExtra;
    property ParentBiDiMode;
    property ParentColor;
    //property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property Scrollbars default ssBoth;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property TitleFont;
    property TitleStyle;
    property Visible;
    property OnCellClick;
    property OnColEnter;
    property OnColExit;
    property OnColumnMoved;
    property OnColumnSized;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawColumnCell;
    property OnDblClick;
    property OnEditButtonClick;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnFieldEditMask;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPrepareCanvas;
    property OnSelectEditor;
    property OnStartDock;
    property OnStartDrag;
    property OnTitleClick;
    property OnUserCheckboxBitmap;
    property OnUTF8KeyPress;
  end;

procedure RegisterExDBGridSortEngine(ExDBGridSortEngineClass:TExDBGridSortEngineClass; DataSetClass:TDataSetClass);

implementation
uses Math, rxdconst, rxstrutils, rxdbgrid_findunit, rxdbgrid_columsunit,
  rxlookup, tooledit, LCLProc;

var
  ExDBGridSortEngineList:TStringList;

procedure RegisterExDBGridSortEngine(ExDBGridSortEngineClass:TExDBGridSortEngineClass; DataSetClass:TDataSetClass);
var
  Pos:integer;
  ExDBGridSortEngine:TExDBGridSortEngine;
begin
  if not ExDBGridSortEngineList.Find(DataSetClass.ClassName, Pos) then
  begin
    ExDBGridSortEngine:=ExDBGridSortEngineClass.Create;
    ExDBGridSortEngine.FDataSetClass:=DataSetClass;
    ExDBGridSortEngineList.AddObject(DataSetClass.ClassName, ExDBGridSortEngine);
  end
end;

procedure GridInvalidateRow(Grid: TRxDBGrid; Row: Longint);
var
  I: Longint;
begin
  for I := 0 to Grid.ColCount - 1 do Grid.InvalidateCell(I, Row);
end;

type

  { TRxDBGridLookupComboEditor }

  TRxDBGridLookupComboEditor =  class(TRxCustomDBLookupCombo)
  private
    FGrid: TRxDBGrid;
    FCol,FRow: Integer;
    FLDS:TDataSource;
  protected
    procedure WndProc(var TheMessage : TLMessage); override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure msg_SetGrid(var Msg: TGridMessage); message GM_SETGRID;
    procedure msg_SetValue(var Msg: TGridMessage); message GM_SETVALUE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TRxDBGridDateEditor }
  TRxDBGridDateEditor = class(TCustomRxDateEdit)
  private
    FGrid: TRxDBGrid;
    FCol,FRow: Integer;
  protected
    procedure Change; override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;

    procedure WndProc(var TheMessage : TLMessage); override;
    procedure msg_SetGrid(var Msg: TGridMessage); message GM_SETGRID;
    procedure msg_SetValue(var Msg: TGridMessage); message GM_SETVALUE;
    procedure msg_GetValue(var Msg: TGridMessage); message GM_GETVALUE;
    procedure msg_SelectAll(var Msg: TGridMessage); message GM_SELECTALL;

  public
//    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); override;
    procedure EditingDone; override;
  end;


{ TRxDBGridDateEditor }

procedure TRxDBGridDateEditor.Change;
begin
  inherited Change;
  if Assigned(FGrid) and FGrid.DatalinkActive and not FGrid.EditorIsReadOnly then
  begin
    if not (FGrid.DataSource.DataSet.State in dsEditModes) then
      FGrid.DataSource.Edit;
    if Self.Text <> '' then
      FGrid.SelectedField.AsDateTime:=Self.Date
    else
      FGrid.SelectedField.Clear;

    if FGrid<>nil then
      FGrid.SetEditText(FCol, FRow, Text);
  end;
end;

procedure TRxDBGridDateEditor.KeyDown(var Key: Word; Shift: TShiftState);
  function AllSelected: boolean;
  begin
    result := (SelLength>0) and (SelLength=UTF8Length(Text));
  end;
  function AtStart: Boolean;
  begin
    Result:= (SelStart=0);
  end;
  function AtEnd: Boolean;
  begin
    result := ((SelStart+1)>UTF8Length(Text)) or AllSelected;
  end;
  procedure doEditorKeyDown;
  begin
    if FGrid<>nil then
      FGrid.EditorkeyDown(Self, key, shift);
  end;
  procedure doGridKeyDown;
  begin
    if FGrid<>nil then
      FGrid.KeyDown(Key, shift);
  end;
  function GetFastEntry: boolean;
  begin
    if FGrid<>nil then
      Result := FGrid.FastEditing
    else
      Result := False;
  end;
  procedure CheckEditingKey;
  begin
    if (FGrid=nil) or FGrid.EditorIsReadOnly then
      Key := 0;
  end;
var
  IntSel: boolean;
begin
  inherited KeyDown(Key,Shift);
  case Key of
    VK_F2:
      if AllSelected then begin
        SelLength := 0;
        SelStart := Length(Text);
      end;
    VK_DELETE:
      CheckEditingKey;
    VK_UP, VK_DOWN:
      doGridKeyDown;
    VK_LEFT, VK_RIGHT:
      if GetFastEntry then begin
        IntSel:=
          ((Key=VK_LEFT) and not AtStart) or
          ((Key=VK_RIGHT) and not AtEnd);
      if not IntSel then begin
          doGridKeyDown;
      end;
    end;
    VK_END, VK_HOME:
      ;
    else
      doEditorKeyDown;
  end;
end;

procedure TRxDBGridDateEditor.WndProc(var TheMessage: TLMessage);
begin
  if TheMessage.msg=LM_KILLFOCUS then
  begin
    if HWND(TheMessage.WParam) = HWND(Handle) then
    begin
      // lost the focus but it returns to ourselves
      // eat the message.
      TheMessage.Result := 0;
      exit;
    end;
  end;
  inherited WndProc(TheMessage);
end;

procedure TRxDBGridDateEditor.msg_SetGrid(var Msg: TGridMessage);
begin
  FGrid:=Msg.Grid as TRxDBGrid;
  Msg.Options:=EO_AUTOSIZE or EO_SELECTALL {or EO_HOOKEXIT or EO_HOOKKEYPRESS or EO_HOOKKEYUP};
end;

procedure TRxDBGridDateEditor.msg_SetValue(var Msg: TGridMessage);
begin
  Self.Date:=FGrid.SelectedField.AsDateTime;
end;

procedure TRxDBGridDateEditor.msg_GetValue(var Msg: TGridMessage);
var
  sText:string;
begin
  sText:=Text;
  Msg.Value:=sText;
end;

procedure TRxDBGridDateEditor.msg_SelectAll(var Msg: TGridMessage);
begin
  SelectAll;
end;

{procedure TRxDBGridDateEditor.SetBounds(aLeft, aTop, aWidth, aHeight: integer);
begin
  BeginUpdateBounds;
  Dec(aWidth, 25);
  inherited SetBounds(aLeft, aTop, aWidth, aHeight);
  EndUpdateBounds;
end;}

procedure TRxDBGridDateEditor.EditingDone;
begin
  inherited EditingDone;
  if FGrid<>nil then
    FGrid.EditingDone;
end;


{ TRxDBGridLookupComboEditor }

procedure TRxDBGridLookupComboEditor.WndProc(var TheMessage: TLMessage);
begin
  if TheMessage.msg=LM_KILLFOCUS then
  begin
    if HWND(TheMessage.WParam) = HWND(Handle) then
    begin
      // lost the focus but it returns to ourselves
      // eat the message.
      TheMessage.Result := 0;
      exit;
    end;
  end;
  inherited WndProc(TheMessage);
end;

procedure TRxDBGridLookupComboEditor.KeyDown(var Key: Word; Shift: TShiftState
  );

procedure doGridKeyDown;
begin
  if Assigned(FGrid) then
    FGrid.KeyDown(Key, shift);
end;

begin
  case Key of
    VK_UP,
    VK_DOWN :
      if (not PopupVisible) and (not (ssAlt in Shift)) then
      begin
        doGridKeyDown;
        exit;
      end;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TRxDBGridLookupComboEditor.msg_SetGrid(var Msg: TGridMessage);
begin
  FGrid:=Msg.Grid as TRxDBGrid;
  Msg.Options:=EO_AUTOSIZE;
end;

procedure TRxDBGridLookupComboEditor.msg_SetValue(var Msg: TGridMessage);
var
  F:TField;
begin
  FCol := Msg.Col;
  FRow := Msg.Row;
  F:=FGrid.SelectedField;
  DataSource:=FGrid.DataSource;
  if Assigned(F) then
  begin
    DataField:=F.FieldName;
    LookupDisplay:=F.LookupResultField;
    LookupField:=F.LookupKeyFields;
    FLDS.DataSet:=F.LookupDataSet;
  end;
end;


constructor TRxDBGridLookupComboEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLDS:=TDataSource.Create(nil);
  LookupSource:=FLDS;
end;

destructor TRxDBGridLookupComboEditor.Destroy;
begin
  FreeAndNil(FLDS);
  inherited Destroy;
end;

{ TRxDBGrid }
const
  ALIGN_FLAGS: array[TAlignment] of Integer =
  (DT_LEFT or DT_SINGLELINE {or DT_EXPANDTABS} or DT_NOPREFIX,
    DT_RIGHT or DT_SINGLELINE {or DT_EXPANDTABS} or DT_NOPREFIX,
    DT_CENTER or DT_SINGLELINE {or DT_EXPANDTABS} or DT_NOPREFIX);
const
  ALIGN_FLAGS_HEADER: array[TAlignment] of Integer =
  (DT_LEFT  or {DT_EXPANDTABS or} DT_NOPREFIX,
    DT_RIGHT or {DT_EXPANDTABS or }DT_NOPREFIX,
    DT_CENTER or {DT_EXPANDTABS or }DT_NOPREFIX);

{  TITLE_SUBHEADER = 2;
  TITLE_DEFAULT = 1;

const
  EdgeFlag: array[Boolean] of UINT = (BDR_RAISEDINNER, BDR_SUNKENINNER);}

procedure WriteTextHeader(ACanvas: TCanvas; ARect: TRect; const Text: string;
  Alignment: TAlignment);
var
  DrawRect: TRect;
  W, CnvW:integer;
begin
  DrawRect := Rect(ARect.Left + 1, ARect.Top + 1, ARect.Right, ARect.Bottom);

  CnvW:=Max(DrawRect.Right - DrawRect.Left, 1);
  W:=(ACanvas.TextWidth(Text) div CnvW) + 1;

  DrawRect.Top:=((ARect.Top + ARect.Bottom) div 2) - W * ACanvas.TextHeight('W') div 2;
  if DrawRect.Top < ARect.Top + 1 then
    DrawRect.Top := ARect.Top + 1;

  DrawText(ACanvas.Handle, PChar(Text), Length(Text), DrawRect,
//    DT_VCENTER or  DT_WORDBREAK or DT_CENTER
    ALIGN_FLAGS_HEADER[Alignment] {or DT_VCENTER or  DT_END_ELLIPSIS }or DT_WORDBREAK
    );
end;


procedure TRxDBGrid.SetTitleButtons(const AValue: boolean);
begin
  if AValue then
    Options:=Options + [dgHeaderPushedLook]
  else
    Options:=Options - [dgHeaderPushedLook];
end;

procedure TRxDBGrid.SetAutoSort(const AValue: boolean);
var
  S:string;
  Pos:integer;
begin
  if FAutoSort=AValue then exit;
  FAutoSort:=AValue;
  if Assigned(DataSource) and Assigned(DataSource.DataSet) and DataSource.DataSet.Active then
  begin
    S:=DataSource.DataSet.ClassName;
    if ExDBGridSortEngineList.Find(S, Pos) then
      FSortEngine:=ExDBGridSortEngineList.Objects[Pos] as TExDBGridSortEngine
    else
      FSortEngine:=nil;
    FSortField:=nil;
    FSortOrder:=smNone;
  end
end;

function TRxDBGrid.GetColumns: TRxDbGridColumns;
begin
  result := TRxDbGridColumns(TCustomDrawGrid(Self).Columns);
end;

function TRxDBGrid.GetPropertyStorage: TCustomPropertyStorage;
begin
  Result:=FPropertyStorageLink.Storage;
end;

function TRxDBGrid.GetTitleButtons: boolean;
begin
  Result:=dgHeaderPushedLook in Options;
end;

function TRxDBGrid.IsColumnsStored: boolean;
begin
  result := TRxDbGridColumns(TCustomDrawGrid(Self).Columns).Enabled;
end;

procedure TRxDBGrid.SetColumns(const AValue: TRxDbGridColumns);
begin
  TRxDbGridColumns(TCustomDrawGrid(Self).Columns).Assign(Avalue);
end;

procedure TRxDBGrid.SetFooterColor(const AValue: TColor);
begin
  if FFooterColor=AValue then exit;
  FFooterColor:=AValue;
  Invalidate;
end;

procedure TRxDBGrid.SetFooterRowCount(const AValue: integer);
begin
  if FFooterRowCount=AValue then exit;
  FFooterRowCount:=AValue;
  VisualChange;
//  Invalidate;
end;

procedure TRxDBGrid.SetOptionsRx(const AValue: TOptionsRx);
begin
  if FOptionsRx=AValue then exit;
  FOptionsRx:=AValue;
  UseXORFeatures:=rdgXORColSizing in FOptionsRx;
  if rdgFilter in FOptionsRx then
  begin
     LayoutChanged;
     BeginUpdate;
     CalcTitle;
     EndUpdate;
  end;
  VisualChange;
end;

procedure TRxDBGrid.SetPropertyStorage(const AValue: TCustomPropertyStorage);
begin
  FPropertyStorageLink.Storage:=AValue;
end;

function TRxDBGrid.DatalinkActive: boolean;
begin
  Result:=Assigned(DataSource) and Assigned(DataSource.DataSet) and DataSource.DataSet.Active;
end;

procedure TRxDBGrid.TrackButton(X, Y: Integer);
var
  Cell: TGridCoord;
  NewPressed: Boolean;
  I, Offset: Integer;
begin
  Cell := MouseCoord(X, Y);
  Offset := RowCount;//[0];
  NewPressed := PtInRect(Rect(0, 0, ClientWidth, ClientHeight), Point(X, Y)) and
  
    (FPressedCol = TColumn(ColumnFromGridColumn(Cell.X))) and (Cell.Y < Offset);
  if FPressed <> NewPressed then
  begin
    FPressed := NewPressed;
    for I := 0 to Offset - 1 do
      GridInvalidateRow(Self, I);
  end;
end;

procedure TRxDBGrid.StopTracking;
begin
  if FTracking then
  begin
    TrackButton(-1, -1);
    FTracking := False;
    MouseCapture := False;
  end;
end;

procedure TRxDBGrid.CalcTitle;
var
  i, j:integer;
  H, H1, W, H2:integer;
  rxCol, rxColNext:TRxColumn;
  rxTit, rxTitleNext:TRxColumnTitle;
  MLRec1:TMLCaptionItem;
  MLRec2:TMLCaptionItem;
  tmpCanvas: TCanvas;
begin
  if RowCount = 0 then exit;
  tmpCanvas := GetWorkingCanvas(Canvas);
  try
    H:=1;
    ClearMLCaptionPointers;
    for i:=0 to Columns.Count-1 do
    begin
      rxCol:=TRxColumn(Columns[i]);
      if Assigned(rxCol) and rxCol.Visible then
      begin
        rxTit:=TRxColumnTitle(rxCol.Title);
        if Assigned(rxTit) then
        begin
          if rxTit.Orientation in [toVertical270, toVertical90] then
            H:=Max((tmpCanvas.TextWidth(Columns[i].Title.Caption)+ tmpCanvas.TextWidth('W')) div DefaultRowHeight, H)
          else
          begin
            rxColNext:=nil;
            rxTitleNext:=nil;
            if i < Columns.Count-1  then
            begin
              rxColNext:=TRxColumn(Columns[i+1]);
              rxTitleNext:=TRxColumnTitle(rxColNext.Title);
            end;
    { TODO -oalexs : Тут необходимо также обработать скрытые столбцы }
    {
            j:=i;
     while j < Columns.Count-1  then
            begin
              if
              inc(j);
            end;
            }

            W:=Max(rxCol.Width-2, 1);
            if rxTit.CaptionLinesCount > 0 then
            begin
              H2:=0;
              H1:=0;
              for j:=0 to rxTit.CaptionLinesCount-1 do
              begin
                MLRec1:=rxTit.CaptionLine(j);
                if Assigned(rxTitleNext) and (rxTitleNext.CaptionLinesCount>j) then
                begin
                  MLRec2:=rxTitleNext.CaptionLine(j);
                  if MLRec1.Caption = MLRec2.Caption then
                  begin
                    MLRec1.Next:=MLRec2;
                    MLRec2.Prior:=MLRec1;
                  end;
                end;

                MLRec1.Width:=tmpCanvas.TextWidth(MLRec1.Caption)+2;

                if W > MLRec1.Width then
                  H2:=1
                else
                  H2:=MLRec1.Width div W + 1;

                if H2>WordCount(MLRec1.Caption, [' ']) then
                  H2:=WordCount(MLRec1.Caption, [' ']);

                H1:=H1+H2;
              end
            end
            else
            begin
              H1:=Max((tmpCanvas.TextWidth(rxTit.Caption)+2) div W + 1, H);
              if H1>WordCount(rxTit.Caption, [' ']) then
                H1:=WordCount(rxTit.Caption, [' ']);
            end;
            H:=Max(H1, H);
          end;

          for j:=0 to rxTit.CaptionLinesCount-1 do
          begin
            MLRec1:=rxTit.CaptionLine(j);
            if MLRec1.Width < rxTit.Column.Width then
              MLRec1.Width:=rxTit.Column.Width;
          end;

        end;
      end;
    end;

    RowHeights[0] := DefaultRowHeight * ({FTitleLines+}H);

    if rdgFilter in OptionsRx then
    begin
      RowHeights[0] := RowHeights[0] + DefaultRowHeight;
    end;

  finally
    if TmpCanvas<>Canvas then
      FreeWorkingCanvas(tmpCanvas);
  end;
end;

procedure TRxDBGrid.ClearMLCaptionPointers;
var
  i, j:integer;
  rxCol:TRxColumn;
  rxTit:TRxColumnTitle;
begin
  for i:=0 to Columns.Count-1 do
  begin
    rxCol:=TRxColumn(Columns[i]);
    if Assigned(rxCol) then
    begin
      rxTit:= TRxColumnTitle(rxCol.Title);
      if Assigned(rxTit) then
      begin
        for j:=0 to rxTit.CaptionLinesCount - 1 do
        begin
          rxTit.CaptionLine(j).Next:=nil;
          rxTit.CaptionLine(j).Prior:=nil;
        end;
      end
    end
  end;
end;

function TRxDBGrid.getFilterRect(bRect: TRect): TRect;
begin
  Result := bRect;
  Result.Top := bRect.Bottom - DefaultRowHeight;
end;

function TRxDBGrid.getTitleRect(bRect: TRect): TRect;
begin
  Result := bRect;
  Result.Bottom := bRect.Bottom - DefaultRowHeight;
end;

procedure TRxDBGrid.OutCaptionCellText(aCol, aRow: Integer;const aRect: TRect;
  aState: TGridDrawState; const ACaption: string);
begin
  Canvas.FillRect(aRect);
  DrawCellGrid(aCol, aRow, aRect, aState);
  if ACaption <> '' then
    WriteTextHeader(Canvas, aRect, ACaption, GetColumnAlignment(aCol, true))
end;

procedure TRxDBGrid.OutCaptionCellText90(aCol,aRow: Integer;const  aRect: TRect;
  aState: TGridDrawState;const ACaption:string; const TextOrient:TTextOrientation);
var
  dW:integer;
begin
  Canvas.FillRect(aRect);
  DrawCellGrid(aCol,aRow,aRect,aState);

  if TextOrient in [toVertical90, toVertical270] then
    dW:=((aRect.Bottom - aRect.Top) - Canvas.TextWidth(ACaption)) div 2
  else
    dW:=0;
  OutTextXY90(Canvas, aRect.Left, aRect.Top+dw, ACaption, TextOrient);
end;

procedure TRxDBGrid.OutCaptionSortMarker(const aRect: TRect;
  ASortMarker: TSortMarker);
var
  X,Y:integer;
begin
  if (dgHeaderPushedLook in Options) then
  begin
    if ASortMarker = smDown then
    begin
      X:=aRect.Right - FMarkerDown.Width - 6;
      Y:=Trunc((aRect.Top+aRect.Bottom-FMarkerDown.Height)/2);
      Canvas.Draw(X, Y, FMarkerDown);
    end
    else
    if ASortMarker = smUp then
    begin
      X:=aRect.Right - FMarkerUp.Width - 6;
      Y:=Trunc((aRect.Top+aRect.Bottom-FMarkerUp.Height)/2);
      Canvas.Draw(X, Y, FMarkerUp);
    end;
  end;
end;

procedure TRxDBGrid.OutCaptionMLCellText(aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState; MLI: TMLCaptionItem);
var
  MLINext: TMLCaptionItem;
begin
  MLINext:=MLI.Next;
  while Assigned(MLINext) do
  begin
    aRect.Right:=aRect.Right + MLINext.Width;
    MLINext:=MLINext.Next;
  end;
  OutCaptionCellText(aCol, aRow, aRect, aState, MLI.Caption);
end;

procedure TRxDBGrid.OnIniSave(Sender: TObject);
var
  i:integer;
  S, S1:string;
  C:TRxColumn;
begin
  S:=Owner.Name+'.'+Name;
  FPropertyStorageLink.Storage.WriteInteger(S+sVersion, FVersion);
  FPropertyStorageLink.Storage.WriteInteger(S+sCount, Columns.Count);
  S:=S+sItem;
  for i:=0 to Columns.Count-1 do
  begin
    S1:=S+IntToStr(i);
    C:=TRxColumn(Columns[i]);
    FPropertyStorageLink.Storage.WriteString(S1+sCaption, StrToHexText(C.Title.Caption));
    FPropertyStorageLink.Storage.WriteInteger(S1+sWidth, C.Width);
  end;
end;

procedure TRxDBGrid.OnIniLoad(Sender: TObject);

function GetColByCaption(Cap:string):TRxColumn;
var
  i:integer;
begin
  Result:=nil;
  for i:=0 to Columns.Count - 1 do
    if Cap = Columns[i].Title.Caption then
    begin
      Result:=TRxColumn(Columns[i]);
      exit;
    end;
end;

var
  i, ACount:integer;
  S, S1, ColumName:string;
  C:TRxColumn;

begin
  S:=Owner.Name+'.'+Name;
  ACount:=FPropertyStorageLink.Storage.ReadInteger(S+sVersion, FVersion); //Check cfg version
  if ACount = FVersion then
  begin
    ACount:=FPropertyStorageLink.Storage.ReadInteger(S+sCount, 0);
    S:=S+sItem;
    for i:=0 to ACount-1 do
    begin
      S1:=S+IntToStr(i);
      ColumName:=HexTextToStr(FPropertyStorageLink.Storage.ReadString(S1+sCaption, ''));
      if ColumName<>'' then
      begin
        C:=GetColByCaption(ColumName);
        if Assigned(C) then
          C.Width:=FPropertyStorageLink.Storage.ReadInteger(S1+sWidth, C.Width);
      end;
    end;
  end;
end;

{procedure TRxDBGrid.CreateWnd;
begin
  BeginUpdate;
  try
    inherited CreateWnd;
    CalcTitle;
  finally
    EndUpdate;
  end;
end;     }

procedure TRxDBGrid.DefaultDrawCellA(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
begin
  PrepareCanvas(aCol, aRow, aState);
  if rdgFilter in OptionsRx then
  begin
     DefaultDrawFilter(aCol, aRow, getFilterRect(aRect), aState);
     DefaultDrawTitle(aCol, aRow, getTitleRect(aRect), aState);
  end
  else
      DefaultDrawTitle(aCol, aRow, aRect, aState);
end;

procedure TRxDBGrid.DefaultDrawTitle(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);

 { procedure FixRectangle;
  begin
    case Canvas.TextStyle.Alignment of
      Classes.taLeftJustify: Inc(aRect.Left, 3);
      Classes.taRightJustify: Dec(aRect.Right, 3);
    end;
    case Canvas.TextStyle.Layout of
      tlTop: Inc(aRect.Top, 3);
      tlBottom: Dec(aRect.Bottom, 3);
    end;
  end;}

var
  ASortMarker: TSortMarker;
  Background: TColor;
  i:integer;
  Down:boolean;
  aRect2: TRect;
  FTitle :TRxColumnTitle;
  GrdCol:TGridColumn;
  MLI, MLINext:TMLCaptionItem;


begin
  if (dgIndicator in Options) and (aCol=0) then
  begin
     Canvas.FillRect(aRect);
     DrawCellGrid(aCol,aRow, aRect, aState);
     exit;
  end;

  Down := FPressed and (dgHeaderPushedLook in Options) and (FPressedCol = TColumn(ColumnFromGridColumn(aCol)));

  ASortMarker := smNone;

  if (FSortField = GetFieldFromGridColumn(aCol)) then ASortMarker := FSortOrder;

  if Assigned(FOnGetBtnParams) and Assigned(GetFieldFromGridColumn(aCol)) then
  begin
    Background:=Canvas.Brush.Color;
    FOnGetBtnParams(Self, GetFieldFromGridColumn(aCol), Canvas.Font,
                    Background, ASortMarker, Down);
    Canvas.Brush.Color:=Background;
  end;

  if (gdFixed in aState) and (aRow=0) and (ACol>=FixedCols) then
  begin

    GrdCol:=ColumnFromGridColumn(aCol);
    if Assigned(GrdCol) then
      FTitle:=TRxColumnTitle(GrdCol.Title)
    else
      FTitle:=nil;

    if Assigned(FTitle) then
    begin
      if FTitle.Orientation <>  toHorizontal then
      begin
        OutCaptionCellText90(aCol, aRow, aRect, aState, FTitle.Caption, FTitle.Orientation);
        if Down then
          aState:= aState + [gdPushed];
      end
      else
      if (FTitle.CaptionLinesCount>0) then
      begin
        aRect2.Left:=aRect.Left;
        aRect2.Right:=aRect.Right;
        aRect2.Top:=aRect.Top;
        for i:=0 to FTitle.CaptionLinesCount - 1 do
        begin
          MLI:=FTitle.CaptionLine(i);
          aRect2.Right:=aRect.Right;

          if i = FTitle.CaptionLinesCount - 1 then
          begin
            aRect2.Bottom:=aRect.Bottom;
            aRect.Top:=ARect2.Top;
            if Down then
              aState:= aState + [gdPushed];
          end
          else
          begin
            aRect2.Bottom:=aRect2.Top + DefaultRowHeight;
          end;


          if Assigned(MLI.Next) then
          begin
            if Assigned(MLI.Prior) then
            begin
              if aCol = LeftCol then
                OutCaptionMLCellText(aCol, aRow, aRect2, aState, MLI);
            end
            else
              OutCaptionMLCellText(aCol, aRow, aRect2, aState, MLI);
          end
          else
          begin
            if not Assigned(MLI.Prior) then
            begin
              OutCaptionCellText(aCol, aRow, aRect2, aState, MLI.Caption);
            end
            else
            if aCol = LeftCol then
              OutCaptionMLCellText(aCol, aRow, aRect2, aState, MLI);
          end;
          aRect2.Top:=aRect2.Bottom;
        end;
      end
      else
      begin
        if Down then
          aState:= aState + [gdPushed];
        OutCaptionCellText(aCol, aRow, aRect, aState, FTitle.Caption);
      end;
    end
    else
    begin
      OutCaptionCellText(aCol, aRow, aRect, aState, GetDefaultColumnTitle(aCol));
    end;
    OutCaptionSortMarker(aRect, ASortMarker);
  end
  else
  begin
    if Down then
      aState:= aState + [gdPushed];
    OutCaptionCellText(aCol, aRow, aRect, aState, '');
  end;
end;

procedure TRxDBGrid.DefaultDrawFilter(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
var
   bg : TColor;
   al : TAlignment;
   ft : TFont;
   MyCol : integer;
   TxS:TTextStyle;

begin
  if (dgIndicator in Options) and (aCol=0) then
  begin
    Canvas.FillRect(aRect);
    DrawCellGrid(aCol,aRow, aRect, aState);
    exit;
  end;

  DrawCellGrid(aCol,aRow,aRect,aState);
  Inc(aRect.Left, 1);
  Dec(aRect.Right, 1);
  Inc(aRect.Top, 1);
  Dec(aRect.Bottom, 1);

  if Columns.Count > (aCol-1) then
  begin
    bg := Canvas.Brush.Color;
    al := Canvas.TextStyle.Alignment;
    ft := Canvas.Font;
    TxS:=Canvas.TextStyle;

    MyCol := Columns.RealIndex(aCol-1);
    with TRxColumn(Columns[MyCol]).Filter do
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(aRect);

      if Value<>'' then
      begin
        Canvas.Font := Font;
        if (aRect.Right - aRect.Left) >= Canvas.TextWidth(Value) then
          TxS.Alignment := Alignment
        else
          TxS.Alignment := taLeftJustify;
        Canvas.TextStyle:=TxS;
        DrawCellText(aCol, aRow, aRect, aState, Value)
      end
      else
      begin
        Canvas.Font := TRxColumn(Columns[MyCol]).Filter.EmptyFont;
        if (aRect.Right - aRect.Left) >= Canvas.TextWidth(Value) then
          TxS.Alignment := Alignment
        else
          TxS.Alignment := taLeftJustify;

        Canvas.TextStyle:=TxS;
        DrawCellText(aCol, aRow, aRect, aState, TRxColumn(Columns[MyCol]).Filter.EmptyValue);
      end;
    end;

    Canvas.Font := ft;
    Canvas.Brush.Color := bg;
//    Canvas.TextStyle.Alignment := al;
    TxS.Alignment := al;
    Canvas.TextStyle:=TxS;
  end
  else
  begin
    bg := Canvas.Brush.Color;
    Canvas.Brush.Color := Color;
    Canvas.FillRect(aRect);
    Canvas.Brush.Color := bg;
  end;
end;

procedure TRxDBGrid.DefaultDrawCellData(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
var
  S: string;
  F: TField;
  C:TRxColumn;
  j:integer;
begin
  if Assigned(OnDrawColumnCell) and not(CsDesigning in ComponentState) then
    OnDrawColumnCell(Self, aRect, aCol, TColumn(ColumnFromGridColumn(aCol)), aState)
  else
  begin
    F := GetFieldFromGridColumn(aCol);
    C := ColumnFromGridColumn(aCol) as TRxColumn;
    case ColumnEditorStyle(aCol, F) of
      cbsCheckBoxColumn : DrawCheckBoxBitmaps(aCol, aRect, F);
    else
      if F<>nil then
      begin
        if F.dataType <> ftBlob then
        begin
{          if Assigned(F.LookupDataSet) and (F.LookupResultField<>'') then
            S := F.LookupDataSet.FieldByName(F.LookupResultField).DisplayText
          else}
            S := F.DisplayText;
          if Assigned(C) and (C.KeyList.Count > 0) and (C.PickList.Count>0) then
          begin
            J:=C.KeyList.IndexOf(S);
            if (J>=0) and (J<C.PickList.Count) then
              S:=C.PickList[j];
          end;
        end
        else
          S := '(blob)';
      end
      else
        S := '';
      DrawCellText(aCol,aRow,aRect,aState,S);
    end;
  end
end;

procedure TRxDBGrid.DrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
var
  RxColumn:TRxColumn;
  AImageIndex:integer;
  FBackground: TColor;
begin
  if (gdFixed in aState) and (aRow=0) then
    DefaultDrawCellA(aCol, aRow, aRect, aState)
  else
  if  not ((gdFixed in aState) or (aCol=0) or (aRow=0)) then
  begin

    PrepareCanvas(aCol, aRow, aState);

    if Assigned(FOnGetCellProps) and not (gdSelected in aState) then
    begin
      FBackground:=Canvas.Brush.Color;
      FOnGetCellProps(Self, GetFieldFromGridColumn(aCol), Canvas.Font, FBackground);
      Canvas.Brush.Color:=FBackground;
    end;
    
    Canvas.FillRect(aRect);
    DrawCellGrid(aCol,aRow, aRect, aState);

    RxColumn:=TRxColumn(ColumnFromGridColumn(aCol));
    if Assigned(RxColumn) and Assigned(RxColumn.Field) and Assigned(RxColumn.ImageList) then
    begin
      AImageIndex:=StrToIntDef(RxColumn.KeyList.Values[RxColumn.Field.AsString], RxColumn.FNotInKeyListIndex);
      if (AImageIndex > -1) and (AImageIndex < RxColumn.ImageList.Count) then
        DrawCellBitmap(RxColumn, aRect, aState, AImageIndex);
    end
    else
    DefaultDrawCellData(aCol, aRow, aRect, aState);
//      inherited DrawCell(aCol, aRow, aRect, aState);
  end
  else
    inherited DrawCell(aCol, aRow, aRect, aState);
end;

procedure TRxDBGrid.LinkActive(Value: Boolean);
var
  S:string;
  Pos:integer;
begin
  inherited LinkActive(Value);
  if Value then
  begin
    S:=DataSource.DataSet.ClassName;
    if ExDBGridSortEngineList.Find(S, Pos) then
      FSortEngine:=ExDBGridSortEngineList.Objects[Pos] as TExDBGridSortEngine
    else
      FSortEngine:=nil;
  end
  else
  begin
    FSortEngine:=nil;
    if SelectedRows.Count>0 then
      SelectedRows.Clear;
  end;
  FSortField:=nil;
  FSortOrder:=smNone;
end;

procedure TRxDBGrid.DrawFooterRows;
var
  FooterRect: TRect;
  R : TRect;
  TotalYOffs: integer;
  TotalWidth: integer;
  i  : integer;
  C :TRxColumn;
  Background : TColor;
  ClipArea: Trect;
  TxS:TTextStyle;
begin
  TotalWidth := GetClientRect.Right;
  TotalYOffs:= GCache.ClientHeight;
  FooterRect := Rect(0, TotalYOffs, TotalWidth, TotalYOffs + DefaultRowHeight * FooterRowCount + 2);

  Background := Canvas.Brush.Color;
  Canvas.Brush.Color:=Color;
  Canvas.FillRect(FooterRect);

  R.Top:=TotalYOffs;
  R.Bottom:=TotalYOffs + DefaultRowHeight * FooterRowCount + 2;

  Canvas.Brush.Color := FFooterColor;
  if (Columns.Count > 0) then
  begin
    TxS:=Canvas.TextStyle;
    for i := GCache.VisibleGrid.Left to GCache.VisibleGrid.Right do
    begin
      ColRowToOffset(True, True, i, R.Left, R.Right);
      Canvas.FillRect(R);
      DrawCellGrid(i, 0, R, []);

      C := ColumnFromGridColumn(i) as TRxColumn;
      if Assigned(C) then
      begin
        TxS.Alignment:=C.Footer.Alignment;
        TxS.Layout:=C.Footer.Layout;
        Canvas.TextStyle:=TxS;
        DrawCellText(i, 0, R, [], C.Footer.DisplayText);
      end;
    end;

    ClipArea := Canvas.ClipRect;
    for i:=0 to FixedCols-1 do
    begin
      ColRowToOffset(True, True, i, R.Left, R.Right);
      DrawCellGrid(i, 0, R, [gdFixed]);
      if ((R.Left < ClipArea.Right) and (R.Right > ClipArea.Left)) then
        DrawCell(i, 0, R, [gdFixed]);
    end;
  end;
  Canvas.Brush.Color := Background;
end;

procedure TRxDBGrid.DoTitleClick(ACol: Longint; AField: TField);
begin
  if FAutoSort and (FSortEngine<>nil) and (AField<>nil) then
  begin
    if AField=FSortField then
    begin
      if FSortOrder=smUp then
        FSortOrder:=smDown
      else
        FSortOrder:=smUp;
    end
    else
    begin
      FSortField:=AField;
      FSortOrder:=smUp;
    end;
    FSortEngine.Sort(FSortField, DataSource.DataSet, FSortOrder=smUp);
  end;
//  if Assigned(FOnTitleBtnClick) then FOnTitleBtnClick(Self, ACol, AField);
end;

procedure TRxDBGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Cell: TGridCoord;
  Rect : TRect;
begin
  if FTracking then TrackButton(X, Y);
  inherited MouseMove(Shift, X, Y);

  if (rdgFilter in OptionsRx) and (dgColumnResize in Options) and (Cursor = crHSplit) then
  begin
    Cell := MouseCoord(X, Y);
    Rect := getFilterRect(CellRect(Cell.x,Cell.y));
    if (Cell.Y=0) and (Cell.X >= ord(dgIndicator in Options)) and (Rect.Top < Y) then
    begin
      Cursor := crDefault;
    end;
  end;

  if FColumnResizing and (MouseToGridZone(X,Y) = gzFixedCols) then
  begin
    CalcTitle;
    if (rdgFooterRows in OptionsRx) and (dgColumnResize in Options) and (FooterRowCount > 0) then
      DrawFooterRows;
  end;
end;

procedure TRxDBGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  Cell: TGridCoord;
  Rect : TRect;
//  X1,X2,Y1,Y2 : integer;
//  msg: TGridMessage;
//  pow : TForm;
//  curCol,curRow : integer;
//  dump : integer;
begin
  Cell := MouseCoord(X, Y);
  if (Cell.Y=0) and (Cell.X >= ord(dgIndicator in Options))  then
  begin
    if (rdgFilter in OptionsRx) and DatalinkActive then
    begin
      Cell := MouseCoord(X, Y);
      Rect := getFilterRect(CellRect(Cell.x,Cell.y));
      if (Cell.Y=0) and (Cell.X >= ord(dgIndicator in Options)) and (Rect.Top < Y) then
      begin
        if TRxColumn(Columns[Columns.RealIndex(Cell.x-1)]).Filter.ValueList.Count >0 then
        with FFilterListEditor do
        begin
          Items.Clear;
          Items.AddStrings(TRxColumn(Columns[Columns.RealIndex(Cell.x-1)]).Filter.ValueList);
          Parent:=Self;
          Width := Rect.Right-Rect.Left;
          Height := Rect.Bottom - Rect.Top;
          BoundsRect := Rect;
          Style := csDropDownList;
//          DropDownCount := TRxColumn(Columns[Columns.RealIndex(Cell.x-1)]).Filter.DropDownRows;
          Text:=TRxColumn(Columns[Columns.RealIndex(Cell.x-1)]).Filter.Value;
          Show(Self,Cell.x-1);
        end;
        exit;
      end;
    end;

    if dgColumnResize in Options then
    begin
      FColumnResizing:=true;
    end;

    if FAutoSort then
    begin
      Cell := MouseCoord(X, Y);
      if (Cell.Y=0) and (Cell.X >= ord(dgIndicator in Options))  then
      begin
        if (dgColumnResize in Options) and (Button = mbRight) then
        begin
          Button := mbLeft;
          FSwapButtons := True;
          MouseCapture := True;
          Shift:=Shift + [ssLeft];
          inherited MouseDown(Button, Shift, X, Y);
        end
        else
        if Button = mbLeft then
        begin
          if (MouseToGridZone(X,Y) = gzFixedCols) and (dgColumnResize in Options) and (Cursor=crHSplit) then
          begin
            if (ssDouble in Shift) and (rdgDblClickOptimizeColWidth in FOptionsRx) then
            begin
              if Assigned(ColumnFromGridColumn(Cell.X)) then
                TRxColumn(ColumnFromGridColumn(Cell.X)).OptimizeWidth;
            end
            else
              inherited MouseDown(Button, Shift, X, Y);
          end
          else
          begin
            MouseCapture := True;
            FTracking := True;
            FPressedCol := TColumn(ColumnFromGridColumn(Cell.X));
            TrackButton(X, Y);
          end;
        end
      end
      else
        inherited MouseDown(Button, Shift, X, Y);
    end
    else
      inherited MouseDown(Button, Shift, X, Y);
  end
  else
  begin
    if rdgMrOkOnDblClik in FOptionsRx then
    begin
      if (Cell.Y > 0) and (Cell.X >= ord(dgIndicator in Options)) and (ssDouble in Shift) then
      begin
        if Owner is TCustomForm then
          TCustomForm(Owner).ModalResult:=mrOk;
      end;
    end;
    inherited MouseDown(Button, Shift, X, Y);
  end;
end;

procedure TRxDBGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  Cell: TGridCoord;
  ACol: Longint;
  DoClick: Boolean;
begin
  FColumnResizing := false;

  if (dgHeaderPushedLook in Options) and FTracking and (FPressedCol <> nil) then
  begin
    Cell := MouseCoord(X, Y);
    DoClick := PtInRect(Rect(0, 0, ClientWidth, ClientHeight), Point(X, Y))
      and (Cell.Y < RowHeights[0]) and
      (FPressedCol = TColumn(ColumnFromGridColumn(Cell.X)));
    StopTracking;
    if DoClick then
    begin
      ACol := Cell.X;
      if (dgIndicator in Options) then Dec(ACol);
      if DataLinkActive and (ACol >= 0) and (ACol <  Columns.Count ) then
      begin
        FPressedCol := ColumnFromGridColumn(Cell.X) as TColumn;
        if Assigned(FPressedCol) then
          DoTitleClick(FPressedCol.Index, FPressedCol.Field);
      end;
    end;
  end
  else
  if FSwapButtons then begin
    FSwapButtons := False;
    MouseCapture := False;
    if Button = mbRight then Button := mbLeft;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TRxDBGrid.SetQuickUTF8Search(AValue : String);
var
  ClearSearchValue : Boolean;
  OldSearchString : String;
begin
  if ( rdgAllowQuickSearch in OptionsRx ) then
  begin
    OldSearchString := Self.FQuickUTF8Search;
    if (OldSearchString <> AValue ) and Assigned(Self.FBeforeQuickSearch) then
       Self.FBeforeQuickSearch(Self, SelectedField, AValue);
    if OldSearchString <> AValue then
    begin
      ClearSearchValue := True;
      if ( Length(AValue) > 0 ) and ( Self.DatalinkActive ) then
      begin
        if (DataSource.DataSet.State = dsBrowse) and (not (DataSource.DataSet.EOF and DataSource.DataSet.BOF)) then
        begin
          //1.Вызываем процедурку поиска...
          if DataSetLocateThrough(Self.DataSource.DataSet, Self.SelectedField.FieldName,AValue,[loPartialKey,loCaseInsensitive]) then
             Self.FQuickUTF8Search := AValue;
           ClearSearchValue := False;
        end;
      end;
      if ClearSearchValue then
      begin
        Self.FQuickUTF8Search := '';
      end;
      if (OldSearchString <> Self.FQuickUTF8Search ) and Assigned(Self.FAfterQuickSearch) then
        Self.FAfterQuickSearch(Self, SelectedField, OldSearchString);
     end
  end;
 //TODO: сделать отображение ищущейся буквы/строки.
end;

procedure TRxDBGrid.UTF8KeyPress(var UTF8Key: TUTF8Char);
var
  CheckUp : Boolean;
begin
  inherited UTF8KeyPress(UTF8Key);
  if ReadOnly then
  begin
    //0. Проверяем что это кнопка значащая, увеличиваем "строку поиска"
    if Length(UTF8Key) = 1 then
    begin
        //DebugLn('Ord Of Key:',IntToStr(Ord(UTF8Key[1])));
        CheckUp := not ( Ord(UTF8Key[1]) in CBadQuickSearchSymbols )
    end
    else
      CheckUp := True;
  //  DebugLn('RxDBGrid.UTF8KeyPress check',IfThen(CheckUp,'True','False'),'INIT UTF8Key= ',UTF8Key,' Selected Field: ', Self.SelectedField.FieldName);
    if CheckUp then
      QuickUTF8Search := QuickUTF8Search + Trim(UTF8Key);
  end;
end;

procedure TRxDBGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  FTmpReadOnly:boolean;
begin
  //DebugLn('RxDBGrid.KeyDown ',Name,' INIT Key= ',IntToStr(Key));
  if (Key in CCancelQuickSearchKeys) then
    if Length(QuickUTF8Search) > 0 then QuickUTF8Search := '';
  case Key of
    ord('F'):begin
               if (ssCtrl in Shift) and (rdgAllowDialogFind in OptionsRx) then
               begin
                 if Length(QuickUTF8Search) > 0 then QuickUTF8Search := '';
                 ShowFindDialog;
                 exit;
               end;
             end;
    ord('W'):begin
               if (ssCtrl in Shift) and (rdgAllowColumnsForm in OptionsRx) then
               begin
                 if Length(QuickUTF8Search) > 0 then QuickUTF8Search := '';
                 ShowColumnsDialog;
                 exit;
               end;
             end;
    VK_DELETE:if not (aoDelete in FAllowedOperations) then exit;
    VK_INSERT:if not (aoInsert in FAllowedOperations) then exit;
    VK_DOWN:if not (aoAppend in FAllowedOperations) then
      begin
        FTmpReadOnly:=ReadOnly;
        ReadOnly:=true;
        inherited KeyDown(Key, Shift);
        ReadOnly:=FTmpReadOnly;
        exit;
      end;
  end;
  inherited KeyDown(Key, Shift);
end;

function TRxDBGrid.CreateColumns: TGridColumns;
begin
  Result := TRxDbGridColumns.Create(Self, TRxColumn);
end;

procedure TRxDBGrid.DrawCellBitmap(RxColumn: TRxColumn; aRect: TRect;
  aState: TGridDrawState; AImageIndex: integer);
var
  ClientSize: TSize;
  H, W: Integer;
begin
  InflateRect(aRect, -1, -1);

  H := RxColumn.ImageList.Height;
  W := RxColumn.ImageList.Width;

  ClientSize.cx:= Min(aRect.Right - aRect.Left, W);
  ClientSize.cy:= Min(aRect.Bottom - aRect.Top, H);

  if ClientSize.cx = W then
  begin
    aRect.Left:= (aRect.Left + aRect.Right - W) div 2;
    aRect.Right:=aRect.Left + W;
  end;

  if ClientSize.cy = H then
  begin
    aRect.Top:= (aRect.Top + aRect.Bottom - H) div 2;
    aRect.Bottom:=aRect.Top + H;
  end;

  RxColumn.ImageList.StretchDraw(Canvas, AImageIndex, aRect);
end;

procedure TRxDBGrid.SetEditText(ACol, ARow: Longint; const Value: string);
var
  C:TRxColumn;
  j:integer;
  S:string;
begin
  C := ColumnFromGridColumn(aCol) as TRxColumn;
  S:=Value;
  if Assigned(C) and (C.KeyList.Count>0) and (C.PickList.Count>0) then
  begin
    J:=C.PickList.IndexOf(S);
    if (J>=0) and (J<C.KeyList.Count) then
      S:=C.KeyList[j];
  end;
  inherited SetEditText(ACol, ARow, S);
end;

procedure TRxDBGrid.CheckNewCachedSizes(var AGCache: TGridDataCache);
begin
  if (rdgFooterRows in OptionsRx) and (FooterRowCount > 0) then
    Dec(GCache.ClientHeight, DefaultRowHeight * FooterRowCount + 2);
end;

procedure TRxDBGrid.ColRowMoved(IsColumn: Boolean; FromIndex, ToIndex: Integer
  );
begin
  inherited ColRowMoved(IsColumn, FromIndex, ToIndex);
  if IsColumn then
    CalcTitle;
end;

procedure TRxDBGrid.Paint;
begin
  inherited Paint;
  if (rdgFooterRows in OptionsRx) and (FooterRowCount > 0) then
    DrawFooterRows;
end;

procedure TRxDBGrid.UpdateActive;
begin
  if FInProcessCalc>0 then exit;
  inherited UpdateActive;
{  if (rdgFooterRows in OptionsRx) and (FooterRowCount > 0) then
    CalcStatTotals;}
end;

procedure TRxDBGrid.UpdateData;
begin
  inherited UpdateData;
end;

procedure TRxDBGrid.MoveSelection;
begin
  inherited MoveSelection;
  if (rdgFooterRows in OptionsRx) and (FooterRowCount > 0) then
    DrawFooterRows;
end;

procedure TRxDBGrid.CMHintShow(var Message: TLMessage);
var
  Cell : TGridCoord;
  tCol  : TRxColumn;
begin
  if Assigned(TCMHintShow(Message).HintInfo) then
  begin
    with TCMHintShow(Message).HintInfo^ do
    begin
      Cell := MouseCoord(CursorPos.X, CursorPos.Y);
      if (Cell.Y=0) and (Cell.X >= ord(dgIndicator in Options)) then
      begin
        tCol:=TRxColumn(ColumnFromGridColumn(Cell.X));
        if Assigned(tCol) and (TRxColumnTitle(tCol.Title).Hint <> '') and (TRxColumnTitle(tCol.Title).FShowHint) then
          HintStr:=TRxColumnTitle(tCol.Title).Hint;
      end;
    end;
  end;
  inherited CMHintShow(Message);
end;

procedure TRxDBGrid.FFilterListEditorOnChange(Sender: TObject);
begin
  FFilterListEditor.Hide;
  with TRxColumn(Columns[Columns.RealIndex(FFilterListEditor.Col)]).Filter do
  begin
    if FFilterListEditor.Text = EmptyValue then
      Value := ''
    else
      Value := FFilterListEditor.Text
  end;
  if Assigned(FOnFiltred) then
    FOnFiltred(Self);
end;

procedure TRxDBGrid.FFilterListEditorOnCloseUp(Sender: TObject);
begin
  FFilterListEditor.Hide;
  FFilterListEditor.Changed;
  SetFocus;
end;

procedure TRxDBGrid.InternalOptimizeColumnsWidth(AColList: TList);
var
  P:TBookmark;
  i, W:integer;
  WA:PIntegerArray;
begin
  GetMem(WA, SizeOf(Integer) * AColList.Count);

  for I := 0 to AColList.Count-1 do
    WA^[i]:=20;

  with DataSource.DataSet do
  begin
    DisableControls;
    P:=GetBookmark;
    First;
    try
      while not Eof do
      begin
        for I := 0 to AColList.Count-1 do
        begin
          W:=Canvas.TextWidth(TRxColumn(AColList[i]).Field.DisplayText) + 6;
          if WA^[i]<W then
            WA^[i]:=W;
        end;
        Next;
      end;
    finally
      GotoBookmark(p);
      FreeBookmark(p);
      EnableControls;
    end;
  end;

  for I := 0 to AColList.Count-1 do
    if WA^[i]>0 then
      TRxColumn(AColList[i]).Width:=WA^[i];
      
  FreeMem(WA, SizeOf(Integer) * AColList.Count);
end;

function TRxDBGrid.IsDefaultRowHeightStored: boolean;
begin
  Result:=DefaultRowHeight = Canvas.TextHeight('W');
end;

procedure TRxDBGrid.VisualChange;
begin
  inherited VisualChange;
//  if Canvas.HandleAllocated then
  CalcTitle;
end;

function TRxDBGrid.EditorByStyle(Style: TColumnButtonStyle): TWinControl;
var
  F:TField;
begin
  if Style = cbsAuto then
  begin
    F:=SelectedField;
    if Assigned(F) then
    begin
      if Assigned(F.LookupDataSet) and (F.LookupKeyFields<>'') and (F.LookupResultField<>'') and (F.KeyFields<>'') then
      begin
        Result:=FRxDbGridLookupComboEditor;
        exit;
      end
      else
      if F.DataType in [ftDate, ftDateTime] then
      begin
        Result:=FRxDbGridDateEditor;
        exit;
      end;
    end
  end;
  Result:=inherited EditorByStyle(Style);
end;

procedure TRxDBGrid.CalcStatTotals;
var
  P:TBookmark;
  DS:TDataSet;
  i:integer;
//  J:integer;
begin
  if (not ((rdgFooterRows in OptionsRx) and DatalinkActive)) or (Columns.Count = 0) then
    Exit;
  inc(FInProcessCalc);
  DS:=DataSource.DataSet;;
  P := Ds.GetBookMark;
  DS.DisableControls;
  try
    for i:=0 to Columns.Count - 1 do
      TRxColumn(Columns[i]).Footer.ResetTestValue;
    
    DS.First;
    while not DS.EOF do
    begin
      for i:=0 to Columns.Count - 1 do
        TRxColumn(Columns[i]).Footer.UpdateTestValue;
      DS.Next;
    end;
  finally
    DS.GotoBookmark(P);
    DS.FreeBookmark(P);
    DS.EnableControls;
  end;

  Dec(FInProcessCalc);
  if FInProcessCalc<0 then FInProcessCalc:=0;
end;

procedure TRxDBGrid.OptimizeColumnsWidth(AColList: String);
var
  ColList:TList;
  
procedure DoFillColList;
var
  L:integer;
begin
  L:=Pos(';', AColList);
  while L>0 do
  begin
    if AColList<>'' then
      ColList.Add(ColumnByFieldName(Copy(AColList, 1, L-1)));
    Delete(AColList, 1, L);
    L:=Pos(';', AColList);
  end;
  if AColList<>'' then
    ColList.Add(ColumnByFieldName(AColList));
end;

begin
  if (not DatalinkActive) or (Columns.Count = 0) then Exit;
  ColList:=TList.Create;
  DoFillColList;
  InternalOptimizeColumnsWidth(ColList);
  ColList.Free;
end;

procedure TRxDBGrid.OptimizeColumnsWidthAll;
var
  ColList:TList;
  i:integer;
begin
  if (not DatalinkActive) or (Columns.Count = 0) then Exit;
  ColList:=TList.Create;
  for i:=0 to Columns.Count-1 do
    ColList.Add(Columns[i]);
  InternalOptimizeColumnsWidth(ColList);
  ColList.Free;
end;

procedure TRxDBGrid.UpdateTitleHight;
begin
  CalcTitle;
end;

constructor TRxDBGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF RXDBGRID_OPTIONS_WO_CANCEL_ON_EXIT}
  Options:=Options - [dgCancelOnExit];
{$ENDIF}

  FMarkerUp := LoadLazResBitmapImage('rx_markerup');
  FMarkerDown := LoadLazResBitmapImage('rx_markerdown');

  FPropertyStorageLink:=TPropertyStorageLink.Create;
  FPropertyStorageLink.OnSave:=@OnIniSave;
  FPropertyStorageLink.OnLoad:=@OnIniLoad;

//  FTitleLines := TITLE_DEFAULT;
  FAllowedOperations:=[aoInsert, aoUpdate, aoDelete, aoAppend];
  
  FFooterColor:=clWindow;
  FFooterRowCount:=0;

  FFilterListEditor := TFilterListCellEditor.Create(nil);
  with FFilterListEditor do
  begin
    Name := 'FilterListEditor';
    Visible := False;
    Items.Append('');
    ReadOnly := true;
    AutoComplete := true;
    OnChange := @FFilterListEditorOnChange;
    OnCloseUp := @FFilterListEditorOnCloseUp;
  end;
  FColumnResizing := false;

  FRxDbGridLookupComboEditor:=TRxDBGridLookupComboEditor.Create(nil);
  FRxDbGridLookupComboEditor.Name:='RxDBGridLookupComboEditor';
  FRxDbGridLookupComboEditor.Visible:=false;
  
  FRxDbGridDateEditor:=TRxDBGridDateEditor.Create(nil);
  FRxDbGridDateEditor.Name:='RxDbGridDateEditor';
  FRxDbGridDateEditor.Visible:=false;
end;

destructor TRxDBGrid.Destroy;
begin
  FreeAndNil(FRxDbGridLookupComboEditor);
  FreeAndNil(FRxDbGridDateEditor);
  FreeAndNil(FMarkerDown);
  FreeAndNil(FMarkerUp);
  FreeAndNil(FPropertyStorageLink);
  FreeAndNil(FFilterListEditor);
  inherited Destroy;
end;

procedure TRxDBGrid.LayoutChanged;
begin
  inherited LayoutChanged;
//  CalcTitle;
end;

procedure TRxDBGrid.ShowFindDialog;
begin
  ShowRxDBGridFindForm(Self);
end;

procedure TRxDBGrid.ShowColumnsDialog;
begin
  ShowRxDBGridColumsForm(Self);
end;

function TRxDBGrid.ColumnByFieldName(AFieldName: string): TRxColumn;
var
  i:integer;
begin
  Result:=nil;
  AFieldName:=UpperCase(AFieldName);
  for i:=0 to Columns.Count - 1 do
  begin
    if UpperCase(Columns[i].FieldName)=AFieldName then
    begin
      Result:=Columns[i] as TRxColumn;
      exit;
    end;
  end;
end;

{ TRxDbGridColumns }
function TRxDbGridColumns.Add: TRxColumn;
begin
  result := TRxColumn( inherited Add);
end;

{ TRxColumn }

function TRxColumn.GetKeyList: TStrings;
begin
  if FKeyList=nil then
    FKeyList := TStringList.Create;
  Result := FKeyList;
end;

procedure TRxColumn.SetFilter(const AValue: TRxColumnFilter);
begin
  FFilter.Assign(AValue);
end;

function TRxColumn.GetFooter: TRxColumnFooter;
begin
  Result:=FFooter;
end;

procedure TRxColumn.SetFooter(const AValue: TRxColumnFooter);
begin
  FFooter.Assign(AValue);
end;

procedure TRxColumn.SetImageList(const AValue: TImageList);
begin
  if FImageList=AValue then exit;
  FImageList:=AValue;
  if Grid <> nil then
    Grid.Invalidate;
end;

procedure TRxColumn.SetKeyList(const AValue: TStrings);
begin
  if AValue=nil then
  begin
    if FKeyList<>nil then
      FKeyList.Clear
  end
  else
    KeyList.Assign(AValue);
end;

procedure TRxColumn.SetNotInKeyListIndex(const AValue: Integer);
begin
  if FNotInKeyListIndex=AValue then exit;
  FNotInKeyListIndex:=AValue;
  if Grid <> nil then
    Grid.Invalidate;
end;

function TRxColumn.CreateTitle: TGridColumnTitle;
begin
  Result:=TRxColumnTitle.Create(Self);
end;

constructor TRxColumn.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FNotInKeyListIndex:=-1;
  FFooter:=TRxColumnFooter.Create(Self);
  FFilter := TRxColumnFilter.Create(Self);
end;

destructor TRxColumn.destroy;
begin
  if FKeyList<>nil then
  begin
    FKeyList.Free;
    FKeyList:=nil;
  end;
  FreeAndNil(FFooter);
  FreeAndNil(FFilter);
  inherited destroy;
end;

procedure TRxColumn.OptimizeWidth;
begin
  if Grid <> nil then
    TRxDBGrid(Grid).OptimizeColumnsWidth(FieldName);
end;

{ TRxColumnTitle }
procedure TRxColumnTitle.SetOrientation(const AValue: TTextOrientation);
begin
  if FOrientation=AValue then exit;
  FOrientation:=AValue;
  TRxDBGrid(TRxColumn(Column).Grid).CalcTitle;
  TRxColumn(Column).ColumnChanged;
end;

function TRxColumnTitle.GetCaptionLinesCount: integer;
begin
  if Assigned(FCaptionLines) then
    Result:=FCaptionLines.Count
  else
    Result:=0;
end;

function TRxColumnTitle.CaptionLine(ALine:integer):TMLCaptionItem;
begin
  if Assigned(FCaptionLines) and (FCaptionLines.Count>0) and (ALine>=0) and (FCaptionLines.Count>ALine) then
    Result:=TMLCaptionItem(FCaptionLines[ALine])
  else
    Result:=nil;
end;

procedure TRxColumnTitle.ClearCaptionML;
var
  i:integer;
  R:TMLCaptionItem;
begin
  for i:=0 to FCaptionLines.Count - 1 do
  begin
    R:=TMLCaptionItem(FCaptionLines[i]);
    R.Free;
  end;
  FCaptionLines.Clear;
end;

procedure TRxColumnTitle.SetCaption(const AValue: TCaption);
var
  c:integer;
  s:string;

procedure AddMLStr(AStr:string);
var
  R:TMLCaptionItem;
begin
  R:=TMLCaptionItem.Create;
  R.Caption:=AStr;
  FCaptionLines.Add(R);
end;

begin
  inherited SetCaption(AValue);
  ClearCaptionML;
  c:=Pos('|', AValue);
  if C>0 then
  begin
    S:=AValue;
    while C>0 do
    begin
      AddMLStr(Copy(S, 1, C-1));
      System.Delete(S, 1, C);
      c:=Pos('|', S);
    end;
    if S<>'' then
      AddMLStr(S);
  end;
  if not (csLoading in Column.Grid.ComponentState) and Column.Grid.HandleAllocated then
    TRxDBGrid(Column.Grid).CalcTitle;
end;

constructor TRxColumnTitle.Create(TheColumn: TGridColumn);
begin
  inherited Create(TheColumn);
{$IFDEF NEW_STYLE_TITLE_ALIGNMENT_RXDBGRID}
  Alignment:=taCenter;
{$ENDIF}
  FCaptionLines:=TFPList.Create;
end;

destructor TRxColumnTitle.Destroy;
begin
  ClearCaptionML;
  FreeAndNil(FCaptionLines);
  inherited Destroy;
end;

{ TRxColumnFooter }

procedure TRxColumnFooter.SetValue(const AValue: String);
begin
  if FValue=AValue then exit;
  FValue:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFooter.SetDisplayFormat(const AValue: String);
begin
  if FDisplayFormat=AValue then exit;
  FDisplayFormat:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFooter.SetAlignment(const AValue: TAlignment);
begin
  if FAlignment=AValue then exit;
  FAlignment:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFooter.SetFieldName(const AValue: String);
begin
  if FFieldName=AValue then exit;
  FFieldName:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFooter.SetLayout(const AValue: TTextLayout);
begin
  if FLayout=AValue then exit;
  FLayout:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFooter.SetValueType(const AValue: TFooterValueType);
begin
  if FValueType=AValue then exit;
  FValueType:=AValue;
  if FValueType in [fvtSum, fvtAvg, fvtMax, fvtMin] then
    TRxDBGrid(FOwner.Grid).CalcStatTotals;
  FOwner.ColumnChanged;
end;

function TRxColumnFooter.DisplayText: string;
begin
  case FValueType of
    fvtSum,
    fvtAvg,
    fvtMax,
    fvtMin:Result:=GetStatTotal;
    fvtCount:Result:=GetRecordsCount;
    fvtFieldValue:Result:=GetFieldValue;
    fvtStaticText:Result:=FValue;
    fvtRecNo:Result:=GetRecNo;
  else
    Result:='';
  end;
end;

function TRxColumnFooter.GetFieldValue: string;
begin
  if (FFieldName<>'') and TRxDBGrid(FOwner.Grid).DatalinkActive then
    Result:=TRxDBGrid(FOwner.Grid).DataSource.DataSet.FieldByName(FFieldName).AsString
  else
    Result:='';
end;

function TRxColumnFooter.GetRecordsCount: string;
begin
  if TRxDBGrid(FOwner.Grid).DatalinkActive then
  begin
    if DisplayFormat <> '' then
      Result:=Format(DisplayFormat, [TRxDBGrid(FOwner.Grid).DataSource.DataSet.RecordCount])
    else
      Result:=IntToStr(TRxDBGrid(FOwner.Grid).DataSource.DataSet.RecordCount);
  end
  else
    Result:='';
end;

function TRxColumnFooter.GetRecNo: string;
begin
  if TRxDBGrid(FOwner.Grid).DatalinkActive then
  begin
    if DisplayFormat <> '' then
      Result:=Format(DisplayFormat, [TRxDBGrid(FOwner.Grid).DataSource.DataSet.RecNo])
    else
      Result:=IntToStr(TRxDBGrid(FOwner.Grid).DataSource.DataSet.RecNo);
  end
  else
    Result:='';
end;

function TRxColumnFooter.GetStatTotal: string;
var
  F:TField;
begin
  if (FFieldName<>'') and TRxDBGrid(FOwner.Grid).DatalinkActive then
  begin
    F:=TRxDBGrid(FOwner.Grid).DataSource.DataSet.FieldByName(FFieldName);
    if Assigned(F) then
    begin
      if F.DataType in [ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency,
                        ftDate,  ftTime, ftDateTime, ftTimeStamp] then
      begin
        if F.DataType in [ftDate,  ftTime, ftDateTime, ftTimeStamp] then
        begin
          if FValueType in [fvtSum, fvtAvg] then
            Result:=''
          else
          if FDisplayFormat = '' then
            Result:=DateToStr(FTestValue)
          else
            Result:=FormatDateTime(FDisplayFormat, FTestValue);
        end
        else
        if F.DataType in [ftSmallint, ftInteger, ftWord] then
        begin
          if FDisplayFormat = '' then
            Result:=IntToStr(Round(FTestValue))
          else
            Result:=Format(FDisplayFormat, [Round(FTestValue)]);
        end
        else
        begin
          if FDisplayFormat <> '' then
            Result:=FormatFloat(FDisplayFormat, FTestValue)
          else
            if F.DataType = ftCurrency then
              Result:=FloatToStrF(FTestValue, ffCurrency, 12, 2)
            else
              Result:=FloatToStr(FTestValue);
        end
      end
      else
        Result:='';
    end
    else
      Result:='';
  end
  else
    Result:='';
end;

procedure TRxColumnFooter.ResetTestValue;
begin
  FTestValue:=0;
end;

procedure TRxColumnFooter.UpdateTestValue;
var
  F:TField;
begin
  if ValueType in [fvtSum, fvtAvg, fvtMax, fvtMin] then
  begin
    F:=TRxDBGrid(FOwner.Grid).DataSource.DataSet.FieldByName(FFieldName);
    if Assigned(F) then
    begin
      if F.DataType in [ftDate,  ftTime, ftDateTime, ftTimeStamp] then
      begin
        case FValueType of
          fvtMax:FTestValue:=Max(FTestValue, F.AsDateTime);
          fvtMin:FTestValue:=Min(FTestValue, F.AsDateTime);
        end;
      end
      else
      begin
        case FValueType of
          fvtSum:FTestValue:=FTestValue+F.AsFloat;
  //        fvtAvg:
          fvtMax:FTestValue:=Max(FTestValue, F.AsFloat);
          fvtMin:FTestValue:=Min(FTestValue, F.AsFloat);
        end;
      end;
    end;
  end;
end;

constructor TRxColumnFooter.Create(Owner: TRxColumn);
begin
  inherited Create;
  FOwner:=Owner;
  FTestValue:=0;
  FLayout:=tlCenter;
end;

{ TFilterListCellEditor }

procedure TFilterListCellEditor.WndProc(var TheMessage: TLMessage);
begin

  if TheMessage.msg=LM_KILLFOCUS then
  begin
    Change;
    Hide;
    if HWND(TheMessage.WParam) = HWND(Handle) then begin
      // lost the focus but it returns to ourselves
      // eat the message.
      TheMessage.Result := 0;
      exit;
    end;
  end;
  inherited WndProc(TheMessage);
end;

procedure TFilterListCellEditor.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key,Shift);
  case Key of
    VK_RETURN:
    begin
       DroppedDown := False;
       Change;
       Hide;
    end;
  end;
end;

procedure TFilterListCellEditor.Show(Grid: TCustomGrid; Col: Integer);
begin
  FGrid := Grid;
  FCol := Col;
  Visible := true;
//  Text:=TRxColumn(TRxDBGrid(Grid).SelectedColumn).Filter.Value;
  SetFocus;
//  DroppedDown := true;
end;


{ TRxColumnFilter }

function TRxColumnFilter.GetItemIndex: integer;
begin
  Result:=FValueList.IndexOf(FValue);
end;

procedure TRxColumnFilter.SetColor(const AValue: TColor);
begin
  if FColor = AValue then exit;
  FColor:=AValue;
  FOwner.ColumnChanged;
end;

procedure TRxColumnFilter.SetFont(const AValue: TFont);
begin
  FFont.Assign(AValue);
  FOwner.ColumnChanged;
end;

procedure TRxColumnFilter.SetItemIndex(const AValue: integer);
begin
  if (AValue>=-1) and (AValue<FValueList.Count) then
  begin
    if AValue=-1 then
      FValue:=''
    else
      FValue:=FValueList[AValue];
    FOwner.ColumnChanged;
  end
end;

constructor TRxColumnFilter.Create(Owner:TRxColumn);
begin
  inherited Create;
  FOwner:=Owner;
  FFont := TFont.Create;
  FEmptyFont := TFont.Create;
  FValueList := TStringList.Create;
  FColor := clWhite;
end;

destructor TRxColumnFilter.Destroy;
begin
  FreeAndNil(FFont);
  FreeAndNil(FEmptyFont);
  FreeAndNil(FValueList);
  inherited Destroy;
end;

initialization
  {$I rxdbgrid.lrs}
//  {$I rx_markerdown.lrs}

  ExDBGridSortEngineList:=TStringList.Create;
  ExDBGridSortEngineList.Sorted:=true;
finalization
  while (ExDBGridSortEngineList.Count>0) do
  begin
    ExDBGridSortEngineList.Objects[0].Free;
    ExDBGridSortEngineList.Delete(0);
  end;
  ExDBGridSortEngineList.Free;
end.

