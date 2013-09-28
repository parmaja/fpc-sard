unit sardObjects;
{**
 *  This file is part of the "SARD"
 *
 * @license   Apache License Version 2.0
 *            included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$mode objfpc}
{$ENDIF}
{$H+}{$M+}
{$INTERFACES CORBA}

(*

  o1: {
    o2: {
    }
    fn1;
    fn2;
  }

 o1;
 fn1;
 fn2;
 o1.o2;

 o3 := 10+5;
*)

{
TODO:
create variable manually in the example to test return value in formual
10+x
soVariable find it is value in the stack and use it in formual

soVariable create a runtime variable in the stack
x := 10;
}

{
  Prefix guid
  srd global classes inherited from sard
  run Runtime classes
  so Sard objects, that created when compile the source
  op Operators objects
}
interface

uses
  Classes, SysUtils, sardClasses;

type

  TsrdObjectType = (otUnkown, otInteger, otFloat, otBoolean, otString, otBlock, otObject, otClass, otVariable);
  TsrdCompare = (cmpLess, cmpEqual, cmpGreater);

  TsrdDebug = class(TsardObject)
  public
    Line: Integer;
    Column: Integer;
    FileName: string;
    BreakPoint: Boolean; //not sure do not laugh
  end;

  TsoObject = class;
  TsoObjectClass = class of TsoObject;

  TopOperator = class;
  TrunResult = class;
  TrunStack = class;
  TrunVariables = class;

  { TsrdStatementItem }

  TsrdStatementItem = class(TsardObject)
  public
    AnOperator: TopOperator;
    AnObject: TsoObject;
    function Execute(vStack: TrunStack): Boolean;
  end;

  { TsrdStatement }

  TsrdStatement = class(TsardObjectList)
  private
    FDebug: TsrdDebug;
    function GetItem(Index: Integer): TsrdStatementItem;
    procedure SetDebug(AValue: TsrdDebug);
  public
    function Add(AObject: TsrdStatementItem): Integer;
    function Add(AOperator:TopOperator; AObject: TsoObject): TsrdStatementItem;
    function Execute(vStack: TrunStack): Boolean;
    property Items[Index: Integer]: TsrdStatementItem read GetItem; default;
    property Debug: TsrdDebug read FDebug write SetDebug; //<-- Nil until we compile it with Debug Info
  end;

  { TsrdBlock }

  TsrdBlock = class(TsardObjectList)
  private
    function GetStatement: TsrdStatement;
    function GetItem(Index: Integer): TsrdStatement;
  protected
  public
    function Add(AStatement: TsrdStatement): Integer;
    function Add: TsrdStatement;
    procedure Check; //Check if empty then create first statement
    property Items[Index: Integer]: TsrdStatement read GetItem; default;
    property Statement: TsrdStatement read GetStatement;
    function Execute(vStack: TrunStack): Boolean;
  end;

  { TsrdBlockStack }

  TsrdBlockStack = class(TsardStack)
  private
    function GetCurrent: TsrdBlock;
  public
    procedure Push(vItem: TsrdBlock);
    property Current: TsrdBlock read GetCurrent;
  end;

  IsrdObject = interface['{9FD9AEE0-507E-4EEA-88A8-AE686E6A1D98}']
  end;

  IsrdOperate = interface['{4B036431-57FA-4E6D-925C-51BC1B67331A}']
    function Add(var vResult: TrunResult): Boolean;
    function Sub(var vResult: TrunResult): Boolean;
    function Mulpiply(var vResult: TrunResult): Boolean;
    function Divide(var vResult: TrunResult): Boolean;
  end;

  IsrdCompare = interface['{4B036431-57FA-4E6D-925C-51BC1B67331A}']
    function Compare(var vResult: TrunResult): TsrdCompare;
  end;

  IsrdBlock = interface['{CB4C0FA1-E233-431E-8CC2-3755F62D93F2}']
    function Execute(vStack: TrunStack; AOperator: TopOperator): Boolean;
  end;

  { TsoObject }

  TsoObject = class(TsardObject, IsrdObject)
  private
  protected
    FObjectType: TsrdObjectType;
  public
    constructor Create; virtual;
    function This: TsoObject; //return the same object, stupid but save some code :P
    function Execute(vStack: TrunStack; AOperator: TopOperator): Boolean; virtual; abstract;
    procedure Assign(FromObject: TsoObject); virtual;
    function Clone(WithValue: Boolean = True): TsoObject; virtual;
    property ObjectType: TsrdObjectType read FObjectType;
    function AsString: String;
    function AsFloat: Float;
    function AsInteger: int;
    function AsBoolean: Boolean;
    function ToBoolean(out outValue: Boolean): Boolean; virtual;
    function ToString(out outValue: string): Boolean; virtual; reintroduce;
    function ToFloat(out outValue: Float): Boolean; virtual;
    function ToInteger(out outValue: int): Boolean; virtual;
  end;

  { TsoObjects }

  TsrdObjects = class(TsardObjectList)
  private
    function GetItem(Index: Integer): TsoObject;
  public
    property Items[Index: Integer]: TsoObject read GetItem; default;
  end;

  {-------- Objects --------}

  { TsoConstObject }

  TsoConstObject = class(TsoObject)
  protected
    function DoExecute(vStack: TrunStack; AOperator: TopOperator): Boolean; virtual; abstract;
  public
    function Execute(vStack: TrunStack; AOperator: TopOperator): Boolean; override; final;
  end;

  { TsoBlock }

  TsoBlock = class(TsoObject, IsrdBlock)
  protected
    FItems: TsrdBlock;
    procedure Created; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Execute(vStack: TrunStack; AOperator: TopOperator): Boolean; override; final;
    property Items: TsrdBlock read FItems;
  end;

  { TsrdClass }

  TsoClass = class(TsoObject)
  public
    procedure Created; override;
  end;

  { TsrdInstance }

  TsoInstance = class(TsoObject)
  public
    Value: TsoObject;
    procedure Created; override;
  end;

  { TsoVariable }

  TsoVariable = class(TsoObject)
  private
    FName: string;
    procedure SetName(AValue: string);
  public
    procedure Created; override;
    function Execute(vStack: TrunStack; AOperator: TopOperator): Boolean; override;
    property Name: string read FName write SetName;
  end;

  TsoBranch = class(TsoBlock) //Todo rename tp scope
  public
  end;

  TsoMain = class(TsoBranch)
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  { TsoScope }

{  TsoScope = class(TsoObject, IsrdBlock)
  protected
    FItems: TsrdScope;
    procedure Created; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Execute(vStack: TrunStack): Boolean; override;
    property Items: TsrdScope read FItems;
  end;}

{-------- Const Objects --------}

  { TsrdNone }

  TsoNone = class(TsoConstObject) //None it is not Null, it is an initial value we sart it
  public
    //Do operator
    //Convert to 0 or ''
  end;

  { TsrdNumber }

  TsoNumber = class(TsoConstObject) //abstract
  public
    //Assign
    //Do operator
  end;

  { TsrdInteger }

  { TsoInteger }

  TsoInteger = class(TsoNumber)
  protected
    procedure Created; override;
  public
    Value: int;
    constructor Create(AValue: int); overload;
    procedure Assign(FromObject: TsoObject); override;
    function DoExecute(vStack: TrunStack; AOperator: TopOperator): Boolean; override;
    function ToString(out outValue: string): Boolean; override;
    function ToFloat(out outValue: Float): Boolean; override;
    function ToInteger(out outValue: int): Boolean; override;
    function ToBoolean(out outValue: Boolean): Boolean; override;
  end;

  { TsrdFloat }

  TsoFloat = class(TsoNumber)
  public
    Value: Float;
    procedure Created; override;
    function ToString(out outValue: string): Boolean; override;
    function ToFloat(out outValue: Float): Boolean; override;
    function ToInteger(out outValue: int): Boolean; override;
    function ToBoolean(out outValue: Boolean): Boolean; override;
  end;

  { TsrdBoolean }

  TsoBoolean = class(TsoNumber)
  public
    Value: Boolean;
    procedure Created; override;
    function ToString(out outValue: string): Boolean; override;
    function ToFloat(out outValue: Float): Boolean; override;
    function ToInteger(out outValue: int): Boolean; override;
    function ToBoolean(out outValue: Boolean): Boolean; override;
  end;

  { TsrdString }

  TsoString = class(TsoConstObject)
  public
    Value: string;
    procedure Created; override;
    function ToString(out outValue: string): Boolean; override;
    function ToFloat(out outValue: Float): Boolean; override;
    function ToInteger(out outValue: int): Boolean; override;
    function ToBoolean(out outValue: Boolean): Boolean; override;
  end;

{-------- Operators --------}

  { TopOperator }

  TopOperator = class(TsardObject)
  protected
    function DoExecute(vStack: TrunStack; vObject: TsoObject): Boolean; virtual;
  public
    Code: string;
    Name: string;
    Level: Integer;
    Description: string;
    function Execute(vStack: TrunStack; vObject: TsoObject): Boolean;
    constructor Create; virtual;
  end;

  TopOperatorClass = class of TopOperator;
  { TopOperators }

  TopOperators = class(TsardObjectList)
  private
    function GetItem(Index: Integer): TopOperator;
  protected
    function CheckBeforeRegister(AOperator: TopOperator): Boolean; virtual;
  public
    function Find(const Code: string): TopOperator;
    function FindByName(const vName: string): TopOperator;
    function RegisterOperator(AOperator: TopOperator): Boolean;
    function RegisterOperator(AOperatorClass: TopOperatorClass): Boolean;
    property Items[Index: Integer]: TopOperator read GetItem; default;
  end;

  { TopAssign }

  TopAssign = class(TopOperator)//Naaaaaaaaaah
  public
    constructor Create; override;
  end;

  { TopPlus }

  TopPlus = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopMinus }

  TopMinus = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopMultiply }

  TopMultiply = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopDivide }

  TopDivide = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopPower }

  TopPower = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopLesser }

  TopLesser = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopGreater }

  TopGreater = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopEqual }

  TopEqual = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopNotEqual }

  TopNot = class(TopOperator)
  public
    constructor Create; override;
  end;

  TopNotEqual = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopAnd }

  TopAnd = class(TopOperator)
  public
    constructor Create; override;
  end;

  { TopOr }

  TopOr = class(TopOperator)
  public
    constructor Create; override;
  end;

{-------- Run Time Engine --------}

  { TrunVariable }

    TrunVariable = class(TsardObject)
    private
      FName: string;
      procedure SetName(AValue: string);
    public
      Value: TrunResult;
      property Name: string read FName write SetName;
    end;

    { TsardVariables }

    { TrunVariables }

    TrunVariables = class(TsardObjectList)
    private
      function GetItem(Index: Integer): TrunVariable;
    public
      property Items[Index: Integer]: TrunVariable read GetItem; default;
      function Find(vName: string): TrunVariable;
      function Register(vName: string): TrunVariable;
      function SetValue(vName: string; vValue: TsoObject): TrunVariable;
    end;

    { TrunResult }

    TrunResult = class(TsardObject)
    private
      FAnObject: TsoObject;
      procedure SetAnObject(AValue: TsoObject);
    public
      destructor Destroy; override;
      property AnObject: TsoObject read FAnObject write SetAnObject;
    end;

    { TsrdScope }

    TsrdScope = class(TsardObject)
    private
      FVariables: TrunVariables;
    public
      constructor Create;
      destructor Destroy; override;
      property Variables: TrunVariables read FVariables;
    end;

    { TrunStackItem }

    TrunStackItem = class(TsardObject)
    private
      FResult: TrunResult;
      FScope: TsrdScope;
    public
      constructor Create;
      destructor Destroy; override;
      property Result: TrunResult read FResult;
      property Scope: TsrdScope read FScope;
    end;

    { TrunStack }

    TrunStack = class(TsardStack)
    private
      function GetCurrent: TrunStackItem;
    public
      procedure Push(vObject: TrunStackItem);
      function Push: TrunStackItem; overload;
      function Pull: TrunStackItem;
      property Current: TrunStackItem read GetCurrent;
    end;

  { TsrdEngine }

  TsrdEngine = class(TsardCustomEngine)
  protected
    FOperators: TopOperators;
    procedure Created; override;
    function CreateOperators: TopOperators;
  public
    constructor Create;
    function IsWhiteSpace(vChar: AnsiChar; vOpen: Boolean = True): Boolean; override;
    function IsControl(vChar: AnsiChar; vOpen: Boolean = True): Boolean; override;
    function IsOperator(vChar: AnsiChar; vOpen: Boolean = True): Boolean; override;
    function IsNumber(vChar: AnsiChar; vOpen: Boolean = True): Boolean; override;
    function IsIdentifier(vChar: AnsiChar; vOpen: Boolean = True): Boolean; override;

    property Operators: TopOperators read FOperators;
  end;

function sardEngine: TsrdEngine;

implementation

uses
  sardScripts;

var
  FsardEngine: TsrdEngine = nil;

function sardEngine: TsrdEngine;
begin
  if FsardEngine = nil then
    FsardEngine := TsrdEngine.Create;
  Result := FsardEngine;
end;

{ TrunResult }

procedure TrunResult.SetAnObject(AValue: TsoObject);
begin
  if FAnObject <> AValue then
  begin
    if FAnObject <> nil then
      FreeAndNil(FAnObject);
    FAnObject :=AValue;
  end;
end;

destructor TrunResult.Destroy;
begin
  FreeAndNil(FAnObject);
  inherited Destroy;
end;

{ TsrdScope }

constructor TsrdScope.Create;
begin
  inherited Create;
  FVariables := TrunVariables.Create;
end;

destructor TsrdScope.Destroy;
begin
  FreeAndNil(FVariables);
  inherited Destroy;
end;

{ TsoConstObject }

function TsoConstObject.Execute(vStack: TrunStack; AOperator: TopOperator): Boolean;
begin
   if vStack.Current.Result.AnObject = nil then
  begin
    vStack.Current.Result.AnObject := Clone;
    Result := True;
  end
  else
    Result := DoExecute(vStack, AOperator);

  WriteLn('Execute: ' + ClassName+ ' Level=' + IntToStr(vStack.CurrentItem.Level));
  if AOperator <> nil then
    Write('{'+ AOperator.ClassName+'}');
end;

{ TrunStackItem }

constructor TrunStackItem.Create;
begin
  inherited;
  FResult := TrunResult.Create;
  FScope := TsrdScope.Create;
end;

destructor TrunStackItem.Destroy;
begin
  FreeAndNil(FResult);
  FreeAndNil(FScope);
  inherited Destroy;
end;

{ TrunStack }

function TrunStack.GetCurrent: TrunStackItem;
begin
  Result := (inherited GetCurrent) as TrunStackItem;
end;

procedure TrunStack.Push(vObject: TrunStackItem);
begin
  inherited Push(vObject);
end;

function TrunStack.Push: TrunStackItem;
begin
  Result := TrunStackItem.Create;
  Push(Result);
end;

function TrunStack.Pull: TrunStackItem;
begin
  Result := (inherited Pull) as TrunStackItem;
end;

{ TsoBlock }

procedure TsoBlock.Created;
begin
  inherited Created;
  FObjectType := otBlock;
end;

function TsoBlock.Execute(vStack: TrunStack; AOperator: TopOperator): Boolean;
var
  T: TrunStackItem;
begin
  Result := False;
  T := vStack.Push;
  try
    Result := Items.Execute(vStack);
  finally
    vStack.Pull;
  end;
  if T.Result.AnObject <> nil then
    T.Result.AnObject.Execute(vStack, AOperator);
  FreeAndNil(T);
  WriteLn('Execute: ' + ClassName+ ' Level=' + IntToStr(vStack.CurrentItem.Level));
  if AOperator <> nil then
    Write('{'+ AOperator.ClassName+'}');
end;

constructor TsoBlock.Create;
begin
  inherited Create;
  FItems := TsrdBlock.Create;
end;

destructor TsoBlock.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

{ TsardVariables }

function TrunVariables.GetItem(Index: Integer): TrunVariable;
begin
  Result := inherited Items[Index] as TrunVariable;
end;

function TrunVariables.Find(vName: string): TrunVariable;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(vName, Items[i].Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TrunVariables.Register(vName: string): TrunVariable;
begin
  Result := Find(vName);
  if Result <> nil then
  begin
    Result := TrunVariable.Create;
    Result.Name := vName;
    Add(Result);
  end;
end;

function TrunVariables.SetValue(vName: string; vValue: TsoObject): TrunVariable;
begin
  Result := Find(vName);
  if Result <> nil then
    Result.Value.AnObject := vValue;
end;

{ TrunVariable }

procedure TrunVariable.SetName(AValue: string);
begin
  if FName =AValue then Exit;
  FName :=AValue;
end;

{ TopAssign }

constructor TopAssign.Create;
begin
  inherited Create;
  Code := ':=';
  Name := 'Assign';
  Level := 10;
  Description := 'Clone to another object';
end;

{ TsrdBlockStack }

function TsrdBlockStack.GetCurrent: TsrdBlock;
begin
  Result := (inherited GetCurrent) as TsrdBlock;
end;

procedure TsrdBlockStack.Push(vItem: TsrdBlock);
begin
  inherited Push(vItem);
end;

{ TopNot }

constructor TopNot.Create;
begin
  inherited Create;
  Code := '!'; //or '~'
  Name := 'Not';
  Level := 100;
end;

{ TopOr }

constructor TopOr.Create;
begin
  inherited Create;
  Code := '|';
  Name := 'Or';
  Level := 51;
end;

{ TopAnd }

constructor TopAnd.Create;
begin
  inherited Create;
  Code := '&';
  Name := 'And';
  Level := 51;
end;

{ TopNotEqual }

constructor TopNotEqual.Create;
begin
  inherited Create;
  Code := '<>';
  Name := 'NotEqual';
  Level := 51;
end;

{ TopEqual }

constructor TopEqual.Create;
begin
  inherited Create;
  Code := '=';
  Name := 'Equal';
  Level := 51;
end;

{ TopGreater }

constructor TopGreater.Create;
begin
  inherited Create;
  Code := '>';
  Name := 'Greater';
  Level := 51;
end;

{ TopLesser }

constructor TopLesser.Create;
begin
  inherited Create;
  Code := '<';
  Name := 'Lesser';
  Level := 51;
end;

{ TopPower }

constructor TopPower.Create;
begin
  inherited Create;
  Code := '^';
  Name := 'Power';
  Level := 52;
end;

procedure TsoVariable.SetName(AValue: string);
begin
  FName := AValue;
end;

procedure TsoVariable.Created;
begin
  inherited Created;
  FObjectType := otVariable;
end;

function TsoVariable.Execute(vStack: TrunStack; AOperator: TopOperator): Boolean;
var
  v: TrunVariable;
begin
  v := vStack.Current.Scope.Variables.Register(Name);
  if v <> nil then
  begin
    if v.Value.AnObject <> nil then
      v.Value.AnObject.Execute(vStack, AOperator);
  end;
end;

{
procedure TsoScope.Created;
begin
  inherited Created;
  FObjectType := otBlock;
end;

constructor TsoScope.Create;
begin
  inherited Create;
  FItems := TsrdScope.Create(nil);
end;

destructor TsoScope.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TsoScope.Execute(vStack: TrunStack): Boolean;
begin
  //Just Forward
  Result := Items.Execute(vStack);
end;
}

{ TopDivide }

constructor TopDivide.Create;
begin
  inherited Create;
  Code := '/';
  Name := 'Divition';
  Level := 51;
end;

{ TopMultiply }

constructor TopMultiply.Create;
begin
  inherited Create;
  Code := '*';
  Name := 'Multiply';
  Level := 51;
end;

{ TopMinus }

constructor TopMinus.Create;
begin
  inherited Create;
  Code := '-';
  Name := 'Minus';
  Level := 50;
  Description := 'Sub object to another object';
end;

{ TopOperator }

function TopOperator.DoExecute(vStack: TrunStack; vObject: TsoObject): Boolean;
begin
  Result := False;
end;

function TopOperator.Execute(vStack: TrunStack; vObject: TsoObject): Boolean;
begin
  Result := False;
end;

(*
function TopOperator.Execute(vStack: TrunStack; vObject: TsoObject): Boolean;
var
  aResult: TrunResult;
  procedure ExecuteNow(O: TsoObject);
  begin
    {
      if previous object is null and there is a operator we considr that privouse object is empty one like 0 or ''
      it is good to say  -10
    }

    if Self = nil then //TODO: If assign
    //if vStack.Current.Result.AnObject = nil then
      vStack.Current.Result.AnObject := O.Clone
    else
    begin
      if vStack.Current.Result.AnObject = nil then
        vStack.Current.Result.AnObject := O.Clone(False);
      Result := DoExecute(vStack, O);
    end;
  end;
begin
  aResult := TrunResult.Create;
  try
    if not vObject.Execute(vStack, Self) then //it is a block
    begin
      if aResult.AnObject <> nil then
        ExecuteNow(aResult.AnObject)
    end
    else//<-- maybe not !!!
      ExecuteNow(vObject);
  finally
    aResult.Free;
  end;
end;
*)

constructor TopOperator.Create;
begin
  inherited Create;
end;

function TopOperators.Find(const Code: string): TopOperator;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if Code = Items[i].Code then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TopOperators.FindByName(const vName: string): TopOperator;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if vName = Items[i].Name then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TopOperators.RegisterOperator(AOperator: TopOperator): Boolean;
begin
  Result := CheckBeforeRegister(AOperator);
  if Result then
    Add(AOperator);
end;

function TopOperators.RegisterOperator(AOperatorClass: TopOperatorClass): Boolean;
begin
  Result := RegisterOperator(AOperatorClass.Create);
end;

{ TopPlus }

constructor TopPlus.Create;
begin
  inherited Create;
  Code := '+';
  Name := 'Plus';
  Level := 50;
  Description := 'Add object to another object';
end;

{ TopOperators }

function TopOperators.GetItem(Index: Integer): TopOperator;
begin
  Result := inherited Items[Index] as TopOperator;
end;

function TopOperators.CheckBeforeRegister(AOperator: TopOperator): Boolean;
begin
  Result := True;
end;

{ TsrdEngine }

procedure TsrdEngine.Created;
begin
  inherited;
  with Operators do
  begin
    Operators.RegisterOperator(TopPlus);
    Operators.RegisterOperator(TopMinus);
    Operators.RegisterOperator(TopMultiply);
    Operators.RegisterOperator(TopDivide);

    Operators.RegisterOperator(TopEqual);
    Operators.RegisterOperator(TopNotEqual);
    Operators.RegisterOperator(TopAnd);
    Operators.RegisterOperator(TopOr);
    Operators.RegisterOperator(TopNot);

    Operators.RegisterOperator(TopGreater);
    Operators.RegisterOperator(TopLesser);

    Operators.RegisterOperator(TopPower);
  end;
end;

function TsrdEngine.CreateOperators: TopOperators;
begin
  Result := TopOperators.Create;
end;

constructor TsrdEngine.Create;
begin
  inherited Create;
  FOperators := CreateOperators;
end;

function TsrdEngine.IsWhiteSpace(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  Result := vChar in sWhitespace;
end;

function TsrdEngine.IsControl(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  if vOpen then
    Result := vChar in aControlsOpenChars
  else
    Result := vChar in sControlsChars;
end;

function TsrdEngine.IsOperator(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  //if vOpen then
    Result := vChar in sOperatorOpenChars
//  else
//    Result := not IsWhiteSpace(vChar, False) and not IsNumber(vChar, False) and not IsControl(vChar, False); //Can be any thing except those
end;

function TsrdEngine.IsNumber(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  if vOpen then
    Result := vChar in sNumberOpenChars
  else
    Result := vChar in sNumberChars;
end;

function TsrdEngine.IsIdentifier(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  Result := inherited IsIdentifier(vChar, vOpen);
end;


{ TsrdStatementItem }

function TsrdStatementItem.Execute(vStack: TrunStack): Boolean;
begin
  if AnObject = nil then
    raise EsardException.Create('Object not set!');
  {if AnOperator = nil then
    raise EsardException.Create('Object not set!');}
//  Result := AnOperator.Execute(vStack, AnObject);//Even AnOperator is nil it will work
  Result := AnObject.Execute(vStack, AnOperator);
end;

{ TsrdClass }

procedure TsoClass.Created;
begin
  inherited Created;
  FObjectType := otClass;
end;

{ TsrdInstance }

procedure TsoInstance.Created;
begin
  inherited Created;
  FObjectType := otObject;
end;

{ TsrdBoolean }

procedure TsoBoolean.Created;
begin
  inherited Created;
  FObjectType := otBoolean;
end;

function TsoBoolean.ToString(out outValue: string): Boolean;
begin
  Result :=inherited ToString(outValue);
end;

function TsoBoolean.ToFloat(out outValue: Float): Boolean;
begin
  Result :=inherited ToFloat(outValue);
end;

function TsoBoolean.ToInteger(out outValue: int): Boolean;
begin
  Result :=inherited ToInteger(outValue);
end;

function TsoBoolean.ToBoolean(out outValue: Boolean): Boolean;
begin
  outValue := Value;
  Result := True;
end;

{ TsrdString }

procedure TsoString.Created;
begin
  inherited Created;
  FObjectType := otString;
end;

function TsoString.ToString(out outValue: string): Boolean;
begin
  Result :=inherited ToString(outValue);
end;

function TsoString.ToFloat(out outValue: Float): Boolean;
begin
  Result :=inherited ToFloat(outValue);
end;

function TsoString.ToInteger(out outValue: int): Boolean;
begin
  Result :=inherited ToInteger(outValue);
end;

function TsoString.ToBoolean(out outValue: Boolean): Boolean;
begin
  if not TryStrToBool(Value, outValue) then
    outValue := AsInteger <> 0;
  Result := True;
end;

{ TsrdFloat }

procedure TsoFloat.Created;
begin
  inherited Created;
  FObjectType := otFloat;
end;

function TsoFloat.ToString(out outValue: string): Boolean;
begin
  Result :=inherited ToString(outValue);
end;

function TsoFloat.ToFloat(out outValue: Float): Boolean;
begin
  Result :=inherited ToFloat(outValue);
end;

function TsoFloat.ToInteger(out outValue: int): Boolean;
begin
  Result :=inherited ToInteger(outValue);
end;

function TsoFloat.ToBoolean(out outValue: Boolean): Boolean;
begin
  outValue := Value <> 0;
  Result := True;
end;

{ TsrdInteger }

procedure TsoInteger.Created;
begin
  inherited Created;
  FObjectType := otInteger;
end;

constructor TsoInteger.Create(AValue: int);
begin
  inherited Create;
  Value := AValue;
end;

procedure TsoInteger.Assign(FromObject: TsoObject);
begin
  if FromObject <> nil then
  begin
    if FromObject is TsoInteger then
      Value := (FromObject as TsoInteger).Value
    else
      Value := FromObject.AsInteger;
  end;
end;

function TsoInteger.DoExecute(vStack: TrunStack; AOperator: TopOperator): Boolean;
begin
  if vStack.Current.Result.AnObject is TsoInteger then
  begin
    Result := True;
    WriteLn(IntToStr(TsoInteger(vStack.Current.Result.AnObject).Value) + ' '+ AOperator.Code+' ' +IntToStr(Value));
    case AOperator.Code of
      '+': TsoInteger(vStack.Current.Result.AnObject).Value := TsoInteger(vStack.Current.Result.AnObject).Value + Value;
      '-': TsoInteger(vStack.Current.Result.AnObject).Value := TsoInteger(vStack.Current.Result.AnObject).Value - Value;
      '*': TsoInteger(vStack.Current.Result.AnObject).Value := TsoInteger(vStack.Current.Result.AnObject).Value * Value;
      '/': TsoInteger(vStack.Current.Result.AnObject).Value := TsoInteger(vStack.Current.Result.AnObject).Value div Value;
      else
        Result := False;
    end;
  end;
end;

function TsoInteger.ToString(out outValue: string): Boolean;
begin
  Result := True;
  outValue := IntToStr(Value);
end;

function TsoInteger.ToFloat(out outValue: Float): Boolean;
begin
  Result := True;
  outValue := Value;
end;

function TsoInteger.ToInteger(out outValue: int): Boolean;
begin
  Result := True;
  outValue := Value;
end;

function TsoInteger.ToBoolean(out outValue: Boolean): Boolean;
begin
  outValue := Value <> 0;
  Result := True;
end;

{ TsoBlock }

function TsrdBlock.GetStatement: TsrdStatement;
begin
  Check;//TODO: not sure
  Result := Last as TsrdStatement;
end;

function TsrdBlock.GetItem(Index: Integer): TsrdStatement;
begin
  Result := inherited Items[Index] as TsrdStatement;
end;

function TsrdBlock.Add(AStatement: TsrdStatement): Integer;
begin
  Result := inherited Add(AStatement);
end;

function TsrdBlock.Add: TsrdStatement;
begin
  Result := TsrdStatement.Create;
  Add(Result);
end;

procedure TsrdBlock.Check;
begin
  if Count = 0  then
    Add;
end;

function TsrdBlock.Execute(vStack: TrunStack): Boolean;
var
  i: Integer;
begin
  Result := Count > 0;
  for i := 0 to Count -1 do
  begin
    Result := Items[i].Execute(vStack) and Result;
  end;
end;

{ TsrdStatement }

function TsrdStatement.GetItem(Index: Integer): TsrdStatementItem;
begin
  Result := inherited Items[Index] as TsrdStatementItem;
end;

procedure TsrdStatement.SetDebug(AValue: TsrdDebug);
begin
  if FDebug =AValue then Exit;
  FDebug :=AValue;
end;

function TsrdStatement.Add(AObject: TsrdStatementItem): Integer;
begin
  Result := inherited Add(AObject);
end;

function TsrdStatement.Add(AOperator: TopOperator; AObject: TsoObject): TsrdStatementItem;
begin
  Result := TsrdStatementItem.Create;
  Result.AnOperator := AOperator;
  Result.AnObject := AObject;
  Add(Result);
end;

function TsrdStatement.Execute(vStack: TrunStack): Boolean;
var
  i: Integer;
begin
  Result := Count > 0;
  for i := 0 to Count -1 do
  begin
    Result := Items[i].Execute(vStack) and Result;
  end;
end;

{ TsoRun }

constructor TsoMain.Create;
begin
  inherited Create;
end;

destructor TsoMain.Destroy;
begin
  inherited Destroy;
end;

{ TsrdObjects }

function TsrdObjects.GetItem(Index: Integer): TsoObject;
begin
  Result := inherited Items[Index] as TsoObject;
end;

{ TsoObject }

constructor TsoObject.Create;
begin
  inherited Create;
end;

function TsoObject.This: TsoObject;
begin
  Result := Self;
end;

procedure TsoObject.Assign(FromObject: TsoObject);
begin
  //Nothing to do
end;

function TsoObject.Clone(WithValue: Boolean): TsoObject;
begin
  Result := TsoObjectClass(ClassType).Create;
  if WithValue then
    Result.Assign(Self);
end;

function TsoObject.AsString: String;
var
  o: string;
begin
  if ToString(o) then
    Result := o
  else
    Result := '';
end;

function TsoObject.AsFloat: Float;
var
  o: Float;
begin
  if ToFloat(o) then
    Result := o
  else
    Result := 0;
end;

function TsoObject.AsInteger: int;
var
  o: int;
begin
  if ToInteger(o) then
    Result := o
  else
    Result := 0;
end;

function TsoObject.AsBoolean: Boolean;
var
  o: Boolean;
begin
  if ToBoolean(o) then
    Result := o
  else
    Result := False;
end;

function TsoObject.ToBoolean(out outValue: Boolean): Boolean;
begin
  Result := False;
end;

function TsoObject.ToString(out outValue: string): Boolean;
begin
  Result := False;
end;

function TsoObject.ToFloat(out outValue: Float): Boolean;
begin
  Result := False;
end;

function TsoObject.ToInteger(out outValue: int): Boolean;
begin
  Result := False;
end;

end.
