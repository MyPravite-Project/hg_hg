; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#ifndef VERSION
#define FileHandle
#define FileLine
#define VERSION = "unknown"
#if FileHandle = FileOpen(SourcePath + "\..\..\mercurial\__version__.py")
  #expr FileLine = FileRead(FileHandle)
  #expr FileLine = FileRead(FileHandle)
  #define VERSION = Copy(FileLine, Pos('"', FileLine)+1, Len(FileLine)-Pos('"', FileLine)-1)
#endif
#if FileHandle
  #expr FileClose(FileHandle)
#endif
#pragma message "Detected Version: " + VERSION
#endif

[Setup]
AppCopyright=Copyright 2005-2009 Matt Mackall and others
AppName=Mercurial
AppVerName=Mercurial {#VERSION}
InfoAfterFile=contrib/win32/postinstall.txt
LicenseFile=COPYING
ShowLanguageDialog=yes
AppPublisher=Matt Mackall and others
AppPublisherURL=http://mercurial.selenic.com/
AppSupportURL=http://mercurial.selenic.com/
AppUpdatesURL=http://mercurial.selenic.com/
AppID={{4B95A5F1-EF59-4B08-BED8-C891C46121B3}
AppContact=mercurial@selenic.com
OutputBaseFilename=Mercurial-{#VERSION}
DefaultDirName={pf}\Mercurial
SourceDir=..\..
VersionInfoDescription=Mercurial distributed SCM (version {#VERSION})
VersionInfoCopyright=Copyright 2005-2009 Matt Mackall and others
VersionInfoCompany=Matt Mackall and others
InternalCompressLevel=max
SolidCompression=true
SetupIconFile=contrib\win32\mercurial.ico
AllowNoIcons=true
DefaultGroupName=Mercurial
PrivilegesRequired=none

[Files]
Source: contrib\mercurial.el; DestDir: {app}/Contrib
Source: contrib\vim\*.*; DestDir: {app}/Contrib/Vim
Source: contrib\zsh_completion; DestDir: {app}/Contrib
Source: contrib\hgk; DestDir: {app}/Contrib; DestName: hgk.tcl
Source: contrib\win32\ReadMe.html; DestDir: {app}; Flags: isreadme
Source: contrib\mergetools.hgrc; DestDir: {tmp};
Source: contrib\win32\mercurial.ini; DestDir: {app}; DestName: Mercurial.ini; Check: CheckFile; AfterInstall: ConcatenateFiles;
Source: contrib\win32\postinstall.txt; DestDir: {app}; DestName: ReleaseNotes.txt
Source: dist\hg.exe; DestDir: {app}; AfterInstall: Touch('{app}\hg.exe.local')
Source: dist\python*.dll; Destdir: {app}; Flags: skipifsourcedoesntexist
Source: dist\library.zip; DestDir: {app}
Source: dist\mfc*.dll; DestDir: {app}; Flags: skipifsourcedoesntexist
Source: dist\msvc*.dll; DestDir: {app}; Flags: skipifsourcedoesntexist
Source: dist\Microsoft.VC*.CRT.manifest; DestDir: {app}; Flags: skipifsourcedoesntexist
Source: dist\Microsoft.VC*.MFC.manifest; DestDir: {app}; Flags: skipifsourcedoesntexist
Source: dist\w9xpopen.exe; DestDir: {app}
Source: dist\add_path.exe; DestDir: {app}
Source: doc\*.html; DestDir: {app}\Docs
Source: doc\style.css; DestDir: {app}\Docs
Source: locale\*.*; DestDir: {app}\locale; Flags: recursesubdirs createallsubdirs
Source: templates\*.*; DestDir: {app}\Templates; Flags: recursesubdirs createallsubdirs
Source: CONTRIBUTORS; DestDir: {app}; DestName: Contributors.txt
Source: COPYING; DestDir: {app}; DestName: Copying.txt

[INI]
Filename: {app}\Mercurial.url; Section: InternetShortcut; Key: URL; String: http://mercurial.selenic.com/

[UninstallDelete]
Type: files; Name: {app}\Mercurial.url

[Icons]
Name: {group}\Uninstall Mercurial; Filename: {uninstallexe}
Name: {group}\Mercurial Command Reference; Filename: {app}\Docs\hg.1.html
Name: {group}\Mercurial Configuration Files; Filename: {app}\Docs\hgrc.5.html
Name: {group}\Mercurial Ignore Files; Filename: {app}\Docs\hgignore.5.html
Name: {group}\Mercurial Web Site; Filename: {app}\Mercurial.url

[Run]
Filename: "{app}\add_path.exe"; Parameters: "{app}"; Flags: postinstall; Description: "Add the installation path to the search path"

[UninstallRun]
Filename: "{app}\add_path.exe"; Parameters: "/del {app}"

[UninstallDelete]
Type: files; Name: "{app}\hg.exe.local"
[Code]
var
  WriteFile: Boolean;
  CheckDone: Boolean;

function CheckFile(): Boolean;
begin
  if not CheckDone then begin
    WriteFile := True;
    if FileExists(ExpandConstant(CurrentFileName)) then begin
        WriteFile := MsgBox('' + ExpandConstant(CurrentFileName) + '' #13#13 'The file already exists.' #13#13 'Would you like Setup to overwrite it?', mbConfirmation, MB_YESNO) = idYes;
    end;
    CheckDone := True;
  end;
  Result := WriteFile;
end;

procedure ConcatenateFiles();
var
  MergeConfigs: TArrayOfString;
begin
  if LoadStringsFromFile(ExpandConstant('{tmp}\mergetools.hgrc'),MergeConfigs) then begin
    SaveStringsToFile(ExpandConstant(CurrentFileName),MergeConfigs,True);
  end;
end;

procedure Touch(fn: String);
begin
  SaveStringToFile(ExpandConstant(fn), '', False);
end;
