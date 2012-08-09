{*******************************************************************************
                    This file is part of projectcopy

This source file is public domain. It is provided as is, with no explicit
or implied warranties regarding anything whatsoever.
********************************************************************************
Author: Ludwig Krippahl
Date: 15.8.2011
Purpose:
  Copies the source files for the specified projects, along with all
  unit files used by those projects (recursively) that are in the same
  base folder.
Revisions:
TODO:
  Ignore coments in FPC uses clauses
  Add support for python projects


*******************************************************************************}
program projectcopy;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, enumeratefolders, CustApp, basetypes, stringutils, fileutil
  { you can add units after this };

type

  { TFPCProjectCopy }

  TFPCProjectCopy = class(TCustomApplication)
  protected
    FSourceFolder,FDestFolder:string;
    FFilesList:TEFFileTree;
    FProjects:TSimpleStrings;
    FAddedUnits:TSimpleStrings;
    FAddedFiles:TSimpleStrings;
    procedure DoRun; override;
    procedure AddFPC;
    procedure AddFPCUnit(PasFile:string);
    function ListUsedFPCModules(Sl:TStringList):TSimpleStrings;
    procedure CopyTree;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TFPCProjectCopy }

procedure TFPCProjectCopy.DoRun;
var
  ErrorMsg: String;
  f:Integer;

begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h','help');
  if (ErrorMsg<>'') or (ParamCount<3) or HasOption('h','help') then
    begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  FAddedUnits:=nil;
  FAddedFiles:=nil;
  FSourceFolder:=ParamStr(1);
  FDestFolder:=ParamStr(2);
  SetLength(FProjects,ParamCount-2);
  for f:=3 to ParamCount do
    FProjects[f-3]:=ParamStr(f);
  FFilesList:=TEFFileTree.Create(FSourceFolder);
  AddFPC;
  CopyTree;
  // stop program loop
  Terminate;
end;

procedure TFPCProjectCopy.AddFPC;

var
  f:integer;
  tmpfile:string;

procedure AddFile(FileName:string);

var tmp:string;

begin
  tmp:=FFilesList.FindFile(FileName+'.pas');
  if tmp<>'' then AddToArray(tmp,FAddedFiles)
  else
    begin
    tmp:=FFilesList.FindFile(FileName+'.lpr');
    if tmp<>'' then AddToArray(tmp,FAddedFiles)
    end;
  if tmp='' then Exit;

  tmp:=ChangeFileExt(tmp,'.res');
  if FFilesList.FileExists(tmp) then
    AddToArray(tmp,FAddedFiles);

  tmp:=ChangeFileExt(tmp,'.lpi');
  if FFilesList.FileExists(tmp) then
    AddToArray(tmp,FAddedFiles);

  tmp:=ChangeFileExt(tmp,'.lfm');
  if FFilesList.FileExists(tmp) then
    AddToArray(tmp,FAddedFiles);

  tmp:=ChangeFileExt(tmp,'.ico');
  if FFilesList.FileExists(tmp) then
    AddToArray(tmp,FAddedFiles);

end;

begin
  for f:=0 to High(FProjects) do
    begin
    tmpfile:=FFilesList.FindFile(FProjects[f]+'.pas');
    if tmpfile='' then
      tmpfile:=FFilesList.FindFile(FProjects[f]+'.lpr');
    if tmpfile<>'' then
      begin
      writeln(tmpfile);
      AddFPCUnit(tmpfile);
      AddFile(FProjects[f]);
      end
    else WriteLn('Warning: ',FProjects[f]+' (.pas or .lpr) not found.');
    end;
  for f:=0 to High(FAddedUnits) do
    AddFile(FAddedUnits[f]);
end;

procedure TFPCProjectCopy.AddFPCUnit(PasFile:string);

var
  f:Integer;
  tmpfile:string;
  sl:TStringList;
  units:TSimpleStrings;

begin
  sl:=TStringList.Create;
  sl.LoadFromFile(PasFile);
  units:=ListUsedFPCModules(sl);
  for f:=0 to High(units) do
    begin
    if LastIndexOf(units[f],FAddedUnits)<0 then
      begin
      tmpfile:=FFilesList.FindFile(units[f]+'.pas');
      if tmpfile<>'' then
        begin
        AddToArray(units[f],FAddedUnits);
        AddFPCUnit(tmpfile);
        end;
      end;
    end;
  sl.Free;
end;

function TFPCProjectCopy.ListUsedFPCModules(Sl: TStringList): TSimpleStrings;

var
  f:Integer;
  tmp,line,pasfile:string;
  units:TSimpleStrings;
begin
  f:=0;
  line:='';
  Result:=nil;
  //there may be more than one uses clause
  repeat
    while (f<Sl.Count) and (Pos('USES',UpperCase(Sl.Strings[f]))<1) do
      Inc(f);
    if (f<Sl.Count) then
      begin
      tmp:=Sl.Strings[f];
      Delete(tmp,1,Pos('USES',UpperCase(tmp))+3);
      line:=line+tmp;
      Inc(f);
      while (f<Sl.Count) and (Pos(';',line)<1) do
        begin
        line:=line+Sl.Strings[f];
        Inc(f);
        end;
      if Pos(';',line)>0 then Delete(line,Pos(';',line),Length(line));
      line:=line+',';
      end;
  until (f>=Sl.Count);
  if line<>'' then
    begin
    line:=Deblank(line);
    Result:=SplitString(line,',');
    end;

end;

procedure TFPCProjectCopy.CopyTree;

var
  folders:TSimpleStrings;
  f:Integer;
  newfile:string;
begin
  FFilesList.ResetList(FAddedFiles);
  folders:=FFilesList.ListFolders;
  WriteLn('Folder Tree:');
  for f:=0 to High(folders) do WriteLn(folders[f]);

  for f:=0 to High(folders) do
    if not DirectoryExists(FDestFolder+folders[f]) then
      CreateDir(FDestFolder+folders[f]);

  WriteLn('Files Copied:');
  for f:=0 to High(FAddedFiles) do
    begin
    newfile:=FAddedFiles[f];
    Delete(newfile,1,length(FSourceFolder));
    newfile:=FDestFolder+newfile;
    WriteLn(FAddedFiles[f],'->',newfile);
    CopyFile(FAddedFiles[f],newfile);
    end;
end;

constructor TFPCProjectCopy.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TFPCProjectCopy.Destroy;
begin
  inherited Destroy;
end;

procedure TFPCProjectCopy.WriteHelp;
begin
  { add your help code here }
  WriteLn;
  writeln('Use: ',ExeName,' source_folder destination_folder [project1] [project2] ...');
  WriteLn;
  writeln('Source and destination folders are required, followed by the names'+#10+
          'of the project files to copy to destination (name only, no extension)'+#10+
          'Will copy .pas .res .lpi .lpr .lrs .ico and .lfm files for these projects and'+#10+
          'for all units in the dependency tree that are under the source folder,');
  WriteLn('replicating the tree structure in the destination folder');
  WriteLn('Example (Windows):');
  WriteLn;
end;

var
  Application: TFPCProjectCopy;

{$R *.res}

begin
  Application:=TFPCProjectCopy.Create(nil);
  Application.Run;
  Application.Free;
end.

