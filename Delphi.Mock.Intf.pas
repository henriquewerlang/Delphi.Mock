﻿unit Delphi.Mock.Intf;

interface

uses System.SysUtils, System.Rtti, Delphi.Mock.VirtualInterface, Delphi.Mock.Method;

type
  IMockSetupWhen<T: IInterface> = interface
    ['{1EE67E5A-C054-4771-842F-3FBCD39BB90B}']
    function When: T;
  end;

  IMockSetup<T: IInterface> = interface
    ['{778531BB-4093-4103-B4BC-72845B78387B}']
    function WillExecute(Proc: TProc): IMockSetupWhen<T>;
    function WillReturn(const Value: TValue): IMockSetupWhen<T>;
  end;

  IMockExpectSetup<T: IInterface> = interface
    ['{3E5A7304-B683-474B-A799-B5BDE281AC22}']
    function CustomExpect(Func: TFunc<TArray<TValue>, String>): IMockSetupWhen<T>;
    function Once: IMockSetupWhen<T>;
  end;

  IMock<T: IInterface> = interface
    ['{C249D074-74A0-4AB9-BA7D-102CA4811019}']
    function CheckExpectations: String;
    function Expect: IMockExpectSetup<T>;
    function Instance: T;
    function Setup: IMockSetup<T>;
  end;

  TMockSetupWhenIntf<T: IInterface> = class(TVirtualInterfaceEx, IMockSetupWhen<T>)
  private
    FMethodRegister: IMethodRegister;

    function When: T;

    procedure OnInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create(MethodRegister: IMethodRegister);
  end;

  TMockSetupIntf<T: IInterface> = class(TVirtualInterfaceEx, IMockSetup<T>, IMockExpectSetup<T>)
  private
    FMockSetupWhen: IMockSetupWhen<T>;
    FMethodRegister: IMethodRegister;

    function CheckExpectations: String;
    function CustomExpect(Func: TFunc<TArray<TValue>, String>): IMockSetupWhen<T>;
    function Once: IMockSetupWhen<T>;
    function WillExecute(Proc: TProc): IMockSetupWhen<T>;
    function WillReturn(const Value: TValue): IMockSetupWhen<T>;

    procedure OnInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create;
  end;

  TMockIntf<T: IInterface> = class(TInterfacedObject, IMock<T>)
  private
    FMockSetup: TMockSetupIntf<T>;

    function CheckExpectations: String;
    function Expect: IMockExpectSetup<T>;
    function Instance: T;
    function Setup: IMockSetup<T>;
  public
    constructor Create;
  end;

implementation

uses System.TypInfo;

{ TMockIntf<T> }

function TMockIntf<T>.CheckExpectations: String;
begin
  Result := FMockSetup.CheckExpectations;
end;

constructor TMockIntf<T>.Create;
begin
  inherited;

  FMockSetup := TMockSetupIntf<T>.Create;
end;

function TMockIntf<T>.Expect: IMockExpectSetup<T>;
begin
  Result := FMockSetup;
end;

function TMockIntf<T>.Instance: T;
begin
  FMockSetup.QueryInterface(PTypeInfo(TypeInfo(T)).TypeData.GUID, Result);
end;

function TMockIntf<T>.Setup: IMockSetup<T>;
begin
  Result := FMockSetup;
end;

{ TMockSetupIntf<T> }

function TMockSetupIntf<T>.CheckExpectations: String;
begin
  Result := EmptyStr;

  for var Method in FMethodRegister.ExceptMethods do
  begin
    if not Result.IsEmpty then
      Result := Result + #13#10;

    Result := Result + Method.CheckExpectation;
  end;
end;

constructor TMockSetupIntf<T>.Create;
begin
  inherited Create(TypeInfo(T), OnInvoke);

  FMethodRegister := TMethodRegister.Create;
  FMockSetupWhen := TMockSetupWhenIntf<T>.Create(FMethodRegister);
end;

function TMockSetupIntf<T>.CustomExpect(Func: TFunc<TArray<TValue>, String>): IMockSetupWhen<T>;
begin
  Result := FMockSetupWhen;

  FMethodRegister.StartRegister(TMethodInfoCustomExpectation.Create(Func));
end;

function TMockSetupIntf<T>.Once: IMockSetupWhen<T>;
begin
  Result := FMockSetupWhen;

  FMethodRegister.StartRegister(TMethodInfoExpectOnce.Create);
end;

procedure TMockSetupIntf<T>.OnInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
begin
  var AdjustedArgs: TArray<TValue> := Args;

  Delete(AdjustedArgs, 0, 1);

  FMethodRegister.ExecuteMethod(Method, AdjustedArgs, Result);
end;

function TMockSetupIntf<T>.WillExecute(Proc: TProc): IMockSetupWhen<T>;
begin
  Result := FMockSetupWhen;

  FMethodRegister.StartRegister(TMethodInfoWillExecute.Create(Proc));
end;

function TMockSetupIntf<T>.WillReturn(const Value: TValue): IMockSetupWhen<T>;
begin
  Result := FMockSetupWhen;

  FMethodRegister.StartRegister(TMethodInfoWillReturn.Create(Value));
end;

{ TMockSetupWhenIntf<T> }

constructor TMockSetupWhenIntf<T>.Create(MethodRegister: IMethodRegister);
begin
  inherited Create(TypeInfo(T), OnInvoke);

  FMethodRegister := MethodRegister;
end;

procedure TMockSetupWhenIntf<T>.OnInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
begin
  FMethodRegister.RegisterMethod(Method);
end;

function TMockSetupWhenIntf<T>.When: T;
begin
  QueryInterface(PTypeInfo(TypeInfo(T)).TypeData.GUID, Result);
end;

end.

