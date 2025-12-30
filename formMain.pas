{
******************************************************
  Monkey Island Image Converter
  Copyright (c) 2010 - 2026 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}

unit formMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, JvExControls, JvSpeedButton, JvComponentBase,
  JvDragDrop, JvBaseDlg, JvBrowseFolder, pngimage, JvGIFCtrl, JvAnimatedImage,

  JCLFileUtils, uCustomZLibExGZ, JCLSysInfo, JCLStrings, Vcl.Mask,
  System.ImageList, Vcl.ImgList, ImagingComponents;

type
  TfrmMain = class(TForm)
    radiogroupGameSelect: TRadioGroup;
    EditPath: TLabeledEdit;
    JvDragDrop1: TJvDragDrop;
    panelDragDrop: TPanel;
    Label1: TLabel;
    dlgBrowseForFolder: TJvBrowseForFolderDialog;
    panelProgress: TPanel;
    Image2: TImage;
    JvGIFAnimator1: TJvGIFAnimator;
    radiogroupPlatformSelect: TRadioGroup;
    FileOpenDialogFolder: TFileOpenDialog;
    btnOpen: TButton;
    ImageListLarge: TImageList;
    procedure JvDragDrop1Drop(Sender: TObject; Pos: TPoint; Value: TStrings);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);

  private
    FileList: TStringList;
    function RepackMonkey1(FileName: string; SourceDir: string; DestDir: string; BigEndian: boolean = false): boolean;
    function RepackMonkey2(FileName: string; SourceDir: string; DestDir: string; BigEndian: boolean = false): boolean;
    function PurgeFileListOfNonDDS(FileList: TStrings): boolean;
    function ExtractPartialPath(FileName, RootDir: string): string;
    procedure ShowProgress(Running: boolean);
    procedure EnableDisableButtonsGlobal(Value: boolean);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TfrmMain }


function SwapEndianDWord(Value: integer): integer; register;
asm
  bswap eax
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FileList := TStringList.Create;
  //dlgBrowseforfolder.RootDirectory:=fdDesktopDirectory;
  //dlgBrowseforfolder.RootDirectoryPath:=GetDesktopDirectoryFolder;
  //EditPath.Text:=GetDesktopDirectoryFolder;

  Label1.Caption := 'Drag and drop files or folders here' + #13#13 + 'Folders and sub-folders will be searched for .dds files.';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FileList.Free;
end;

procedure TfrmMain.ShowProgress(Running: boolean);
begin
  case Running of
    True:
    begin
      panelProgress.Visible:=true;
      panelProgress.BringToFront;
      jvgifanimator1.Animate := true;
    end;

    False:
    begin
      jvgifanimator1.Animate := false;
      panelProgress.Visible:=false;
      panelProgress.SendToBack;
    end;
  end;
end;

function TfrmMain.PurgeFileListOfNonDDS(FileList: TStrings): boolean;
var
  i: integer;
  FoundDDSFile: boolean;
begin
  Result := false;
  FoundDDSFile := false;

  for I := FileList.Count - 1 downto 0 do
  begin
    if Uppercase(ExtractFileExt(FileList[i])) = '.DDS' then
      FoundDDSFile := true
    else
      FileList.Delete(i);
  end;

  if (FileList.Count > 0) and (FoundDDSFile = true) then
    Result := true;
end;

procedure TfrmMain.JvDragDrop1Drop(Sender: TObject; Pos: TPoint;
  Value: TStrings);
var
  I, J: Integer;
  IsBigEndian: boolean;
begin
  FileList.Clear;

  if (EditPath.Text = '') or (IsDirectory(EditPath.Text) = false) then
  begin
    ShowMessage('Invalid destination or no destination folder selected!');
    Exit;
  end;


  for I := 0 to Value.Count - 1 do
  begin
    //Is it a folder?
    if IsDirectory(Value[i]) then
    begin
      if AdvBuildFilelist(IncludeTrailingPathDelimiter( Value[i] ) + '*.*' , faAnyFile, FileList, amAny, [flFullNames, flRecursive]) = false then
      begin
        ShowMessage('There was an error scanning the folder: ' + Value[i] + ' Aborting...');
        Exit;
      end;

      //FileList.SaveToFile('c:\users\ben\desktop\MONKEYfileslist.txt');

      if PurgeFileListOfNonDDS(FileList) = false then
      begin
        ShowMessage('No DDS files were found in the folder: ' + Value[i]);
      end;

      //Add source folder as name/value pair - so can use with ForceDirectories later
      for j := 0 to FileList.Count - 1 do
      begin
        FileList[j] := FileList[j] + '=' + IncludeTrailingPathDelimiter(Value[i]);
      end;

    end
    else
    //Is it a file?
    if Uppercase(ExtractFileExt(Value[i])) = '.DDS' then
      FileList.Add(Value[i] + '=' + IncludeTrailingPathDelimiter(ExtractFilePath(Value[i]))); //Add source folder as name/value pair - so can use with ForceDirectories later
  end;

  if FileList.Count = 0 then
  begin
    ShowMessage('No DDS files were found in any of the dragged and dropped files or folders!');
    Exit;
  end;

  ShowProgress(true);
  EnableDisableButtonsGlobal(false);
  try
    case radiogroupPlatformSelect.ItemIndex of
      0:  IsBigEndian := false;
      1:  IsBigEndian := true;
      else
          IsBigEndian := false;
    end;

    for I := 0 to FileList.Count - 1 do
    begin
      case radiogroupGameSelect.ItemIndex of
        0:  RepackMonkey1(FileList.Names[i], FileList.ValueFromIndex[i], EditPath.Text, IsBigEndian);
        1:  RepackMonkey2(FileList.Names[i], FileList.ValueFromIndex[i] ,EditPath.Text, IsBigEndian);
      end;

      Application.ProcessMessages;
    end;

  finally
    ShowProgress(false);
    EnableDisableButtonsGlobal(true);
    MessageBeep(0);
  end;
end;



procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if Win32MajorVersion >= 6 then //Vista and above
  begin
    if FileOpenDialogFolder.Execute then
      editPath.Text := FileOpenDialogFolder.FileName;
  end
  else
  begin
    if dlgBrowseForFolder.Execute then
      editPath.Text := dlgBrowseForFolder.Directory;
  end;
end;

procedure TfrmMain.EnableDisableButtonsGlobal(Value: boolean);
begin
  btnOpen.Enabled := Value;
  editPath.Enabled := Value;
  JVDragDrop1.AcceptDrag := Value;
  RadioGroupGameSelect.Enabled := Value;
end;

function TfrmMain.ExtractPartialPath(FileName, RootDir: string): string;
begin
  Result := StrAfter( IncludeTrailingPathDelimiter(RootDir), ExtractFilePath(FileName));
end;

function TfrmMain.RepackMonkey1(FileName, SourceDir, DestDir: string; BigEndian: boolean = false): boolean;
var
  Width, Height: integer;
  Temp: DWord;
  SourceFile, DestFile: TFileStream;
  NewDestDir: string;
begin
  Result := false;

  SourceFile := TFileStream.Create(FileName, fmOpenRead);
  try
    //Sanity check first
    SourceFile.Read(Temp, 4);
    if Temp <> 542327876 then //'DDS '
      exit;

    SourceFile.Position := 12;
    SourceFile.Read(Height, 4);
    SourceFile.Read(Width, 4);
    SourceFile.Position := 84; //FOURCC
    SourceFile.Read(Temp, 4); // Store the FOURCC for later
    SourceFile.Position := 128; //End of the dds header

    //Correct for big endian
    if BigEndian then Width := SwapEndianDWord(Width);
    if BigEndian then Height := SwapEndianDWord(Height);

    NewDestDir :=  IncludeTrailingPathDelimiter(DestDir) + ExtractPartialPath( FileName, SourceDir);
    ForceDirectories( NewDestDir );

    DestFile := TFileStream.Create(
                  IncludeTrailingPathDelimiter(NewDestDir) +
                  ChangeFileExt( ExtractFileName( FileName ), '.dxt') ,
                  fmCreate);
    try
      DestFile.Write(Temp, SizeOf(Temp)); //FOURCC eg DXT5
      Temp := Width;
      DestFile.Write(Temp, SizeOf(Temp));
      Temp := Height;
      DestFile.Write(Temp, SizeOf(Temp));

      //Copy over the data
      DestFile.CopyFrom(SourceFile, SourceFile.Size - SourceFile.Position);

      if DestFile.Size > 12 then result := true;
    finally
      DestFile.Free;
    end;

  finally
    SourceFile.Free;
  end;
end;

function TfrmMain.RepackMonkey2(FileName, SourceDir, DestDir: string; BigEndian: boolean = false): boolean;
var
  Width, Height: integer;
  Temp: DWord;
  SourceFile, DestFile: TFileStream;
  NewDestDir: string;
begin
  Result := false;

  SourceFile := TFileStream.Create(FileName, fmOpenRead);
  try
    //Sanity check first
    SourceFile.Read(Temp, 4);
    if Temp <> 542327876 then //'DDS '
      exit;

    SourceFile.Position := 12;
    SourceFile.Read(Height, 4);
    SourceFile.Read(Width, 4);
    SourceFile.Position := 84; //FOURCC
    SourceFile.Read(Temp, 4); // Store the FOURCC for later
    SourceFile.Position := 128; //End of the dds header

    //Correct for big endian
    if BigEndian then Width := SwapEndianDWord(Width);
    if BigEndian then Height := SwapEndianDWord(Height);

    NewDestDir :=  IncludeTrailingPathDelimiter(DestDir) + ExtractPartialPath( FileName, SourceDir);
    ForceDirectories( NewDestDir );

    DestFile := TFileStream.Create(
                  IncludeTrailingPathDelimiter(NewDestDir) +
                  ChangeFileExt( ExtractFileName( FileName ), '.dxt') ,
                  fmCreate);
    try
      DestFile.Write(Temp, SizeOf(Temp)); //FOURCC eg DXT5
      Temp := Width;
      DestFile.Write(Temp, SizeOf(Temp));
      Temp := Height;
      DestFile.Write(Temp, SizeOf(Temp));

      //GZip the data
      GZCompressStream(SourceFile, DestFile, '', '', 0);

      if DestFile.Size > 12 then result := true;
    finally
      DestFile.Free;
    end;

  finally
    SourceFile.Free;
  end;
end;


end.
