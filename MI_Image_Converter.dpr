{
******************************************************
  Monkey Island Image Converter
  Copyright (c) 2010 - 2026 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}

program MI_Image_Converter;

uses
  Forms,
  formMain in 'formMain.pas' {frmMain},
  uCustomZLibExGZ in 'uCustomZLibExGZ.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Monkey Island Image Converter';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
