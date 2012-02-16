; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
AppName=LazEdit
AppVerName=LazEdit v1.9
AppPublisherURL=http://wiki.lazarus.freepascal.org/LazEdit
AppSupportURL=http://wiki.lazarus.freepascal.org/LazEdit
AppUpdatesURL=http://wiki.lazarus.freepascal.org/LazEdit
DefaultDirName={pf}\LazEdit
DefaultGroupName=Free Pascal Applications Suite
; LicenseFile=..\license.txt
OutputDir=.\
OutputBaseFilename=LazEdit1.9_install
Compression=lzma
SolidCompression=yes
VersionInfoVersion=1.9
AllowNoIcons=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\lazedit.exe"; DestDir: "{app}"; Flags: ignoreversion
; Source: "..\Images\*.png"; DestDir: "{app}\Images"; Flags: ignoreversion
; Source: "..\libraries\pas_overlays\pas_overlays.dll"; DestDir: "{app}"; Flags: ignoreversion
; Source: "..\libraries\videocard_checker\videocard_checker.dll"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Registry]
Root: HKCR; Subkey: "*\shell\LazEdit"; Flags: uninsdeletekeyifempty
Root: HKCR; Subkey: "*\shell\LazEdit"; ValueType: string; ValueName: ""; ValueData: "Open with LazEdit"; Flags: uninsdeletekey
Root: HKCR; Subkey: "*\shell\LazEdit\command"; ValueType: string; ValueName: ""; ValueData: """{app}\lazedit.exe"" ""%1"""; Flags: uninsdeletekey

[Icons]
Name: "{group}\LazEdit"; Filename: "{app}\lazedit.exe"
Name: "{group}\{cm:ProgramOnTheWeb,LazEdit}"; Filename: "http://wiki.lazarus.freepascal.org/LazEdit"
Name: "{group}\{cm:UninstallProgram,LazEdit}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\LazEdit"; Filename: "{app}\lazedit.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\lazedit.exe"; Description: "{cm:LaunchProgram,LazEdit}"; Flags: nowait postinstall skipifsilent



