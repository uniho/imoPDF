unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    ExecPath: string;
    procedure Doing(const filename: string);
    procedure AfterShow(Data: PtrInt);
    procedure BeforeDoing;
    procedure AfterDoing;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  Process, UTF8Process, windows;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  ExecPath:=ExtractFilePath(ParamStr(0));
  Caption:='imoPDF';
  Label1.Caption:='imoPDF へようこそ。'#$0d#$0d+
   'このアプリは、PDF を画像だけで構成されるPDF に変換します。'#$0d#$0d+
   'ここに PDF をドラッグすると変換を開始します。'+
   '';
  AllowDropFiles:=true;
  FormStyle:=fsSystemStayOnTop;
  BorderIcons:=BorderIcons-[biMinimize];
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
var
  s: string;
begin
  BeforeDoing;
  for s in FileNames do begin
    Doing(s);
  end;
  AfterDoing;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  SetWindowLong(getwindow(Handle,GW_OWNER),GWL_STYLE,0);
  SetWindowLong(getwindow(Handle,GW_OWNER),GWL_EXSTYLE,0);
  OnShow:=nil;
  Application.QueueAsyncCall(@AfterShow, 0);
end;

procedure TForm1.AfterShow(Data: PtrInt);
var
  i: integer;
begin
  if ParamCount > 0 then begin
    BeforeDoing;
    for i:=1 to ParamCount do begin
      Doing(ParamStr(i));
    end;
    AfterDoing;
  end;
end;

procedure TForm1.BeforeDoing;
begin
  FormStyle:=fsNormal;
  BorderIcons:=BorderIcons+[biMinimize];
end;

procedure TForm1.AfterDoing;
begin
  Label1.Caption:=#$0d#$0d'処理が終了しました。';
  Windows.MessageBeep(0);
  Close;
end;

procedure TForm1.Doing(const filename: string);
var
  sl: TStringList;
  s, fn, cmd: string;
  i: integer;
  pr: TProcessUTF8;
begin
  Label1.Caption:=#$0d#$0d'作業中です。しばらくお待ちください。';
  try
    fn:=ChangeFileExt(filename, '');
    sl:=TStringList.Create;
    try
      pr:=TProcessUTF8.Create(nil);
      try
        sl.LoadFromFile(ExecPath+'imopdf.ini');
        cmd:=SysUtils.GetEnvironmentVariable('comspec');
        for i:= 0 to sl.Count-1 do begin
          s:=Trim(sl[i]);
          if (s = '') or (s[1] = ';') then continue;
          s:=StringReplace(s, '%cp%', ExecPath, [rfReplaceAll]);
          s:=StringReplace(s, '%fn%', fn, [rfReplaceAll]);
          s:=StringReplace(s, '%cmd%', cmd, [rfReplaceAll]);
          pr.CommandLine:=s;
          pr.Options:=pr.Options+[poNoConsole];
          pr.Execute;
          while pr.Running do begin
            Sleep(10);
            Application.ProcessMessages;
          end;
        end;
      finally
        pr.Free;
      end;
    finally
      sl.Free;
    end;
  except
    Label1.Caption:=#$0d#$0d'エラーが発生しました';
  end;
end;

end.

