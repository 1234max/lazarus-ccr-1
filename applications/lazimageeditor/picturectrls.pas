{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Tom Gregorovic

  Abstract:
    Components to view and edit picture.
}
unit PictureCtrls;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LCLIntf, Controls, Forms, ExtCtrls, Graphics, Math,
  BmpRGBGraph, BmpRGBUtils, BmpRGBTypes, DLBitmap;

type
  TPictureViewOption = (poShowGrid, poShowMask);
  TPictureViewOptions = set of TPictureViewOption;

  TPictureBitmap = TRGB32Bitmap;

  { TCustomPictureView }

  TCustomPictureView = class(TScrollBox)
  private
    FOnPictureMouseDown: TMouseEvent;
    FOnPictureMouseMove: TMouseMoveEvent;
    FOnPictureMouseUp: TMouseEvent;
    FOptions: TPictureViewOptions;
    FZoom: single;
    FScrollStop: TPanel;
    FPicture: TPictureBitmap;
    FPictureRect: TRect;
    FOldPos: TPoint;
    FStartPos: TPoint;
    FEndPos: TPoint;
    FPaintIndex: integer;
    procedure SetOptions(const AValue: TPictureViewOptions);
    procedure SetPicture(const AValue: TPictureBitmap);
    procedure SetZoom(const AValue: single);
    procedure MaskDraw(Data: PtrInt);
  protected
    procedure PictureMouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); dynamic;
    procedure PictureMouseMove(Shift: TShiftState; X, Y: integer); dynamic;
    procedure PictureMouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); dynamic;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure UpdatePictureRect;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure EraseBackground(DC: HDC); override;
    procedure InvalidatePictureRect(R: TRect);
    function ClientToPicture(const P: TPoint): TPoint;
    function ClientToPicture(const R: TRect): TRect;
    function PictureToClient(const P: TPoint): TPoint;
    function PictureToClient(const R: TRect): TRect;

    procedure LoadPicture(const FileName: string); virtual;
    procedure LoadBitmap(ABitmap: TRasterImage); virtual;
    procedure SavePicture(const FileName: string); virtual;
    procedure ExportPictureAsLazarusResource(const AFileName, AName: string); virtual;

    property StartPos: TPoint read FStartPos;
    property EndPos: TPoint read FEndPos;
  public
    property Options: TPictureViewOptions read FOptions write SetOptions;
    property Picture: TPictureBitmap read FPicture write SetPicture;
    property Zoom: single read FZoom write SetZoom;

    property OnPictureMouseDown: TMouseEvent
      read FOnPictureMouseDown write FOnPictureMouseDown;
    property OnPictureMouseMove: TMouseMoveEvent
      read FOnPictureMouseMove write FOnPictureMouseMove;
    property OnPictureMouseUp: TMouseEvent read FOnPictureMouseUp
      write FOnPictureMouseUp;
  end;

  TPictureView = class(TCustomPictureView)
  end;

  TPictureEditShape = (psRect, psCircle);

  TPictureEditToolDrag = (tdNone, tdLine, tdRectangle, tdEllipse,
    tdRoundRectangle, tdPolygon);

  TPictureEditTool = (ptLine, ptPen, ptRectangle, ptFloodFill, ptEllipse,
    ptMask, ptColorPick, ptEraser, ptSpray, ptPolygon, ptBrush, ptText, ptColorReplacer);

  TPicturePos = (ppTopLeft, ppTopCenter, ppTopRight, ppCenterLeft, ppCentered,
    ppCenterRight, ppBottomLeft, ppBottomCenter, ppBottomRight);

  TMaskTool = (mtRectangle, mtEllipse, mtFloodFill);

  { TCustomPictureEdit }

  TCustomPictureEdit = class(TCustomPictureView)
  private
    FDrawMode: TDrawMode;
    FFillAlpha: integer;
    FFillAndOutline: TDrawMode;
    FFillColor: TColor;
    FFloodFillTolerance: single;
    FFuzzy: boolean;
    FMaskTool: TMaskTool;
    FModified: boolean;
    FOnChange: TNotifyEvent;
    FOnColorChange: TNotifyEvent;
    FOnPictureSizeChange: TNotifyEvent;
    FOutlineColor: TColor;
    FPaperColor: TColor;
    FRandomDensity: single;
    FRectangleRoundness: integer;
    FShape: TPictureEditShape;
    FSize: integer;
    FTool: TPictureEditTool;
    FToolDrag: TPictureEditToolDrag;
    FTempPos: TPoint;
    procedure SetFillColor(const AValue: TColor);
    procedure SetOutlineColor(const AValue: TColor);
    procedure SetPaperColor(const AValue: TColor);
    procedure SetTool(const AValue: TPictureEditTool);
  protected
    FromColor, ToColor: TColor;
    procedure Change; dynamic;
    procedure ColorChange; dynamic;
    procedure PictureSizeChange; dynamic;
    procedure PictureMouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure PictureMouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure PictureMouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;

    function GetToolDrag: TPictureEditToolDrag; virtual;
    procedure DrawToolDrag(X1, Y1, X2, Y2: integer); virtual;
  public
    constructor Create(TheOwner: TComponent); override;

    procedure NewPicture(AWidth, AHeight: integer; APaperColor: TColor);
    procedure LoadPicture(const FileName: string); override;
    procedure LoadBitmap(ABitmap: TRasterImage); override;
    procedure SavePicture(const FileName: string); override;

    procedure ColorPick(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure FloodFill(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure MaskFloodFill(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure Eraser(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure ColorReplacer(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure Spray(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure Brush(X, Y: integer; Shift: TShiftState = [ssLeft]);
    procedure Line(X1, Y1, X2, Y2: integer; Shift: TShiftState = [ssLeft]);
    procedure Rectangle(X1, Y1, X2, Y2: integer; Shift: TShiftState = [ssLeft]);
    procedure Ellipse(X1, Y1, X2, Y2: integer; Shift: TShiftState = [ssLeft]);
    procedure Polygon(X1, Y1, X2, Y2: integer; Shift: TShiftState);
    procedure ProcessEditorText(X1, Y1, X2, Y2: integer);
    procedure ProcessPointAddr(X1, Y1, X2, Y2: integer; Points: array of TPoint; PCount: integer);
    procedure Mask(X1, Y1, X2, Y2: integer; Shift: TShiftState = [ssLeft]);

    procedure FlipHorizontally;
    procedure FlipVertically;
    procedure Rotate90Clockwise;
    procedure Rotate180Clockwise;
    procedure Rotate270Clockwise;
    procedure ColorReplace(ColorFrom, ColorTo: TColor);

    procedure StretchTruncate(AWidth, AHeight: integer);
    procedure StretchSmooth(AWidth, AHeight: integer; Method: TSmoothMethod);
    procedure ResizePaper(AWidth, AHeight: integer; PicturePos: TPicturePos);
    procedure ClipPaperToMask;

    procedure RemoveMask;
    procedure InvertMask;

    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Delete;
    procedure SelectAll;


    procedure Invert;
    procedure Grayscale;
    procedure Disable;

    procedure BeginDraw;
    procedure EndDraw;
    procedure UpdatePicture;
    procedure ChangeColor(FrColor, taColor: TColor);
  public
    TextEditor: TTextEditor;
    property DrawMode: TDrawMode read FDrawMode write FDrawMode;
    property FillColor: TColor read FFillColor write SetFillColor;
    property OutlineColor: TColor read FOutlineColor write SetOutlineColor;
    property PaperColor: TColor read FPaperColor write SetPaperColor;
    property Shape: TPictureEditShape read FShape write FShape;
    property FillAndOutline: TDrawMode read FFillAndOutline write FFillAndOutline;
    property MaskTool: TMaskTool read FMaskTool write FMaskTool;
    property RandomDensity: single read FRandomDensity write FRandomDensity;
    property RectangleRoundness: integer read FRectangleRoundness
      write FRectangleRoundness;
    property FloodFillTolerance: single read FFloodFillTolerance
      write FFloodFillTolerance;
    property Size: integer read FSize write FSize;
    property Tool: TPictureEditTool read FTool write SetTool;
    property FillAlpha: integer read FFillAlpha write FFillAlpha;
    property Fuzzy: boolean read FFuzzy write FFuzzy;

    property Modified: boolean read FModified;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnColorChange: TNotifyEvent read FOnColorChange write FOnColorChange;
    property OnPictureSizeChange: TNotifyEvent
      read FOnPictureSizeChange write FOnPictureSizeChange;
  end;

  { TPictureEdit }

  TPictureEdit = class(TCustomPictureEdit)
  end;

implementation

{ TCustomPictureView }

procedure TCustomPictureView.SetPicture(const AValue: TPictureBitmap);
begin
  FPicture := AValue;

  FZoom := 1;
  UpdatePictureRect;
end;

procedure TCustomPictureView.SetOptions(const AValue: TPictureViewOptions);
begin
  if FOptions = AValue then
    Exit;
  FOptions := AValue;
  Invalidate;
end;

procedure TCustomPictureView.SetZoom(const AValue: single);
begin
  if AValue = FZoom then
    Exit;
  FZoom := AValue;
  if FZoom < 0.1 then
    FZoom := 0.1;
  if FZoom > 20 then
    FZoom := 20;

  UpdatePictureRect;
end;

procedure TCustomPictureView.MaskDraw(Data: PtrInt);
var
  I, J, CI, CJ, X, Y: integer;
const
  PORTION_SIZE = 128;
begin
  Application.ProcessMessages;
  if Application.Terminated then
    Exit;
  if FPaintIndex <> Data then
    Exit;

  CI := Ceil(Picture.Width / PORTION_SIZE);
  CJ := Ceil(Picture.Height / PORTION_SIZE);

  for J := 0 to Pred(CJ) do
    for I := 0 to Pred(CI) do
      with Canvas do
      begin
        X := FPictureRect.Left - GetClientScrollOffset.X;
        Y := FPictureRect.Top - GetClientScrollOffset.Y;

        FPicture.Mask.StretchDrawShapePortionTo(Canvas, X, Y,
          FPictureRect.Right - FPictureRect.Left, FPictureRect.Bottom - FPictureRect.Top,
          I * PORTION_SIZE, J * PORTION_SIZE, PORTION_SIZE, PORTION_SIZE);

        Application.ProcessMessages;
        if Application.Terminated then
          Exit;
        if FPaintIndex <> Data then
          Exit;
      end;
end;

procedure TCustomPictureView.UpdatePictureRect;
var
  W, H, X, Y: integer;
begin
  if FPicture <> nil then
  begin
    W := Round(FPicture.Width * FZoom);
    H := Round(FPicture.Height * FZoom);

    if W > ClientWidth then
      X := 0
    else
      X := (ClientWidth - W) div 2;

    if H > ClientHeight then
      Y := 0
    else
      Y := (ClientHeight - H) div 2;

    FPictureRect := Bounds(X, Y, W, H);
  end
  else
    FPictureRect := Rect(0, 0, 0, 0);

  //VertScrollBar.Range := FPictureRect.Bottom;
  //HorzScrollBar.Range := FPictureRect.Right;
  if Assigned(FScrollStop) then
  begin
    FScrollStop.SetBounds(FPictureRect.Right, FPictureRect.Bottom, 0, 0);
    Invalidate;
  end;
end;

procedure TCustomPictureView.PictureMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  FStartPos := Point(X, Y);
  FEndPos := FStartPos;

  if Assigned(FOnPictureMouseDown) then
    FOnPictureMouseDown(Self, Button, Shift, X, Y);
end;

procedure TCustomPictureView.PictureMouseMove(Shift: TShiftState; X, Y: integer);
begin
  FEndPos := Point(X, Y);
  if Shift * [ssLeft, ssMiddle, ssRight] = [] then
    FStartPos := FEndPos;

  if Assigned(FOnPictureMouseMove) then
    FOnPictureMouseMove(Self, Shift, X, Y);
end;

procedure TCustomPictureView.PictureMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if Assigned(FOnPictureMouseUp) then
    FOnPictureMouseUp(Self, Button, Shift, X, Y);
end;

procedure TCustomPictureView.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  C: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);

  C := ClientToPicture(Point(X, Y));
  PictureMouseDown(Button, Shift, C.X, C.Y);
  FOldPos := C;
end;

procedure TCustomPictureView.MouseMove(Shift: TShiftState; X, Y: integer);
var
  C: TPoint;
begin
  inherited MouseMove(Shift, X, Y);

  C := ClientToPicture(Point(X, Y));
  if FOldPos <> C then
  begin
    PictureMouseMove(Shift, C.X, C.Y);
    FOldPos := C;
  end;
end;

procedure TCustomPictureView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  C: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);

  C := ClientToPicture(Point(X, Y));
  PictureMouseUp(Button, Shift, C.X, C.Y);
end;

constructor TCustomPictureView.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  Color := clSilver;
  FOptions := [poShowGrid, poShowMask];
  DoubleBuffered := True;
  FStartPos := Point(0, 0);
  FEndPos := Point(0, 0);
  AutoScroll := True;

  FScrollStop := TPanel.Create(Self);
  FScrollStop.SetBounds(0, 0, 0, 0);
  FScrollStop.Parent := Self;
end;

destructor TCustomPictureView.Destroy;
begin
  inherited;
end;

procedure TCustomPictureView.Paint;
var
  I: integer;
  R: TRect;
begin
  Inc(FPaintIndex);
  inherited Paint;

  with Canvas do
  begin
    Brush.Color := Self.Color;
    FillRect(ClipRect);

    if Assigned(FPicture) then
    begin
      FPicture.StretchDrawTo(Canvas, FPictureRect.Left, FPictureRect.Top,
        FPictureRect.Right, FPictureRect.Bottom);

      if (poShowGrid in Options) and (Zoom > 2.0) then
      begin
        Pen.Color := clGray;

        for I := 1 to FPicture.Width do
        begin
          MoveTo(FPictureRect.Left + Round(I * Zoom), FPictureRect.Top);
          LineTo(FPictureRect.Left + Round(I * Zoom), FPictureRect.Bottom);
        end;

        for I := 1 to FPicture.Height do
        begin
          MoveTo(FPictureRect.Left, FPictureRect.Top + Round(I * Zoom));
          LineTo(FPictureRect.Right, FPictureRect.Top + Round(I * Zoom));
        end;
      end;

      if (poShowMask in Options) and not FPicture.Mask.IsEmpty then
      begin
        Application.QueueAsyncCall(@MaskDraw, FPaintIndex);
      end;
    end;
  end;
end;

procedure TCustomPictureView.Resize;
begin
  inherited Resize;
  UpdatePictureRect;
end;

procedure TCustomPictureView.EraseBackground(DC: HDC);
begin
  //inherited EraseBackground(DC);
end;

procedure TCustomPictureView.InvalidatePictureRect(R: TRect);
var
  P: TRect;
  S: TPoint;
begin
  if HandleAllocated then
  begin
    P := PictureToClient(R);
    S := GetClientScrollOffset;
    OffsetRect(P, -S.X, -S.Y);
    InvalidateRect(Handle, @P, False);
  end;
end;

function TCustomPictureView.ClientToPicture(const P: TPoint): TPoint;
var
  S: TPoint;
begin
  S := GetClientScrollOffset;
  Result.X := Floor((P.X - FPictureRect.Left + S.X) / FZoom);
  Result.Y := Floor((P.Y - FPictureRect.Top + S.Y) / FZoom);
end;

function TCustomPictureView.ClientToPicture(const R: TRect): TRect;
var
  S: TPoint;
begin
  Result := R;
  SortRect(Result);
  S := GetClientScrollOffset;

  Result.Left := Floor((Result.Left - FPictureRect.Left + S.X) / FZoom);
  Result.Top := Floor((Result.Top - FPictureRect.Top + S.Y) / FZoom);
  Result.Right := Ceil((Result.Right - FPictureRect.Right + S.X) / FZoom);
  Result.Bottom := Ceil((Result.Bottom - FPictureRect.Bottom + S.Y) / FZoom);
end;

function TCustomPictureView.PictureToClient(const P: TPoint): TPoint;
var
  S: TPoint;
begin
  S := GetClientScrollOffset;
  Result.X := Floor((P.X + 0.5) * FZoom) + FPictureRect.Left - S.X;
  Result.Y := Floor((P.Y + 0.5) * FZoom) + FPictureRect.Top - S.Y;
end;

function TCustomPictureView.PictureToClient(const R: TRect): TRect;
var
  S: TPoint;
begin
  Result := R;
  SortRect(Result);
  S := GetClientScrollOffset;

  Result.Left := Floor((Result.Left - 1) * FZoom) + FPictureRect.Left + S.X;
  Result.Top := Floor((Result.Top - 1) * FZoom) + FPictureRect.Top + S.Y;
  Result.Right := Ceil((Result.Right + 2) * FZoom) + FPictureRect.Left + S.X;
  Result.Bottom := Ceil((Result.Bottom + 2) * FZoom) + FPictureRect.Top + S.Y;
end;

procedure TCustomPictureView.LoadPicture(const FileName: string);
begin
  Picture.Free;
  Picture := TPictureBitmap.CreateFromFile(FileName);
end;

procedure TCustomPictureView.LoadBitmap(ABitmap: TRasterImage);
begin
  Picture.Free;
  Picture := TPictureBitmap.CreateFromBitmap(ABitmap);
end;

procedure TCustomPictureView.SavePicture(const FileName: string);
var
  Pic: TPicture;
  ExtName: string;
begin
  Pic := TPicture.Create;
  //Picture.SaveToFile(UTF8Decode(FileName));
  Pic.Bitmap.Width := Picture.Width;
  Pic.Bitmap.Height := Picture.Height;
  Pic.Bitmap.Canvas.Draw(0, 0, Picture);
  ExtName := ExtractFileExt(FileName);
  //  if ExtName = 'PNG' then
  //    Pic.Graphic.;
  Pic.SaveToFile(FileName, ExtName);
  Pic.Free;
end;

procedure TCustomPictureView.ExportPictureAsLazarusResource(
  const AFileName, AName: string);
begin
  Picture.SaveToLazarusResource(AFileName, AName);
end;

{ TCustomPictureEdit }

procedure TCustomPictureEdit.SetTool(const AValue: TPictureEditTool);
begin
  if FTool = AValue then
    Exit;
  FTool := AValue;
end;

procedure TCustomPictureEdit.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCustomPictureEdit.SetFillColor(const AValue: TColor);
begin
  if AValue = FFillColor then
    Exit;
  FFillColor := AValue;
  ColorChange;
end;

procedure TCustomPictureEdit.SetOutlineColor(const AValue: TColor);
begin
  if AValue = FOutlineColor then
    Exit;
  FOutlineColor := AValue;
  ColorChange;
end;

procedure TCustomPictureEdit.SetPaperColor(const AValue: TColor);
begin
  if AValue = FPaperColor then
    Exit;
  FPaperColor := AValue;
  ColorChange;
end;

procedure TCustomPictureEdit.ColorChange;
begin
  if Assigned(FOnColorChange) then
    FOnColorChange(Self);
end;

procedure TCustomPictureEdit.PictureSizeChange;
begin
  if Assigned(FOnPictureSizeChange) then
    FOnPictureSizeChange(Self);
end;

procedure TCustomPictureEdit.PictureMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  inherited PictureMouseDown(Button, Shift, X, Y);

  FTempPos := Point(X, Y);
  case Tool of
    ptPen: Line(X, Y, X, Y, Shift);
    ptFloodFill: FloodFill(X, Y, Shift);
    ptMask: if MaskTool = mtFloodFill then
        MaskFloodFill(X, Y, Shift);
    ptColorPick: ColorPick(X, Y, Shift);
    ptEraser: Eraser(X, Y, Shift);
    ptColorReplacer: ColorReplacer(X, Y, Shift);
    ptSpray: Spray(X, Y, Shift);
    ptText: ProcessEditorText(X, Y, X, Y);
    ptBrush: Brush(X, Y, Shift);
  end;

  FToolDrag := GetToolDrag;
  DrawToolDrag(StartPos.X, StartPos.Y, FTempPos.X, FTempPos.Y);
end;

procedure TCustomPictureEdit.PictureMouseMove(Shift: TShiftState; X, Y: integer);
begin
  inherited PictureMouseMove(Shift, X, Y);

  if Shift * [ssLeft, ssRight] <> [] then
  begin
    case Tool of
      ptPen:
      begin
        Line(FTempPos.X, FTempPos.Y, X, Y, Shift);
      end;
      ptEraser: Eraser(X, Y, Shift);
      ptColorReplacer: ColorReplacer(X, Y, Shift);
      ptSpray: Spray(X, Y, Shift);
      ptBrush: Brush(X, Y, Shift);
      ptColorPick: ColorPick(X, Y, Shift);
    end;
  end;

  DrawToolDrag(StartPos.X, StartPos.Y, FTempPos.X, FTempPos.Y);
  FTempPos := Point(X, Y);

  DrawToolDrag(StartPos.X, StartPos.Y, X, Y);
end;

procedure TCustomPictureEdit.PictureMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  paddr: array of TPoint; i, pXUnit, pYUnit: integer;
begin
  inherited PictureMouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    Shift := Shift + [ssLeft];
  if Button = mbRight then
    Shift := Shift + [ssRight];

  case Tool of
    ptLine: Line(StartPos.X, StartPos.Y, X, Y, Shift);
    ptRectangle: Rectangle(StartPos.X, StartPos.Y, X, Y, Shift);
    ptEllipse: Ellipse(StartPos.X, StartPos.Y, X, Y, Shift);
    ptPolygon:
    begin
      SetLength(paddr, 3);
      ProcessPointAddr(StartPos.X, StartPos.Y, X, Y, paddr, 3);
      pXUnit := (X - StartPos.X) div (3 - 1);
    pYUnit := (Y - StartPos.Y) div (3 - 1);
    for i := 0 to 3 - 1 do
    begin
      paddr[i].x := StartPos.X + pXUnit * i;
      paddr[i].y := StartPos.Y + pYUnit * i;
    end;
      Canvas.Polygon(paddr);
    end;
    ptMask: if MaskTool <> mtFloodFill then
        Mask(StartPos.X, StartPos.Y, X, Y, Shift);
  end;

  FToolDrag := tdNone;
end;

function TCustomPictureEdit.GetToolDrag: TPictureEditToolDrag;
begin
  case Tool of
    ptLine: Result := tdLine;
    ptRectangle: Result := tdRoundRectangle;
    ptEllipse: Result := tdEllipse;
    ptPolygon: Result := tdPolygon;
    ptMask:
    begin
      case MaskTool of
        mtEllipse: Result := tdEllipse;
        mtRectangle: Result := tdRectangle;
        mtFloodFill: Result := tdNone;
      end;
    end;
    else
      Result := tdNone;
  end;
end;

procedure TCustomPictureEdit.DrawToolDrag(X1, Y1, X2, Y2: integer);
var
  S, E: TPoint;
  R: integer;
begin
  if FToolDrag = tdNone then
    Exit;

  // Canvas.Pen.Mode := pmNot;
  Canvas.Pen.Mode := pmNotXor;
  Canvas.Brush.Style := bsClear;

  S := PictureToClient(Point(X1, Y1));
  E := PictureToClient(Point(X2, Y2));
  R := Round(RectangleRoundness * Zoom);

  if FToolDrag = tdLine then
    Canvas.Line(S.X, S.Y, E.X, E.Y);
  if FToolDrag = tdRectangle then
    Canvas.Rectangle(S.X, S.Y, E.X, E.Y);
  if FToolDrag = tdRoundRectangle then
    Canvas.RoundRect(S.X, S.Y, E.X, E.Y, R, R);
  if FToolDrag = tdEllipse then
    Canvas.Ellipse(S.X, S.Y, E.X, E.Y);
  if FToolDrag = tdPolygon then
    Polygon(S.X, S.Y, E.X, E.Y, [ssLeft]);

  Canvas.Pen.Mode := pmCopy;
  Canvas.Brush.Style := bsSolid;
end;

constructor TCustomPictureEdit.Create(TheOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csCaptureMouse];
  CaptureMouseButtons := [mbLeft, mbMiddle, mbRight];

  FFillAlpha := 100;
  FFillColor := clGray;
  FOutlineColor := clBlack;
  FPaperColor := clWhite;
  RandomDensity := 1.0;
  RectangleRoundness := 0;
  Size := 10;
  FloodFillTolerance := 0;

  Cursor := crCross;
end;

procedure TCustomPictureEdit.NewPicture(AWidth, AHeight: integer; APaperColor: TColor);
begin
  Picture.Free;
  Picture := TPictureBitmap.Create(AWidth, AHeight);
  PaperColor := APaperColor;
  Picture.Fill(PaperColor);
  FModified := False;
  Change;
end;

procedure TCustomPictureEdit.LoadPicture(const FileName: string);
begin
  inherited LoadPicture(FileName);
  FModified := False;
  Change;
end;

procedure TCustomPictureEdit.LoadBitmap(ABitmap: TRasterImage);
begin
  inherited LoadBitmap(ABitmap);
  FModified := False;
  Change;
end;

procedure TCustomPictureEdit.SavePicture(const FileName: string);
begin
  inherited SavePicture(FileName);
  FModified := False;
  Change;
end;

procedure TCustomPictureEdit.ColorPick(X, Y: integer; Shift: TShiftState);
var
  C: TColor;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  try
    C := Picture.GetColor(X, Y);
  finally
    EndDraw;
  end;
  if C <> clNone then
  begin
    if ssLeft in Shift then
      OutlineColor := C;
    if ssRight in Shift then
      FillColor := C;
    if ssMiddle in Shift then
      PaperColor := C;
  end;
end;

procedure TCustomPictureEdit.FloodFill(X, Y: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  try
    //Picture.Canvas.FloodFill(X, Y, FFillColor, fsSurface); //Picture.Canvas.Brush.Color, fsSurface);
    Picture.Canvas.Brush.Color := FFillColor;
    Picture.Canvas.FloodFill(x, y, Picture.Canvas.Pixels[x, y], fsSurface);
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  Invalidate;
end;

procedure TCustomPictureEdit.MaskFloodFill(X, Y: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  try
    Picture.Mask.FillMode := mfXOR;
    if ssLeft in Shift then
      Picture.Mask.FillMode := mfAdd;
    if ssRight in Shift then
      Picture.Mask.FillMode := mfRemove;

    Picture.MaskFloodFill(X, Y);
  finally
    Picture.Mask.FillMode := mfAdd;
    EndDraw;
  end;
  Invalidate;
end;

procedure TCustomPictureEdit.Eraser(X, Y: integer; Shift: TShiftState);
var
  R: TRect;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if ssLeft in Shift then
    Picture.EraseMode := ermErase;
  if ssRight in Shift then
    Picture.EraseMode := ermReplace;
  try
    R := Bounds(X - FSize div 2, Y - FSize div 2, FSize, FSize);
    Picture.Canvas.Pen.Color := FPaperColor;
    Picture.Canvas.Brush.Color := FpaperColor;
    case Shape of
      psRect: Picture.Canvas.FillRect(R.Left, R.Top, R.Right, R.Bottom);
      psCircle: Picture.FillEllipse(R.Left, R.Top, R.Right, R.Bottom);
    end;
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(R);
end;

procedure TCustomPictureEdit.ChangeColor(FrColor, TaColor: TColor);
begin
  FromColor := FrColor;
  ToColor := TaColor;
end;

procedure TCustomPictureEdit.ColorReplacer(X, Y: integer; Shift: TShiftState = [ssLeft]);
var
  R: TRect;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if ssLeft in Shift then
    Picture.EraseMode := ermErase;
  if ssRight in Shift then
    Picture.EraseMode := ermReplace;
  try
    R := Bounds(X - FSize div 2, Y - FSize div 2, FSize, FSize);
    Picture.Canvas.Pen.Color := FPaperColor;
    Picture.Canvas.Brush.Color := FpaperColor;
    case Shape of
      psRect: Picture.ReplaceRectColor(FromColor, ToColor, R, 6, stRoundRect);
      psCircle: Picture.ReplaceRectColor(FromColor, ToColor, R, 6, stEllipse);
    end;
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(R);
end;

procedure TCustomPictureEdit.Spray(X, Y: integer; Shift: TShiftState);
var
  R: TRect;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  // if not (ssLeft in Shift) then Picture.EraseMode := ermErase;
  //  Picture.RandomEnabled := True;
  try
    //   Picture.Canvas.Pen.Color:=FFillColor;
    //   Picture.Canvas.Brush.Color:=FFillColor;
    R := Bounds(X - FSize div 2, Y - FSize div 2, FSize, FSize);
    {case Shape of
    psRect: Picture.Canvas.FillRect(R.Left, R.Top, R.Right, R.Bottom);
    psCircle: Picture.FillEllipse(R.Left, R.Top, R.Right, R.Bottom);
    end;  }
    Picture.Spray(X, Y, 11, FFillColor);
  finally
    Picture.EraseMode := ermNone;
    Picture.RandomEnabled := False;
    EndDraw;
  end;
  InvalidatePictureRect(R);
end;

procedure TCustomPictureEdit.Brush(X, Y: integer; Shift: TShiftState);
var
  R: TRect;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  Picture.RandomEnabled := True;
  try
    Picture.Canvas.Pen.Color := FFillColor;
    Picture.Canvas.Brush.Color := FFillColor;
    R := Bounds(X - FSize div 2, Y - FSize div 2, FSize, FSize);
    case Shape of
      psRect: Picture.Canvas.FillRect(R.Left, R.Top, R.Right, R.Bottom);
      psCircle: Picture.FillEllipse(R.Left, R.Top, R.Right, R.Bottom);
    end;
  finally
    Picture.EraseMode := ermNone;
    Picture.RandomEnabled := False;
    EndDraw;
  end;
  InvalidatePictureRect(R);
end;

procedure TCustomPictureEdit.Line(X1, Y1, X2, Y2: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;

  Picture.Canvas.Pen.Color := FOutLineColor;
  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  try
    if (X1 = X2) and (Y1 = Y2) and (Tool = ptPen) then
      Picture.Canvas.Pixels[X1, Y1] := FOutLineColor
    else
      Picture.Canvas.Line(X1, Y1, X2, Y2);
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(Rect(X1, Y1, X2, Y2));
end;

procedure TCustomPictureEdit.Rectangle(X1, Y1, X2, Y2: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  try
    Picture.Canvas.Brush.Color := FFillColor;
    Picture.Canvas.Pen.Color := FOutlineColor;
    if FFuzzy then
    begin
      Picture.FuzzyRectangle(X1, Y1, X2, Y2);
    end
    else
    begin
      if FFillAlpha = 100 then
        Picture.Canvas.RoundRect(X1, Y1, X2, Y2, FRectangleRoundness,
          FRectangleRoundness)
      else
        Picture.AlphaRectangle(X1, Y1, X2, Y2, FFillAlpha);
    end;
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(Rect(X1, Y1, X2, Y2));
end;

procedure TCustomPictureEdit.Ellipse(X1, Y1, X2, Y2: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  try
    Picture.Canvas.Brush.Color := FFillColor;
    Picture.Canvas.Pen.Color := FOutlineColor;
    Picture.Canvas.Ellipse(X1, Y1, X2, Y2);
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(Rect(X1, Y1, X2, Y2));
end;

procedure TCustomPictureEdit.ProcessPointAddr(X1, Y1, X2, Y2: integer;
  Points: array of TPoint; PCount: integer);
var i, pXUnit, pYUnit: integer;
begin
{  pXUnit := (X2 - X1) div (PCount - 1);
  pYUnit := (Y2 - Y1) div (PCount - 1);
  for i := 0 to PCount - 1 do
  begin
    Points[i].x := X1 + pXUnit * i;
    Points[i].y := Y1 + pYUnit * i;
  end;       }
  Points[0].x := X1 + (X2 - X1) div 2;
  Points[0].y := Y1;
  Points[1].x := X1;
  Points[1].y := Y2;
  Points[2].x := X2;
  Points[2].y := Y2;
end;

procedure TCustomPictureEdit.Polygon(X1, Y1, X2, Y2: integer; Shift: TShiftState);
var
  paddr: array of TPoint; i, pXUnit, pYUnit: integer;
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  if not (ssLeft in Shift) then
    Picture.EraseMode := ermErase;
  try
    Picture.Canvas.Brush.Color := FFillColor;
    Picture.Canvas.Pen.Color := FOutlineColor;
    SetLength(paddr, 3);
    ProcessPointAddr(X1, Y1, X2, Y2, paddr, 3);
    pXUnit := (X2 - X1) div (3 - 1);
    pYUnit := (Y2 - Y1) div (3 - 1);
    for i := 0 to 3 - 1 do
    begin
      paddr[i].x := X1 + pXUnit * i;
      paddr[i].y := Y1 + pYUnit * i;
    end;
 { paddr[0].x := X1 + (X2 - X1) div 2;
  paddr[0].y := Y1;
  paddr[1].x := X1;
  paddr[1].y := Y2;
  paddr[2].x := X2;
  paddr[2].y := Y2;      }
    Picture.Canvas.Polygon(paddr);
  finally
    Picture.EraseMode := ermNone;
    EndDraw;
  end;
  InvalidatePictureRect(Rect(X1, Y1, X2, Y2));
end;

procedure TCustomPictureEdit.ProcessEditorText(X1, Y1, X2, Y2: integer);
var P: TRect;
begin
  TextEditor.IMGCanvas := Picture.Canvas;
  TextEditor.Parent := Self;
  P := PictureToClient(Rect(X1, X2, X1, X2));
  TextEditor.StartEdit(FPictureRect.Left +X1, FPictureRect.Top + Y1, X1, Y1);
end;

procedure TCustomPictureEdit.Mask(X1, Y1, X2, Y2: integer; Shift: TShiftState);
begin
  if Picture = nil then
    Exit;

  BeginDraw;
  try
    Picture.Mask.FillMode := mfXOR;
    if ssLeft in Shift then
      Picture.Mask.FillMode := mfAdd;
    if ssRight in Shift then
      Picture.Mask.FillMode := mfRemove;

    case MaskTool of
      mtEllipse: Picture.Mask.Ellipse(X1, Y1, X2, Y2);
      mtRectangle: Picture.Mask.Rectangle(X1, Y1, X2, Y2);
    end;
  finally
    Picture.Mask.FillMode := mfAdd;
    EndDraw;
  end;
  InvalidatePictureRect(Rect(X1, Y1, X2, Y2));
end;

procedure TCustomPictureEdit.FlipHorizontally;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.FlipHorz;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.FlipVertically;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.FlipVert;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Rotate90Clockwise;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Rotate90;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Rotate180Clockwise;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Rotate180;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Rotate270Clockwise;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Rotate270;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.ColorReplace(ColorFrom, ColorTo: TColor);
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.ColorReplace(ColorFrom, ColorTo);
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.StretchTruncate(AWidth, AHeight: integer);
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.StretchTrunc(AWidth, AHeight);
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.StretchSmooth(AWidth, AHeight: integer;
  Method: TSmoothMethod);
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.StretchSmooth(AWidth, AHeight, Method);
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.ResizePaper(AWidth, AHeight: integer;
  PicturePos: TPicturePos);
var
  New: TPictureBitmap;
  X, Y: integer;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    New := TPictureBitmap.Create(AWidth, AHeight);
    try
      New.PaperColor := PaperColor;
      New.Fill(PaperColor);

      case PicturePos of
        ppTopLeft, ppCenterLeft, ppBottomLeft: X := 0;
        ppTopCenter, ppCentered, ppBottomCenter: X :=
            Round((AWidth - Picture.Width) * 0.5);
        ppTopRight, ppCenterRight, ppBottomRight: X := AWidth - Picture.Width;
      end;

      case PicturePos of
        ppTopLeft, ppTopCenter, ppTopRight: Y := 0;
        ppCenterLeft, ppCentered, ppCenterRight: Y :=
            Round((AHeight - Picture.Height) * 0.5);
        ppBottomLeft, ppBottomCenter, ppBottomRight: Y := AHeight - Picture.Height;
      end;
      New.Draw(X, Y, Picture);
      New.Mask.Draw(X, Y, Picture.Mask);

      Picture.SwapWith(New);
    finally
      New.Free;
    end;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.ClipPaperToMask;
var
  New: TPictureBitmap;
  R: TRect;
begin
  if Picture = nil then
    Exit;
  //  R := Picture.Mask.GetMaskedRect;
  if (Picture.Width = (R.Right - R.Left)) and (Picture.Height =
    (R.Bottom - R.Top)) then
    Exit;

  BeginDraw;
  try
    New := TPictureBitmap.Create(R.Right - R.Left, R.Bottom - R.Top);
    try
      New.Draw(-R.Left, -R.Top, Picture);
      New.Mask.Draw(-R.Left, -R.Top, Picture.Mask);

      Picture.SwapWith(New);
    finally
      New.Free;
    end;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.RemoveMask;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Mask.Clear;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.InvertMask;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Mask.Invert;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Cut;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.CutToClipboard;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Copy;
begin
  if Picture = nil then
    Exit;
  Picture.CopyToClipboard;
end;

procedure TCustomPictureEdit.Paste;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    //Assert(True, 'Implement Paste');
    Picture.PasteFromClipboard;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Delete;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Delete;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.SelectAll;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Mask.ClearWhite;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Invert;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Invert;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Grayscale;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Grayscale;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.Disable;
begin
  if Picture = nil then
    Exit;
  BeginDraw;
  try
    Picture.Disable;
  finally
    EndDraw;
  end;
  UpdatePicture;
end;

procedure TCustomPictureEdit.BeginDraw;
begin
  if Picture = nil then
    Exit;

  Picture.OutlineColor := OutlineColor;
  Picture.FillColor := FillColor;
  Picture.PaperColor := PaperColor;
  Picture.RandomDensity := Round(RandomDensity * MAXRANDOMDENSITY);
  Picture.RectangleRoundness := RectangleRoundness;
  Picture.FloodFillTolerance := Round(FloodFillTolerance * MAXDIFFERENCE);
  Picture.DrawMode := FillAndOutline;
end;

procedure TCustomPictureEdit.EndDraw;
begin
  if Picture = nil then
    Exit;
  FModified := True;
  Change;
end;

procedure TCustomPictureEdit.UpdatePicture;
begin
  UpdatePictureRect;
  PictureSizeChange;
end;

end.

