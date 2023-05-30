unit updfviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Menus, Grids, ExtCtrls,
  LCLIntf, ComCtrls, dateutils, BCTypes, Types, Math,
  BGRAVirtualScreen, PDFDoc, BGRABitmap, Search;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnPagFore: TButton;
    btnPagBack: TButton;
    tTotPag: TEdit;
    HScrollBar: TScrollBar;
    VScrollBar: TScrollBar;
    vsPDF: TBGRAVirtualScreen;
    btnFind: TButton;
    btnSelDir: TButton;
    chkSubDir: TCheckBox;
    cboPath: TComboBox;
    GroupBox1: TGroupBox;
    pnlHolder: TPanel;
    tRename: TEdit;
    Label6: TLabel;
    grpbox1: TGroupBox;
    ProgressBar1: TProgressBar;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StatusBar1: TStatusBar;
    mygrid: TStringGrid;
    procedure btnFindClick(Sender: TObject);
    procedure btnPagBackClick(Sender: TObject);
    procedure btnSelDirClick(Sender: TObject);
    procedure btnPagForeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure HScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure mygridDblClick(Sender: TObject);
    procedure ShowGrid();
    procedure GotoPage(InPageNumber: Integer);
    procedure VScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure vsPDFMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure vsPDFMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure vsPDFRedraw(Sender: TObject; Bitmap: TBGRABitmap);
  private
    { private declarations }
  public
    { public declarations }
  end;

const
{$ifdef MSWindows}
  MYSLASH = '\';
  EDITION = 'Win32';
{$endif}
{$ifdef Unix}
  MYSLASH = '/';
  EDITION = 'Linux';
{$endif}
{$ifdef BSD}
  EDITION = 'MacOSX';
{$endif}
  VERSION = 'v1.00b';


var
  frmMain: TfrmMain;
  myPDFDoc: TPDFDoc;
  PDFZoom: Double;

implementation

{$R *.lfm}

{ TfrmMain }

procedure tfrmMain.GotoPage(InPageNumber: Integer);
begin
  if myPDFDoc <> nil then
  begin
    myPDFDoc.SetContainerWidthAndHeight(pnlHolder.Width, pnlHolder.Height);
    if myPDFDoc.LoadPage(InPageNumber) > -1 then
    begin
      try
        myPDFDoc.ResizeBitmap(vsPDF, PDFZoom, HScrollBar, VScrollBar);
      except
        IetsLooptVerkeerd:=True;
      end;
      myPDFDoc.CenterPreview(vsPDF, pnlHolder);
      tTotPag.text:= Format('%d / %d', [myPDFDoc.FPageNum+1, myPDFDoc.GetPageCount]);
    end;
  end;
end;

procedure TfrmMain.VScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  vsPDF.SetBounds(vsPDF.Left, -ScrollPos, vsPDF.Width, vsPDF.Height);
end;

procedure TfrmMain.vsPDFMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin

end;

procedure TfrmMain.vsPDFMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin

end;

procedure TfrmMain.vsPDFRedraw(Sender: TObject; Bitmap: TBGRABitmap);
begin
  if myPDFDoc <> nil then
    begin
      myPDFDoc.SetContainerWidthAndHeight(pnlHolder.Width, pnlHolder.Height);
      myPDFDoc.RedrawBitmap(Bitmap);
    end;
end;

procedure TfrmMain.ShowGrid();
begin
  mygrid.colcount:= 6;
  mygrid.RowCount:= 1;
  mygrid.Cells[0,0]:= 'Nr.';
  mygrid.Cells[1,0]:= 'Filename';
  mygrid.Cells[2,0]:= 'File Date';
  mygrid.Cells[3,0]:= 'File Size';
  mygrid.Cells[4,0]:= 'Path';
  mygrid.Cells[5,0]:= 'Fullname';


  mygrid.ColWidths[0]:= 30;
  mygrid.ColWidths[1]:= 500;
  mygrid.ColWidths[2]:= 150;
  mygrid.ColWidths[3]:= 100;
  mygrid.ColWidths[4]:= 600;
  mygrid.ColWidths[5]:= 0;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
   i: integer;
   EnvVars: TStringList;
begin
     self.Caption:= 'TPDFViewer ['+EDITION+'] '+VERSION+' © 2023 by ALEXSOFT';
     cboPath.Clear;
     mygrid.clear;

     ShowGrid();

     EnvVars := TStringList.Create;
     for i:= 0 to GetEnvironmentVariableCount - 1 do
         EnvVars.Add(GetEnvironmentString(i));

     if (EDITION = 'Win32') then begin
        cboPath.Items.Add(EnvVars.Values['USERPROFILE']);
        cboPath.Items.Add(EnvVars.Values['USERPROFILE']+'\Desktop\');
        cboPath.Items.Add(EnvVars.Values['USERPROFILE']+'\Documenti\');
     end else begin
         cboPath.Items.Add(EnvVars.Values['HOME']);
     end;

     setExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     PDFZoom:=2/2;

end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  mygrid.Height:= statusbar1.Top - mygrid.Top ;
  progressbar1.Top:= statusbar1.Top+5;
  progressbar1.Left:= statusbar1.Left+5;
end;

procedure TfrmMain.HScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
    vsPDF.SetBounds(-ScrollPos, vsPDF.Top, vsPDF.Width, vsPDF.Height);

end;

procedure TfrmMain.mygridDblClick(Sender: TObject);
var
   filename: string;
begin
  if (mygrid.Row > 0) then begin
     filename:=mygrid.Cells[5,mygrid.Row];
     if (FileExists(filename)) then begin
         myPDFDoc := TPDFDoc.Create;
         myPDFDoc.OpenDocument(filename);
         Try
           GotoPage(0);
         except
             IetslooptVerkeerd:=True;
         end;
     end else
         ShowMessage('File '+filename+' not found!');
     end;
end;

procedure TfrmMain.btnFindClick(Sender: TObject);
var
  ftime,fdata,fullname: string;
  irow,itot: integer;
  myDir,myPathStart: string;
  T: TFileSearch;
  i,ii,fileT: Integer;
  isumsize: double;
  drive,fileN,pathN: string;
  fileD: longint;
  fileS: Int64;
  totfiles: integer;
  FindF: TSearchRec;

begin
  self.Cursor:= crHourGlass;
  myDir:= cboPath.Text;

  ProgressBar1.Min:= 0;
  ProgressBar1.Position:=1;

  T:= TFileSearch.Create;
  T.Path:= myDir;
  T.Filters:= '*.PDF';

  if (chkSubDir.Checked) then
     T.SearchSubdirectories := True
  else
     T.SearchSubdirectories := false;

  T.Search;
  ProgressBar1.Max:= T.Count;
  ii:= 1;
  totfiles:= T.Count-1;

  mygrid.clear;
  ShowGrid();
  mygrid.RowCount:= 2;
  irow:= 1;
  myPathStart:= cboPath.Text;

  if (copy(myPathStart,1,length(myPathStart)) = MYSLASH) then
     myPathStart:= myPathStart + MYSLASH;

  isumsize:=0;
  For i := 0 To totfiles Do begin
      fullname:= T[i];
      drive:= ExtractFileDrive(fullname);
      fileN:= ExtractFileName(fullname);
      pathN:= myPathStart+ExtractRelativePath(drive,ExtractFilePath(fullname));
      fileT:= 0;

      fileD:= FileAge(T[i]);
      fdata:= copy(DateTimeToStr(FileDateTodateTime(fileD)),1,10);
      ftime:= copy(DateTimeToStr(FileDateTodateTime(fileD)),12,8);
      FindFirst(T[i],faAnyFile,FindF);
      fileS:= FindF.Size;

      ProgressBar1.Position:= ii;

      mygrid.Cells[0,irow]:= IntToStr(irow);
      mygrid.Cells[1,irow]:= fileN;
      mygrid.Cells[2,irow]:= copy(fdata,7,4)+'-'+copy(fdata,4,2)+'-'+copy(fdata,1,2)+' '+ftime;
      mygrid.cells[4,irow]:= pathN;
      mygrid.cells[5,irow]:= T[i];

      if fileS > 0 then begin
         isumsize:= isumsize + fileS;
         mygrid.Cells[3,irow]:= Format('%12d',[fileS])
      end else
         mygrid.Cells[3,irow]:= Format('%12d',[0]);

      statusbar1.Panels[1].Text:= 'File Count: '+IntToStr(irow);
      if isumsize > 100000000 then
         statusbar1.Panels[2].Text:= 'File Size: '+FloatToStrF(isumsize/power(1024,3),ffNumber,10,2)+' GB'
      else if isumsize > 10000000 then
            statusbar1.Panels[2].Text:= 'File Size: '+FloatToStrF(isumsize/power(1024,2),ffNumber,10,2)+' MB'
      else
            statusbar1.Panels[2].Text:= 'File Size: '+FloatToStrF(isumsize/1024,ffNumber,10,2)+' KB';

      statusbar1.Refresh;
      Inc(irow);
      mygrid.RowCount:= irow+1;
      Inc(ii);
      mygrid.Refresh;
  end;
  mygrid.RowCount:= irow;

  T.Free;
  ProgressBar1.Position:=0;
  self.Cursor:= crdefault;

end;

procedure TfrmMain.btnPagBackClick(Sender: TObject);
begin
  if myPDFDoc <> nil then
  begin
    if myPDFDoc.FPageNum-1 >= 0 then
      if ((myPDFDoc.GetPageCount) > 0) then GotoPage(myPDFDoc.FPageNum-1);
  end;

end;


procedure TfrmMain.btnSelDirClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then begin
     cboPath.Text:= SelectDirectoryDialog1.FileName;
  end;

end;

procedure TfrmMain.btnPagForeClick(Sender: TObject);
begin
  if myPDFDoc <> nil then
  begin
     if myPDFDoc.FPageNum+1 < myPDFDoc.GetPageCount then
      if ((myPDFDoc.GetPageCount) > 0) then GotoPage(myPDFDoc.FPageNum+1);
  end;

end;

end.
