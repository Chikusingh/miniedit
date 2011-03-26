unit mneSetups;
{$mode delphi}
{**
 * Mini Edit
 * 
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  mneClasses, Dialogs, StdCtrls, IniFiles;

type
  TEditorSetupForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    OkBtn: TButton;
    CancelBtn: TButton;
    WorkspaceEdit: TComboBox;
    procedure Button1Click(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.lfm}

uses
  EditorEngine;

procedure TEditorSetupForm.Button1Click(Sender: TObject);
var
  aFolder: string;
begin
  aFolder := WorkspaceEdit.Text;
  if SelectFolder('Select root directory for you project', '', aFolder) then
  begin
    WorkspaceEdit.Text := aFolder;
  end;
end;

procedure TEditorSetupForm.OkBtnClick(Sender: TObject);
var
  aIniFile:TIniFile;
begin
  if WorkspaceEdit.Text = '' then
  begin
    Application.MessageBox('You must enter valid folder', 'Work space folder', 0);
    WorkspaceEdit.SetFocus;
    Abort;
  end
  else
  begin
    ForceDirectories(WorkspaceEdit.Text);
    aIniFile:=TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
    try
      aIniFile.WriteString('Options', 'Workspace', IncludeTrailingPathDelimiter(WorkspaceEdit.Text));
    finally
      aIniFile.Free;
    end;
  end;
  ModalResult := mrOK;
end;

procedure TEditorSetupForm.FormCreate(Sender: TObject);
var
  aIniFile:TIniFile;
begin
  WorkspaceEdit.Items.Add(ExtractFilePath(Application.ExeName));
  WorkspaceEdit.Items.Add('C:\workspace');
  WorkspaceEdit.Items.Add('D:\workspace');
  aIniFile:=TIniFile.Create(ExtractFilePath(Application.ExeName) + 'setting.ini');
  try
     WorkspaceEdit.Text := aIniFile.ReadString('Options', 'Workspace', '');
  finally
    aIniFile.Free;
  end;
end;

end.

