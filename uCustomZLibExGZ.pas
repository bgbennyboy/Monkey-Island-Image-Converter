{
******************************************************
  Monkey Island Image Converter
  Copyright (c) 2010 - 2026 Bennyboy
  Http://quickandeasysoftware.net
******************************************************
}
{
Based on JCL ZLibExGz unit
}

unit uCustomZLibExGZ;

interface

uses
  Classes, SysUtils, ZLibExGZ, ZLibEx, ZLibExApi;

procedure GZCompressStream(inStream, outStream: TStream; const fileName,
  comment: AnsiString; dateTime: TDateTime);

implementation

function DateTimeToUnix(const AValue: TDateTime): Cardinal;
begin
  Result := Round((AValue - UnixDateDelta) * SecsPerDay);
end;

//Mostly same as usual procedure in ZLibExGZ unit except parameters changed for MI2-SE
procedure GZCompressStream(inStream, outStream: TStream; const fileName,
  comment: AnsiString; dateTime: TDateTime);
const
  bufferSize = 32768;
  GZ_ZLIB_WINDOWBITS = -8;
  GZ_ZLIB_MEMLEVEL   = 1;

  GZ_ASCII_TEXT  = $01;
  GZ_HEADER_CRC  = $02;
  GZ_EXTRA_FIELD = $04;
  GZ_FILENAME    = $08;
  GZ_COMMENT     = $10;
  GZ_RESERVED    = $E0;

  GZ_EXTRA_DEFAULT = 0;
  GZ_EXTRA_MAX     = 2;
  GZ_EXTRA_FASTEST = 4;

  SGZInvalid = 'Invalid GZStream operation!';
var
  header    : TGZHeader;
  trailer   : TGZTrailer;
  buffer    : Array [0..bufferSize-1] of Byte;
  count     : Integer;
  position  : TStreamPos;
  nullString: AnsiString;
begin
  FillChar(header,SizeOf(TGZHeader),0);

  header.Id1 := $1F;
  header.Id2 := $8B;
  header.Method := Z_DEFLATED;

  if dateTime <> 0 then header.Time := DateTimeToUnix(dateTime);

  header.ExtraFlags := GZ_EXTRA_FASTEST;
  header.OS := 0;

  header.Flags := 0;

  if Length(fileName) > 0 then header.Flags := header.Flags or GZ_FILENAME;
  if Length(comment) > 0 then header.Flags := header.Flags or GZ_COMMENT;

  FillChar(trailer, SizeOf(TGZTrailer), 0);

  trailer.Crc := 0;

  position := inStream.Position;

  while inStream.Position < inStream.Size do
  begin
    count := inStream.Read(buffer[0],bufferSize);

    trailer.Crc := ZCrc32(trailer.Crc,buffer[0],count);
  end;

  inStream.Position := position;

  trailer.Size := inStream.Size - inStream.Position;

  outStream.Write(header, SizeOf(TGZHeader));

  if Length(filename) > 0 then
  begin
    nullString := fileName + #$00;

    outStream.Write(nullString[1], Length(nullString));
  end;

  if Length(comment) > 0 then
  begin
    nullString := comment + #$00;

    outStream.Write(nullString[1], Length(nullString));
  end;

  ZCompressStream2(inStream, outStream, zcFastest, GZ_ZLIB_WINDOWBITS,
    GZ_ZLIB_MEMLEVEL, zsDefault);

  outStream.Write(trailer, SizeOf(TGZTrailer));
end;

end.
