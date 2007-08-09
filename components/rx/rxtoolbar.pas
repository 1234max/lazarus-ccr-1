unit rxtoolbar;

{$I rx.inc}

interface

uses
  Classes, SysUtils, Types, LCLType, LCLIntf, Buttons, Controls, ExtCtrls, ActnList,
  PropertyStorage, Menus, Forms;

const
  DefButtonWidth = 24;
  DefButtonHeight = 23;

type
  TToolPanel = class;
  TToolbarItem = class;
  TToolbarButtonStyle = (tbrButton, tbrCheck, tbrDropDown, tbrSeparator, tbrDivider);
  TToolBarStyle = (tbsStandart, tbsWindowsXP);

  TToolPanelOption = (tpFlatBtns, tpTransparentBtns, tpStretchBitmap,
       tpCustomizable, tpGlyphPopup, tpCaptionPopup);
  TToolPanelOptions = set of TToolPanelOption;

  { TToolbarButtonActionLink }

  TToolbarButtonActionLink = class(TSpeedButtonActionLink)
  protected
    procedure SetImageIndex(Value: Integer); override;
    function IsImageIndexLinked: Boolean; override;
  end;
  
  TToolbarButtonActionLinkClass = class of TToolbarButtonActionLink;
  
  { TToolbarButton }
  TToolbarButton = class(TCustomSpeedButton)
  private
    FDesign:boolean;
    FDesignX,
    FDesignY:integer;
    FDrag:boolean;
    FImageList:TImageList;
    FDropDownMenu:TPopupMenu;
    FShowCaption:boolean;
    FToolbarButtonStyle:TToolbarButtonStyle;
    FLastDrawFlagsA:integer;
    FAutoSize:boolean;
    FOwnerItem:TToolbarItem;
    function IsDesignMode:boolean;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Paint; override;
    procedure Click; override;
    procedure UpdateState(InvalidateOnChange: boolean); override;
    procedure SetDesign(AValue:boolean; AToolbarItem:TToolbarItem);
    procedure SetAutoSize(AValue:boolean);
    procedure UpdateSize;
    procedure SetEnabled(NewEnabled: boolean); override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    function GetDrawFlags: integer; virtual;
  public
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); override;
    destructor Destroy; override;
  end;

  { TToolbarItem }

  TToolbarItem = class(TCollectionItem)
  private
    FButton: TToolbarButton;
//    FActionLink:TActionLink;
    function GetAction: TBasicAction;
    function GetAutoSize: boolean;
    function GetButtonStyle: TToolbarButtonStyle;
    function GetDropDownMenu: TPopupMenu;
    function GetGroupIndex: Integer;
    function GetHeight: Integer;
    function GetLayout: TButtonLayout;
    function GetLeft: Integer;
    function GetShowCaption: boolean;
    function GetTag: Longint;
    function GetTop: Integer;
    function GetVisible: boolean;
    function GetWidth: Integer;
//    procedure OnActionChanges(Sender: TObject);
    procedure SetAction(const AValue: TBasicAction);
    procedure SetAutoSize(const AValue: boolean);
    procedure SetButtonStyle(const AValue: TToolbarButtonStyle);
    procedure SetDropDownMenu(const AValue: TPopupMenu);
    procedure SetGroupIndex(const AValue: Integer);
    procedure SetHeight(const AValue: Integer);
    procedure SetLayout(const AValue: TButtonLayout);
    procedure SetLeft(const AValue: Integer);
    procedure SetShowCaption(const AValue: boolean);
    procedure SetTag(const AValue: Longint);
    procedure SetTop(const AValue: Integer);
    procedure SetVisible(const AValue: boolean);
    procedure SetWidth(const AValue: Integer);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
  published
    property Action:TBasicAction read GetAction write SetAction;
    property AutoSize:boolean read GetAutoSize write SetAutoSize default true;
    property Visible:boolean read GetVisible write SetVisible;
    property Left: Integer read GetLeft write SetLeft;
    property Height: Integer read GetHeight write SetHeight;
    property Top: Integer read GetTop write SetTop;
    property Width: Integer read GetWidth write SetWidth;
    property DropDownMenu: TPopupMenu read GetDropDownMenu write SetDropDownMenu;
    property ShowCaption:boolean read GetShowCaption write SetShowCaption;
    property GroupIndex: Integer read GetGroupIndex write SetGroupIndex default 0;
    property Layout: TButtonLayout read GetLayout write SetLayout default blGlyphLeft;
    property ButtonStyle:TToolbarButtonStyle read GetButtonStyle write SetButtonStyle default tbrButton;
    property Tag: Longint read GetTag write SetTag default 0;
  end;

  { TToolbarItems }

  TToolbarItems = class(TCollection)
  private
    FToolPanel:TToolPanel;
    function GetByActionName(ActionName: string): TToolbarItem;
    function GetToolbarItem(Index: Integer): TToolbarItem;
    procedure SetToolbarItem(Index: Integer; const AValue: TToolbarItem);
  public
    constructor Create(ToolPanel: TToolPanel);
    property Items[Index: Integer]: TToolbarItem read GetToolbarItem write SetToolbarItem; default;
    property ByActionName[ActionName:string]:TToolbarItem read GetByActionName;
  end;

  { TToolPanel }

  TToolPanel = class(TCustomPanel)
  private
    FImageList: TImageList;
    FOptions: TToolPanelOptions;
    FPropertyStorageLink:TPropertyStorageLink;
    FToolbarItems:TToolbarItems;
    FDefButtonWidth:integer;
    FDefButtonHeight:integer;
    FToolBarStyle: TToolBarStyle;
    FVersion: Integer;
    function GetBtnHeight: Integer;
    function GetBtnWidth: Integer;
    function GetItems: TToolbarItems;
    function GetPropertyStorage: TCustomPropertyStorage;
    procedure SetBtnHeight(const AValue: Integer);
    procedure SetBtnWidth(const AValue: Integer);
    procedure SetImageList(const AValue: TImageList);
    procedure SetItems(const AValue: TToolbarItems);
    procedure SetOptions(const AValue: TToolPanelOptions);
    procedure SetPropertyStorage(const AValue: TCustomPropertyStorage);
    procedure OnIniSave(Sender: TObject);
    procedure OnIniLoad(Sender: TObject);
    procedure SetToolBarStyle(const AValue: TToolBarStyle);
  protected
    FCustomizer:TForm;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetCustomizing(AValue:boolean);
    procedure DoAutoSize; Override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Customize(HelpCtx: Longint);
  published
    property Items:TToolbarItems read GetItems write SetItems;
    property ImageList:TImageList read FImageList write SetImageList;
    property PropertyStorage:TCustomPropertyStorage read GetPropertyStorage write SetPropertyStorage;
    property BtnWidth: Integer read GetBtnWidth write SetBtnWidth default DefButtonWidth;
    property BtnHeight: Integer read GetBtnHeight write SetBtnHeight default DefButtonHeight;
    property ToolBarStyle:TToolBarStyle read FToolBarStyle write SetToolBarStyle default tbsStandart;
    property Options:TToolPanelOptions read FOptions write SetOptions;
    property Version: Integer read FVersion write FVersion default 0;

    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderWidth;
    property BorderStyle;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DragMode;
    property Enabled;
    property Font;
    property FullRepaint;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
  end;

implementation
uses Math, Graphics, RxTBRSetup, LCLProc, vclutils, Dialogs, typinfo, rxdconst;

{ TToolbarButton }

function TToolbarButton.IsDesignMode: boolean;
begin
  Result:=(Assigned(Parent) and (csDesigning in Parent.ComponentState)) or (FDesign);
end;

procedure TToolbarButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if IsDesignMode  then
  begin
    FDrag:=true;
    FDesignX:=Max(X-1, 1);
    FDesignY:=Max(Y-1, 1);
  end
  else
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TToolbarButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if IsDesignMode and FDrag then
  begin
    Top:=Max(0, Min(Y+Top-FDesignY, Parent.Height - Height));
    Left:=Max(0, Min(X+Left-FDesignX, Parent.Width - Width));
  end
  else
  inherited MouseMove(Shift, X, Y);
end;

procedure TToolbarButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if IsDesignMode  then
  begin
    FDrag:=false;
    Top:=4;
  end
  else
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TToolbarButton.Paint;
var
  PaintRect: TRect;
  GlyphWidth, GlyphHeight: Integer;
  Offset, OffsetCap: TPoint;
  ClientSize, TotalSize, TextSize: TSize;
  //BrushStyle : TBrushStyle;
  M, S : integer;
  TXTStyle : TTextStyle;
  SIndex : Longint;
  TMP : String;
begin
  UpdateState(false);
  if not Assigned(Action) then exit;
  PaintRect:=ClientRect;
  if (Action is TCustomAction) and Assigned(FImageList) and
     (TCustomAction(Action).ImageIndex>-1) and
     (TCustomAction(Action).ImageIndex < FImageList.Count) then
  begin

    FLastDrawFlagsA:=GetDrawFlags;

    if not Transparent then
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(PaintRect);
    end;

    if FLastDrawFlagsA <> 0 then
    begin
      if TToolbarItems(FOwnerItem.Collection).FToolPanel.FToolBarStyle = tbsWindowsXP then
        DrawButtonFrameXP(Canvas, PaintRect, (FLastDrawFlagsA and DFCS_PUSHED) <> 0,
                                         (FLastDrawFlagsA and DFCS_FLAT) <> 0)
      else
        DrawButtonFrame(Canvas, PaintRect, (FLastDrawFlagsA and DFCS_PUSHED) <> 0,
                                         (FLastDrawFlagsA and DFCS_FLAT) <> 0);
    end;
    GlyphWidth:= FImageList.Width;
    GlyphHeight:=FImageList.Height;

    ClientSize.cx:= PaintRect.Right - PaintRect.Left;
    ClientSize.cy:= PaintRect.Bottom - PaintRect.Top;

    if (Caption <> '') and FShowCaption then
    begin
      TMP := Caption;
      SIndex := DeleteAmpersands(TMP);
      TextSize:= Canvas.TextExtent(TMP);
{      If SIndex > 0 then
        If SIndex <= Length(TMP) then
        begin
          FShortcut := Ord(TMP[SIndex]);
        end;}
    end
    else
    begin
      TextSize.cx:= 0;
      TextSize.cy:= 0;
    end;

    if (GlyphWidth = 0) or (GlyphHeight = 0) or (TextSize.cx = 0) or (TextSize.cy = 0)  then
      S:= 0
    else
      S:= Spacing;

    // Calculate caption and glyph layout

    if Margin = -1 then
    begin
      if S = -1 then
      begin
        TotalSize.cx:= TextSize.cx + GlyphWidth;
        TotalSize.cy:= TextSize.cy + GlyphHeight;
        if Layout in [blGlyphLeft, blGlyphRight] then
          M:= (ClientSize.cx - TotalSize.cx) div 3
        else
          M:= (ClientSize.cy - TotalSize.cy) div 3;
        S:= M;
      end
      else
      begin
        TotalSize.cx:= GlyphWidth + S + TextSize.cx;
        TotalSize.cy:= GlyphHeight + S + TextSize.cy;
        if Layout in [blGlyphLeft, blGlyphRight] then
          M:= (ClientSize.cx - TotalSize.cx + 1) div 2
        else
          M:= (ClientSize.cy - TotalSize.cy + 1) div 2
      end;
    end
    else
    begin
      if S = -1 then
      begin
        TotalSize.cx:= ClientSize.cx - (Margin + GlyphWidth);
        TotalSize.cy:= ClientSize.cy - (Margin + GlyphHeight);
        if Layout in [blGlyphLeft, blGlyphRight] then
          S:= (TotalSize.cx - TextSize.cx) div 2
        else
          S:= (TotalSize.cy - TextSize.cy) div 2;
      end;
      M:= Margin
    end;

    case Layout of
      blGlyphLeft :
        begin
          Offset.X:= M;
          Offset.Y:= (ClientSize.cy - GlyphHeight + 1) div 2;
          OffsetCap.X:= Offset.X + GlyphWidth + S;
          OffsetCap.Y:= (ClientSize.cy - TextSize.cy) div 2;
        end;
      blGlyphRight : begin
        Offset.X:= ClientSize.cx - M - GlyphWidth;
        Offset.Y:= (ClientSize.cy - GlyphHeight + 1) div 2;
        OffsetCap.X:= Offset.X - S - TextSize.cx;
        OffsetCap.Y:= (ClientSize.cy - TextSize.cy) div 2;
      end;
      blGlyphTop : begin
        Offset.X:= (ClientSize.cx - GlyphWidth + 1) div 2;
        Offset.Y:= M;
        OffsetCap.X:= (ClientSize.cx - TextSize.cx + 1) div 2;
        OffsetCap.Y:= Offset.Y + GlyphHeight + S;
      end;
      blGlyphBottom : begin
        Offset.X:= (ClientSize.cx - GlyphWidth + 1) div 2;
        Offset.Y:= ClientSize.cy - M - GlyphHeight;
        OffsetCap.X:= (ClientSize.cx - TextSize.cx + 1) div 2;
        OffsetCap.Y:= Offset.Y - S - TextSize.cy;
      end;
    end;

    if ((FLastDrawFlagsA and DFCS_FLAT) <> 0) and ((FLastDrawFlagsA and DFCS_PUSHED) = 0)
      and (tpGlyphPopup in TToolbarItems(FOwnerItem.Collection).FToolPanel.Options)then
    begin
//      FImageList.Draw(Canvas, Offset.X, Offset.Y, TCustomAction(Action).ImageIndex, false);
      Dec(Offset.X, 2);
      Dec(Offset.Y, 2);
    end;
    FImageList.Draw(Canvas, Offset.X, Offset.Y, TCustomAction(Action).ImageIndex, TCustomAction(Action).Enabled);
  end;
  if (Caption <> '') and FShowCaption then
  begin
    TXTStyle := Canvas.TextStyle;
    TXTStyle.Opaque := False;
    TXTStyle.Clipping := True;
    TXTStyle.ShowPrefix := True;
    TXTStyle.Alignment := taLeftJustify;
    TXTStyle.Layout := tlTop;
    TXTStyle.SystemFont := Canvas.Font.IsDefault;//Match System Default Style
    With PaintRect, OffsetCap do
    begin
      Left := Left + X;
      Top := Top + Y;
    end;
    If not Enabled then
    begin
      Canvas.Font.Color := clBtnHighlight;
      OffsetRect(PaintRect, 1, 1);
      Canvas.TextRect(PaintRect, PaintRect.Left, PaintRect.Top, Caption, TXTStyle);
      Canvas.Font.Color := clBtnShadow;
      OffsetRect(PaintRect, -1, -1);
    end
    else
    begin
      Canvas.Font.Color := clBtnText;
      if ((FLastDrawFlagsA and DFCS_FLAT) <> 0) and ((FLastDrawFlagsA and DFCS_PUSHED) = 0) and (TToolPanel(Parent).FToolBarStyle <> tbsWindowsXP)
         and (tpCaptionPopup in TToolbarItems(FOwnerItem.Collection).FToolPanel.Options) then
        OffsetRect(PaintRect, -2, -2);
    end;
    Canvas.TextRect(PaintRect, PaintRect.Left, PaintRect.Top, Caption, TXTStyle);
  end;
end;

procedure TToolbarButton.Click;
var
  P:TPoint;
begin
  if (csDesigning in ComponentState) or FDesign then exit;
  if FToolbarButtonStyle = tbrDropDown then
  begin
    if Assigned(FDropDownMenu) then
    begin
      P.X:=0;
      P.Y:=Height;
      P:=ClientToScreen(P);
      FDropDownMenu.PopUp(P.X, P.Y);
    end;
  end
  else
    inherited Click;
end;

procedure TToolbarButton.UpdateState(InvalidateOnChange: boolean);
var
  OldState: TButtonState;
begin
  OldState:=FState;
  inherited UpdateState(InvalidateOnChange);
  if InvalidateOnChange and ((FState<>OldState) or (FLastDrawFlagsA<>GetDrawFlags)) then
    Invalidate;
end;

procedure TToolbarButton.SetDesign(AValue:boolean; AToolbarItem:TToolbarItem);
begin
  FDesign:=AValue;
  if FDesign then
  begin
    Enabled:=true;
    Flat:=false;
  end
  else
  begin
    Flat:=tpFlatBtns in TToolbarItems(AToolbarItem.Collection).FToolPanel.Options;
    ActionChange(Action, true);
  end;
end;

procedure TToolbarButton.SetAutoSize(AValue: boolean);
begin
  FAutoSize:=AValue;
  UpdateSize;
  Invalidate;
end;

procedure TToolbarButton.UpdateSize;
begin
  SetBounds(Left, Top, Width, Height);
  Invalidate;
end;

procedure TToolbarButton.SetEnabled(NewEnabled: boolean);
begin
  if FToolbarButtonStyle = tbrDropDown then
    NewEnabled :=true;
  inherited SetEnabled(NewEnabled);
end;

function TToolbarButton.GetActionLinkClass: TControlActionLinkClass;
begin
  Result:=TToolbarButtonActionLink;
end;

function TToolbarButton.GetDrawFlags: integer;
begin
  // if flat and not mouse in control and not down, don't draw anything
  if Flat and not MouseInControl and not (FState in [bsDown, bsExclusive]) then
  begin
    Result := 0;
  end
  else
  begin
    Result:=DFCS_BUTTONPUSH;
    if FState in [bsDown, bsExclusive] then
      inc(Result,DFCS_PUSHED);
    if not Enabled then
      inc(Result,DFCS_INACTIVE);
    if Flat then
      inc(Result,DFCS_FLAT);
  end;
end;


procedure TToolbarButton.SetBounds(aLeft, aTop, aWidth, aHeight: integer);
var
  TextSize:TSize;
  ImgH, ImgW:integer;
begin
  if Assigned(Parent) and not (csLoading in TToolPanel(Parent).ComponentState) then
  begin
    if FAutoSize and Assigned(Canvas) then
    begin
      if Assigned(FImageList) then
      begin
        ImgW:=FImageList.Width+8;
        ImgH:=FImageList.Height+8;
      end
      else
      begin
        ImgH:=TToolPanel(Parent).BtnHeight;
        ImgW:=TToolPanel(Parent).BtnWidth;
      end;
      if FShowCaption then
      begin
        TextSize:=Canvas.TextExtent(Caption);
        if (Layout in [blGlyphLeft, blGlyphRight]) and Assigned(FImageList) then
        begin
          aWidth:=ImgW + 4 + TextSize.cx;
          aHeight:=Max(TextSize.cy + 8, ImgH);
        end
        else
        begin
          aWidth:=Max(8 + TextSize.cx, ImgW);
          aHeight:=ImgH + TextSize.cy + 4;
        end;
        if aHeight < TToolPanel(Parent).BtnHeight then
          aHeight:=TToolPanel(Parent).BtnHeight;
      end
      else
      begin
        aWidth:=Max(ImgW, TToolPanel(Parent).BtnWidth);
        aHeight:=Max(ImgH, TToolPanel(Parent).BtnHeight);;
      end;
    end;
  //  if IsDesignMode then
    aTop:=TToolPanel(Parent).BorderWidth;
  end;
  inherited SetBounds(aLeft, aTop, aWidth, aHeight);
end;

destructor TToolbarButton.Destroy;
begin
  if Assigned(FOwnerItem) then
  begin
    FOwnerItem.FButton:=nil;
    FOwnerItem.Free;
  end;
  inherited Destroy;
end;


{ TToolbarItems }

function TToolbarItems.GetToolbarItem(Index: Integer): TToolbarItem;
begin
  result := TToolbarItem( inherited Items[Index] );
end;

function TToolbarItems.GetByActionName(ActionName: string): TToolbarItem;
var
  i:integer;
begin
  Result:=nil;
  for i:=0 to Count-1 do
    if Items[i].Action.Name = ActionName then
    begin
      Result:=Items[i];
    end;
end;

procedure TToolbarItems.SetToolbarItem(Index: Integer;
  const AValue: TToolbarItem);
begin
  Items[Index].Assign( AValue );
end;

constructor TToolbarItems.Create(ToolPanel: TToolPanel);
begin
  inherited Create(TToolbarItem);
  FToolPanel:=ToolPanel;
end;

{ TToolPanel }

function TToolPanel.GetItems: TToolbarItems;
begin
  Result:=FToolbarItems;
end;

function TToolPanel.GetBtnHeight: Integer;
begin
  Result:=FDefButtonHeight;
end;

function TToolPanel.GetBtnWidth: Integer;
begin
  Result:=FDefButtonWidth;
end;

function TToolPanel.GetPropertyStorage: TCustomPropertyStorage;
begin
  Result:=FPropertyStorageLink.Storage;
end;

procedure TToolPanel.SetBtnHeight(const AValue: Integer);
var
  i:integer;
begin
  if FDefButtonHeight<>AValue then
  begin
    FDefButtonHeight:=AValue;
    for i:=0 to FToolbarItems.Count - 1 do
      FToolbarItems[i].FButton.UpdateSize;
  end;
end;

procedure TToolPanel.SetBtnWidth(const AValue: Integer);
var
  i:integer;
begin
  if FDefButtonWidth<>AValue then
  begin
    FDefButtonWidth:=AValue;
    for i:=0 to FToolbarItems.Count - 1 do
      FToolbarItems[i].FButton.UpdateSize;
  end;
end;

procedure TToolPanel.SetImageList(const AValue: TImageList);
var
  i:integer;
begin
  if FImageList=AValue then exit;
  FImageList:=AValue;
  for i:=0 to FToolbarItems.Count - 1 do
    FToolbarItems[i].FButton.FImageList:=AValue;
end;

procedure TToolPanel.SetItems(const AValue: TToolbarItems);
begin
  FToolbarItems.Assign(AValue);
end;

procedure TToolPanel.SetOptions(const AValue: TToolPanelOptions);
var
  i:integer;
begin
  if FOptions=AValue then exit;
  FOptions:=AValue;

  for i:=0 to FToolbarItems.Count - 1 do
  begin
    FToolbarItems[i].FButton.Transparent:=tpTransparentBtns in FOptions;
    FToolbarItems[i].FButton.Flat:=tpFlatBtns in FOptions;
  end;
  
  Invalidate;
end;

procedure TToolPanel.SetPropertyStorage(const AValue: TCustomPropertyStorage);
begin
  FPropertyStorageLink.Storage:=AValue;
end;


procedure TToolPanel.OnIniSave(Sender: TObject);
var
  i:integer;
  S, S1:string;
  tpo:TToolPanelOptions;
  tpo1:integer absolute tpo;
begin
  S:=Owner.Name+'.'+Name;
  FPropertyStorageLink.Storage.WriteInteger(S+sVersion, FVersion);
  FPropertyStorageLink.Storage.WriteInteger(S+sShowHint, ord(ShowHint));
  tpo:=FOptions;
  FPropertyStorageLink.Storage.WriteString(S+sOptions, SetToString(GetPropInfo(Self, 'Options'), tpo1));
  FPropertyStorageLink.Storage.WriteString(S+sToolBarStyle, GetEnumProp(Self, 'ToolBarStyle'));
  FPropertyStorageLink.Storage.WriteInteger(S+sCount, FToolbarItems.Count);
  S:=S+sItem;
  for i:=0 to FToolbarItems.Count-1 do
  begin
    S1:=S+IntToStr(i);
    FPropertyStorageLink.Storage.WriteString(S1+sAction, FToolbarItems[i].Action.Name);
    FPropertyStorageLink.Storage.WriteInteger(S1+sVisible, ord(FToolbarItems[i].Visible));
    FPropertyStorageLink.Storage.WriteInteger(S1+sShowCaption, ord(FToolbarItems[i].ShowCaption));
    FPropertyStorageLink.Storage.WriteInteger(S1+sTop, FToolbarItems[i].Top);
    FPropertyStorageLink.Storage.WriteInteger(S1+sLeft, FToolbarItems[i].Left);
    FPropertyStorageLink.Storage.WriteInteger(S1+sWidth, FToolbarItems[i].Width);
  end;
end;

procedure TToolPanel.OnIniLoad(Sender: TObject);
var
  i, ACount:integer;
  S, S1, AActionName, S2:string;
  AItem:TToolbarItem;
  tpo:TToolPanelOptions;
  tpo1:integer absolute tpo;
begin
  S:=Owner.Name+'.'+Name;
  ACount:=FPropertyStorageLink.Storage.ReadInteger(S+sVersion, FVersion); //Check cfg version
  if ACount = FVersion then
  begin
    ShowHint:=FPropertyStorageLink.Storage.ReadInteger(S+sShowHint, ord(ShowHint))<>0;

    tpo:=FOptions;
    tpo1:=StringToSet(GetPropInfo(Self, 'Options'), FPropertyStorageLink.Storage.ReadString(S+sOptions, SetToString(GetPropInfo(Self, 'Options'), tpo1)));
    SetOptions(tpo);

    SetEnumProp(Self, 'ToolBarStyle', FPropertyStorageLink.Storage.ReadString(S+sToolBarStyle, GetEnumProp(Self, 'ToolBarStyle')));

    ACount:=FPropertyStorageLink.Storage.ReadInteger(S+sCount, 0);
    S:=S+sItem;
    for i:=0 to ACount-1 do
    begin
      S1:=S+IntToStr(i);
      AActionName:=FPropertyStorageLink.Storage.ReadString(S1+sAction, '');
      AItem:=FToolbarItems.ByActionName[AActionName];
      if Assigned(AItem) then
      begin
        AItem.Top:=FPropertyStorageLink.Storage.ReadInteger(S1+sTop, AItem.Top);
        AItem.Left:=FPropertyStorageLink.Storage.ReadInteger(S1+sLeft, AItem.Left);
        AItem.Width:=FPropertyStorageLink.Storage.ReadInteger(S1+sWidth, AItem.Width);
        AItem.Visible:=FPropertyStorageLink.Storage.ReadInteger(S1+sVisible, ord(AItem.Visible)) <> 0;
        AItem.ShowCaption:=FPropertyStorageLink.Storage.ReadInteger(S1+sShowCaption, ord(AItem.ShowCaption)) <> 0;
      end;
    end;
  end;
  Invalidate;
end;

procedure TToolPanel.SetToolBarStyle(const AValue: TToolBarStyle);
begin
  if FToolBarStyle=AValue then exit;
  FToolBarStyle:=AValue;
  if FToolBarStyle = tbsWindowsXP then
    SetOptions(FOptions + [tpFlatBtns]);
  Invalidate;
end;

procedure TToolPanel.Notification(AComponent: TComponent; Operation: TOperation);
var
  i:integer;
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FImageList then
      SetImageList(nil)
    else
    if AComponent is TPopupMenu then
    begin
      for i:=0 to FToolbarItems.Count - 1 do
        if FToolbarItems[i].DropDownMenu = AComponent then
          FToolbarItems[i].DropDownMenu:=nil;
    end
    else
    if AComponent is TBasicAction then
    begin
      for i:=0 to FToolbarItems.Count - 1 do
        if FToolbarItems[i].Action = AComponent then
          FToolbarItems[i].Action:=nil;
    end;
  end;
end;

procedure TToolPanel.SetCustomizing(AValue: boolean);
var
  i:integer;
begin
  for i:=0 to FToolbarItems.Count - 1 do
    FToolbarItems[i].FButton.SetDesign(AValue, FToolbarItems[i]);
end;

procedure TToolPanel.DoAutoSize;
var
  i, H:integer;
  
begin
  if not AutoSizeCanStart then exit;
{  if AutoSizeDelayed then
  begin
    Include(FControlFlags,cfAutoSizeNeeded);
    exit;
  end;}
  if Items.Count > 0 then
  begin
    H:=0;
    for i:=0 to Items.Count-1 do
      if Assigned(Items[i].FButton) then
        H:=Max(H, Items[i].Height);
    H:=H +BorderWidth * 2;
    SetBoundsKeepBase(Left,Top,Width,H,true);
//    Exclude(FControlFlags,cfAutoSizeNeeded);
  end
  else
  inherited DoAutoSize;
end;

procedure TToolPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbRight) and (ssCtrl in Shift) and (tpCustomizable in FOptions) then
    Customize(HelpContext);
end;

constructor TToolPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FToolbarItems:=TToolbarItems.Create(Self);
  Align:=alTop;
  Height:=DefButtonHeight;
  FPropertyStorageLink:=TPropertyStorageLink.Create;
  FPropertyStorageLink.OnSave:=@OnIniSave;
  FPropertyStorageLink.OnLoad:=@OnIniLoad;
  FDefButtonWidth:=DefButtonWidth;
  FDefButtonHeight:=DefButtonHeight;
  FToolBarStyle:=tbsStandart;
  BorderWidth:=4;
  ControlStyle:=ControlStyle - [csSetCaption];
  Caption:='';
end;

destructor TToolPanel.Destroy;
begin
  if Assigned(FCustomizer) then
  begin
    TToolPanelSetupForm(FCustomizer).FToolPanel:=nil;
    FreeAndNil(FCustomizer);
  end;
  FreeAndNil(FToolbarItems);
  FreeAndNil(FPropertyStorageLink);
  inherited Destroy;
end;

procedure TToolPanel.Customize(HelpCtx: Longint);
begin
  if not Assigned(FCustomizer) then
    FCustomizer:=TToolPanelSetupForm.CreateSetupForm(Self);
  FCustomizer.HelpContext:=HelpCtx;
  FCustomizer.Show;
  SetCustomizing(true);
end;

{ TToolbarItem }

procedure TToolbarItem.SetAction(const AValue: TBasicAction);
begin
  if FButton.Action<>AValue then
  begin
{    if Assigned(FButton.Action) then
      FButton.Action.UnRegisterChanges(FActionLink);}
    FButton.Action:=AValue;
    FButton.UpdateSize;
{    if Assigned(AValue) then
      AValue.RegisterChanges(FActionLink);}
  end;
end;

procedure TToolbarItem.SetAutoSize(const AValue: boolean);
begin
  if FButton.FAutoSize<>AValue then
    FButton.SetAutoSize(AValue);
end;

procedure TToolbarItem.SetButtonStyle(const AValue: TToolbarButtonStyle);
begin
  if FButton.FToolbarButtonStyle<>AValue then
  begin
    FButton.FToolbarButtonStyle:=AValue;
{    if AValue = tbrDropDown then
      FButton.Enabled :=true;}
    FButton.UpdateSize;
    FButton.Invalidate;
  end;
end;

procedure TToolbarItem.SetDropDownMenu(const AValue: TPopupMenu);
begin
  if FButton.FDropDownMenu<>AValue then
  begin
    FButton.FDropDownMenu:=AValue;
    FButton.Invalidate;
  end;
end;

procedure TToolbarItem.SetGroupIndex(const AValue: Integer);
begin
  FButton.GroupIndex:=AValue;
end;

procedure TToolbarItem.SetHeight(const AValue: Integer);
begin
  FButton.Height:=AValue;
end;

procedure TToolbarItem.SetLayout(const AValue: TButtonLayout);
begin
  FButton.Layout:=AValue;
  FButton.UpdateSize;
end;

procedure TToolbarItem.SetLeft(const AValue: Integer);
begin
  FButton.Left:=AValue;
end;

procedure TToolbarItem.SetShowCaption(const AValue: boolean);
begin
  if FButton.FShowCaption<>AValue then
  begin
    FButton.FShowCaption:=AValue;
    FButton.UpdateSize;
    FButton.Invalidate;
  end;
end;

procedure TToolbarItem.SetTag(const AValue: Longint);
begin
  FButton.Tag:=AValue;
end;

procedure TToolbarItem.SetTop(const AValue: Integer);
begin
  FButton.Top:=AValue;
end;

function TToolbarItem.GetAction: TBasicAction;
begin
  Result:=FButton.Action;
end;

function TToolbarItem.GetAutoSize: boolean;
begin
  Result:=FButton.FAutoSize;
end;

function TToolbarItem.GetButtonStyle: TToolbarButtonStyle;
begin
  Result:=FButton.FToolbarButtonStyle;
end;

function TToolbarItem.GetDropDownMenu: TPopupMenu;
begin
  Result:=FButton.FDropDownMenu;
end;

function TToolbarItem.GetGroupIndex: Integer;
begin
  Result:=FButton.GroupIndex;
end;

function TToolbarItem.GetHeight: Integer;
begin
  Result:=FButton.Height;
end;

function TToolbarItem.GetLayout: TButtonLayout;
begin
  Result:=FButton.Layout;
end;

function TToolbarItem.GetLeft: Integer;
begin
  Result:=FButton.Left;
end;

function TToolbarItem.GetShowCaption: boolean;
begin
  Result:=FButton.FShowCaption;
end;

function TToolbarItem.GetTag: Longint;
begin
  Result:=FButton.Tag;
end;

function TToolbarItem.GetTop: Integer;
begin
  Result:=FButton.Top;
end;

function TToolbarItem.GetVisible: boolean;
begin
  Result:=FButton.Visible;
end;

function TToolbarItem.GetWidth: Integer;
begin
  Result:=FButton.Width;
end;

procedure TToolbarItem.SetVisible(const AValue: boolean);
begin
  if FButton.Visible<>AValue then
  begin
    FButton.Visible:=AValue;
    FButton.Invalidate;
  end;
end;

procedure TToolbarItem.SetWidth(const AValue: Integer);
begin
  FButton.Width:=AValue;
end;

function TToolbarItem.GetDisplayName: string;
begin
  if Assigned(Action) then
  begin
    if (Action is TCustomAction) then
      Result:=TCustomAction(Action).Name + ' - ' +TCustomAction(Action).Caption
    else
      Result:=TCustomAction(Action).Name;
  end
  else
    Result:=inherited GetDisplayName;
end;

constructor TToolbarItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FButton:=TToolbarButton.Create(TToolbarItems(ACollection).FToolPanel);
  FButton.Parent:=TToolbarItems(ACollection).FToolPanel;
  FButton.FImageList:=TToolbarItems(ACollection).FToolPanel.ImageList;
  FButton.Flat:=tpFlatBtns in TToolbarItems(ACollection).FToolPanel.Options;
  FButton.Transparent:=tpTransparentBtns in TToolbarItems(ACollection).FToolPanel.Options;
  FButton.FShowCaption:=false;
  FButton.FAutoSize:=true;
  FButton.FOwnerItem:=Self;
end;

destructor TToolbarItem.Destroy;
begin
  FButton.FOwnerItem:=nil;
  FreeAndNil(FButton);
  inherited Destroy;
end;

{ TToolbarButtonActionLink }

procedure TToolbarButtonActionLink.SetImageIndex(Value: Integer);
begin
  FClient.Invalidate;
end;

function TToolbarButtonActionLink.IsImageIndexLinked: Boolean;
begin
  Result:=true;
end;

end.

