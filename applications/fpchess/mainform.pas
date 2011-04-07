unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ComCtrls, StdCtrls, Buttons, Spin,
  //
  IDelphiChess_Intf,
  //
  chessdrawer, chessgame, chessconfig, chesstcputils;

type

  { TFormDrawerDelegate }

  TFormDrawerDelegate = class(TChessDrawerDelegate)
  public
    procedure HandleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); override;
    procedure HandleMouseUp(Sender: TObject; Button: TMouseButton;
                          Shift: TShiftState; X, Y: Integer); override;
    procedure HandleMouseDown(Sender: TObject; Button: TMouseButton;
                          Shift: TShiftState; X, Y: Integer); override;
  end;

  { TformChess }

  TformChess = class(TForm)
    btnConnect: TBitBtn;
    btnAI: TBitBtn;
    btnSinglePlayer: TBitBtn;
    btnDirectComm: TBitBtn;
    BitBtn3: TBitBtn;
    btnHotSeat: TBitBtn;
    btnPlayAgainstAI: TButton;
    checkTimer: TCheckBox;
    comboStartColor: TComboBox;
    editWebserviceURL: TLabeledEdit;
    Label1: TLabel;
    labelTime: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    editWebServiceAI: TLabeledEdit;
    labelPos: TLabel;
    editRemoteID: TLabeledEdit;
    editLocalIP: TLabeledEdit;
    editPlayerName: TLabeledEdit;
    pageStart: TPage;
    pageConfigConnection: TPage;
    notebookMain: TNotebook;
    pageConnecting: TPage;
    ProgressBar1: TProgressBar;
    pageGame: TPage;
    spinPlayerTime: TSpinEdit;
    timerChessTimer: TTimer;
    pageWebservice: TPage;
    procedure btnConnectClick(Sender: TObject);
    procedure btnPlayAgainstAIClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HandleMainScreenButton(Sender: TObject);
    procedure pageBeforeShow(Sender: TObject; ANewPage: TPage; ANewIndex: Integer);
    procedure timerChessTimerTimer(Sender: TObject);
  private
    { private declarations }
    function FormatTime(ATimeInMiliseconds: Integer): string;
  public
    { public declarations }
    procedure UpdateCaptions;
    procedure InitializeGameModel;
  end;

var
  formChess: TformChess;
  vFormDrawerDelegate: TFormDrawerDelegate;

implementation

{$R *.lfm}

const
  INT_PAGE_START = 0;
  INT_PAGE_CONFIGCONNECTION = 1;
  INT_PAGE_CONNECTING = 2;
  INT_PAGE_GAME = 3;
  INT_PAGE_AI = 4;

{ TformChess }

procedure TformChess.HandleMainScreenButton(Sender: TObject);
begin
  if Sender = btnSinglePlayer then
  begin
    notebookMain.PageIndex := INT_PAGE_GAME;
    InitializeGameModel();
  end
  else if Sender = btnHotSeat then
  begin
    notebookMain.PageIndex := INT_PAGE_GAME;
    InitializeGameModel();
  end
  else if Sender = btnDirectComm then notebookMain.PageIndex := INT_PAGE_CONFIGCONNECTION
  else if Sender = btnAI then notebookMain.PageIndex := INT_PAGE_AI;
end;

procedure TformChess.pageBeforeShow(Sender: TObject; ANewPage: TPage; ANewIndex: Integer);
begin
  if ANewIndex = INT_PAGE_CONFIGCONNECTION then
  begin
    editLocalIP.Text := ChessGetLocalIP();
  end;
end;

procedure TformChess.timerChessTimerTimer(Sender: TObject);
begin
  vChessGame.UpdateTimes();
  UpdateCaptions();
end;

function TformChess.FormatTime(ATimeInMiliseconds: Integer): string;
var
  lTimePart: Integer;
begin
  Result := '';

  // Hours
  lTimePart := ATimeInMiliseconds div (60*60*1000);
  if lTimePart > 0 then
    Result := IntToStr(lTimePart) + 'h';

  // Minutes
  lTimePart := (ATimeInMiliseconds div (60*1000)) mod 60;
  if (lTimePart > 0) or (Result <> '') then
    Result := Result + IntToStr(lTimePart) + 'm';

  // Seconds
  lTimePart := (ATimeInMiliseconds div (1000)) mod 60;
  Result := Result + IntToStr(lTimePart) + 's';

  // Miliseconds
  lTimePart := ATimeInMiliseconds mod (1000);
  Result := Result + IntToStr(lTimePart);
end;

procedure TformChess.UpdateCaptions;
var
  lStr: string;
begin
  if vChessGame.CurrentPlayerIsWhite then lStr := 'White playing'
  else lStr := 'Black playing';

  lStr := lStr + Format(' X: %d Y: %d',
    [vChessGame.MouseMovePos.X, vChessGame.MouseMovePos.Y]);

  formChess.labelPos.Caption := lStr;

  lStr := Format('White time: %s Black time: %s',
    [FormatTime(vChessGame.WhitePlayerTime), FormatTime(vChessGame.BlackPlayerTime)]);

  formChess.labelTime.Caption := lStr;
end;

procedure TformChess.InitializeGameModel;
begin
  vChessGame.StartNewGame(comboStartColor.ItemIndex, checkTimer.Checked, spinPlayerTime.Value);
end;

procedure TformChess.FormCreate(Sender: TObject);
begin
  // Creation of internal components
  vChessDrawer := TChessDrawer.Create(Self);
  vChessDrawer.Parent := pageGame;
  vChessDrawer.Top := 50;
  vChessDrawer.Left := 20;
  vChessDrawer.Height := INT_CHESSBOARD_SIZE;
  vChessDrawer.Width := INT_CHESSBOARD_SIZE;
  vChessDrawer.SetDelegate(vFormDrawerDelegate);

  // Loading of resources
  vChessDrawer.LoadImages();
end;

procedure TformChess.btnConnectClick(Sender: TObject);
begin
  notebookMain.PageIndex := INT_PAGE_CONNECTING;

end;

procedure TformChess.btnPlayAgainstAIClick(Sender: TObject);
begin
  InitializeGameModel();

  notebookMain.PageIndex := INT_PAGE_GAME;

  if comboStartColor.ItemIndex = 0 then
    GetNextMoveFromBorlandWS();
end;

{ TFormDrawerDelegate }

procedure TFormDrawerDelegate.HandleMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  vChessGame.MouseMovePos := vChessGame.ClientToBoardCoords(Point(X, Y));
  formChess.UpdateCaptions;
end;

procedure TFormDrawerDelegate.HandleMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  lCoords: TPoint;
begin
  vChessGame.Dragging := False;

  lCoords := vChessGame.ClientToBoardCoords(Point(X, Y));
  if not vChessGame.MovePiece(vChessGame.DragStart, lCoords) then Exit;

  vChessDrawer.Invalidate;
  formChess.UpdateCaptions;
end;

procedure TFormDrawerDelegate.HandleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  lCoords: TPoint;
begin
  lCoords := vChessGame.ClientToBoardCoords(Point(X, Y));
  if not vChessGame.CheckStartMove(lCoords) then Exit;

  vChessGame.Dragging := True;
  vChessGame.DragStart := lCoords;
  vChessDrawer.Invalidate;
  formChess.UpdateCaptions;
end;

initialization

  vFormDrawerDelegate := TFormDrawerDelegate.Create;

finalization

  vFormDrawerDelegate.Free;

end.

