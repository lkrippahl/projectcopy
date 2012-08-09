{*******************************************************************************
This source file is public domain. It is provided as is, with no explicit
or implied warranties regarding anything whatsoever.
********************************************************************************
Author: Ludwig Krippahl
Date: 15.8.2011
Purpose:
  Utilities and class for listing files in folder and subfolders
Requirements:
Revisions:
To do:
*******************************************************************************}

unit enumeratefolders;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, basetypes, stringutils,quicksort;

type
  TEFCallback=procedure(Folder:string) of object;

  { TEFFileTree }

  TEFFileTree=class
  protected
    FBaseFolder:string;
    FFiles:TSimpleStrings;
    procedure FolderEnumCallback(Folder:string);
  public
    constructor Create(BaseFolder:string);
    function ListByExtension(Ext:string;CaseSensitive:Boolean=False):TSimpleStrings;
      //Ext includes the dot. E.g. '.bat'
    function ListByFolder(Folder:string):TSimpleStrings;
      //Folder is full path name if BaseFolder was too, otherwise local.
      //TODO:Not Implemented
    function ListFolders(ClipBaseFolder:Boolean=True;SortByLength:Boolean=True):TSimpleStrings;
    function FindFile(FileName:string):string;
      //returns first instance of filename
      //NOTE: Case sensitive!
      //TODO: wildcards
    function FileExists(FileWithPath:string):Boolean;
      //Case sensitive
    procedure ResetList(NewFiles:TSimpleStrings);
  end;


procedure EFEnumerate(Folder:string;Callback:TEFCallback);
function EFListFiles(Folder:string):TSimpleStrings;


implementation

function EFListFiles(Folder:string):TSimpleStrings;

var
  srec:TSearchRec;

begin
  Result:=nil;
  if FindFirst(Folder+PathDelim+'*.*',faAnyFile,srec)=0 then
    repeat
    if ((srec.Attr and faDirectory)=0) then
      AddToArray(Folder+PathDelim+srec.Name,Result);
    until FindNext(srec)<>0;
  FindClose(srec);
end;

procedure EFEnumerate(Folder:string;Callback:TEFCallback);

var
  srec:TSearchRec;

begin
  if Assigned(Callback) then Callback(Folder);
  if FindFirst(Folder+PathDelim+'*.*',faAnyFile,srec)=0 then
    repeat
    if  ((srec.Attr and faDirectory)=faDirectory) and
      (srec.Name<>'.') and (srec.Name<>'..') then
      EFEnumerate(Folder+PathDelim+srec.Name,Callback);
    until FindNext(srec)<>0;
  FindClose(srec);
end;

{ TEFFileTree }

procedure TEFFileTree.FolderEnumCallback(Folder: string);

begin
  FFiles:=Concatenate(FFiles,EFListFiles(Folder));
end;

constructor TEFFileTree.Create(BaseFolder: string);
begin
  Assert(BaseFolder<>'','Invalid folder');
  if BaseFolder[Length(BaseFolder)]=PathDelim then
    Delete(BaseFolder,Length(BaseFolder),1);
  inherited Create;
  FBaseFolder:=BaseFolder;
  EFEnumerate(BaseFolder,@FolderEnumCallback);
end;

function TEFFileTree.ListByExtension(Ext: string; CaseSensitive: Boolean=False): TSimpleStrings;

var
  fileext:string;
  f:Integer;

begin
  Result:=nil;
  if not CaseSensitive then
    Ext:=UpperCase(Ext);
  for f:=0 to High(FFiles) do
    begin
    fileext:=ExtractFileExt(FFiles[f]);
    if not CaseSensitive then
      fileext:=UpperCase(fileext);
    if fileext=ext then
      AddToArray(FFiles[f],Result);
    end;
end;

function TEFFileTree.ListByFolder(Folder: string): TSimpleStrings;
begin
  Assert(False,'Not implemented'); //TODO: Implement...
end;

function TEFFileTree.ListFolders(ClipBaseFolder: Boolean; SortByLength: Boolean): TSimpleStrings;

var
  f:Integer;
  oldfold,newfold:string;
  tmpstrings:TSimpleStrings;
  lens:TIntegers;
begin
  Result:=nil;
  oldfold:='';
  for f:=0 to High(FFiles) do
    begin
    newfold:=ExtractFileDir(FFiles[f]);
    if newfold<>oldfold then
      begin
      oldfold:=newfold;
      if ClipBaseFolder then Delete(newfold,1,Length(FBaseFolder));
      repeat
        if LastIndexOf(newfold,Result)<0 then
            AddToArray(newfold,Result);
         newfold:=ExtractFileDir(newfold);
      until Length(newfold)<2;
        //ususlly newfold is only the path delimiter
        //TO DO:test this better
      end;
    end;
  if SortByLength then
    begin
    SetLength(lens,Length(Result));
    SetLength(tmpstrings,Length(Result));
    for f:=0 to High(Result) do
      lens[f]:=Length(Result[f]);
    lens:=QSAscendingIndex(lens);
    for f:=0 to High(lens) do
      tmpstrings[f]:=Result[lens[f]];
    Result:=tmpstrings;
    end;
end;

function TEFFileTree.FindFile(FileName: string): string;

var f,p:Integer;

begin
  Result:='';
  for f:=0 to High(FFiles) do
    if FileName=ExtractFileName(FFiles[f]) then
      begin
      Result:=FFiles[f];
      Break;
      end;
end;

function TEFFileTree.FileExists(FileWithPath: string): Boolean;
begin
  Result:=FirstIndexOf(FileWithPath,FFiles)>=0;
  //DEBUG
  //if Result then writeln('Found: '+FileWithPath)
  //else writeln('Not Found: '+FileWithPath)
end;

procedure TEFFileTree.ResetList(NewFiles: TSimpleStrings);
begin
  FFiles:=Copy(NewFiles,0,Length(NewFiles));
end;



end.

