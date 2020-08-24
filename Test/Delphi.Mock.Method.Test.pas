﻿unit Delphi.Mock.Method.Test;

interface

uses DUnitX.TestFramework, System.Rtti, System.SysUtils, Delphi.Mock.Method;

type
  [TestFixture]
  TMethodRegisterTest = class
  public
    [Test]
    procedure IfDontCallStartRegisterAndTryToRegisterAMethodMustRaiseAException;
    [Test]
    procedure WhenCallStartRegisterCantRaiseAExpcetionWhenCallRegisterMethod;
    [Test]
    procedure AfterCallRegisterMethodMustResetTheControlOfRegistering;
    [Test]
    procedure WhenCallStartRegisterMustSetNilToItGlobalVariable;
    [Test]
    procedure WhenCallExecuteMustCallExecuteFromInterfaceMethod;
    [Test]
    procedure WhenClassExecuteOfAMethodThatIsNotRegisteredMustRaiseAException;
    [Test]
    procedure WhenRegisteringAProcedureWithParametersYouHaveToRecordTheParametersWithTheItFunction;
    [Test]
    procedure WhenTheNumberOfParametersRecordedIsDifferentFromTheAmountOfParametersTheProcedureHasToRaiseAnError;
    [Test]
    procedure WhenCallAProcedureMustFindTheCorrectProcedureByValueOfCallingParameters;
    [Test]
    procedure TheMethodCountMustIncByOneEveryTimeTheProcedureIsCalled;
    [Test]
    procedure TheOneMethodWhenNotExecutedMustReturnMessageInExpectation;
    [Test]
    procedure WhenTheOnceMethodIsCalledMoreThenOneTimeMustRegisterInTheMessageTheQuantityOsCalls;
    [Test]
    procedure WhenTheOnceMethodIsCalledOnlyOneTimeTheExpcetationMustReturnEmptyString;
    [Test]
    procedure ThePropertyExpectMethodsMustReturnOnlyTheMethodThatImplementsTheExpectedInterface;
    [Test]
    procedure WhenAProcedureIsLoggedButNotExecutedByParameterDifferenceHasToGiveAnError;
    [Test]
    procedure IfTheMethodFoundIsAnExpectationCanNotGiveAnException;
    [Test]
    procedure WhenUsingTheCustomExpectationMustReturnTheValeuFromFunctionRegistered;
    [Test]
    procedure WhenExecuteTheCustomExpectationMustPassTheParamsFromCallingProcedure;
    [Test]
    procedure WhenCallAnExceptationMethodMustMarkAsExecuted;
    [Test]
    procedure WhenAExpectationIsRegistredButNotCalledMustReturnError;
    [Test]
    procedure WhenRegisteredAMethodOfExpectationMustReturnTheMessageOfExpectationWhenCalled;
    [Test]
    procedure WhenExistsMoreTheOneExpectationRegisteredMustReturnTheMessageOfAllMethods;
    [Test]
    procedure TheMethodExpectOneMustReturnTrueAlwayWhenCheckingIfWasExecuted;
  end;

  TMyMethod = class(TMethodInfo, IMethod)
  private
    FCalled: Boolean;
    FParams: TArray<TValue>;

    procedure Execute(const Params: TArray<TValue>; out Result: TValue);
  end;

  TMyExpectMethod = class(TMethodInfo, IMethod, IMethodExpect)
  private
    FMessage: String;
    FExceptation: Boolean;

    function CheckExpectation: String;
    function ExceptationExecuted: Boolean;

    procedure Execute(const Params: TArray<TValue>; out Result: TValue);
  public
    constructor Create(ExpectationMessage: String = '');
  end;

  TMyClass = class
  public
    procedure AnyProcedure;
    procedure AnotherProcedure(Param: String; Param2: Integer);
    procedure MyProcedure(Param: String);
  end;

implementation

uses Delphi.Mock;

{ TMethodRegisterTest }

procedure TMethodRegisterTest.AfterCallRegisterMethodMustResetTheControlOfRegistering;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var Result: TValue;

      MethodRegister.StartRegister(TMyMethod.Create);

      MethodRegister.RegisterMethod(Context.GetType(ClassType).GetMethods[0]);

      MethodRegister.RegisterMethod(Context.GetType(ClassType).GetMethods[0]);
    end, EDidNotCallTheStartRegister);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.IfDontCallStartRegisterAndTryToRegisterAMethodMustRaiseAException;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillRaise(
    procedure
    begin
      var Result: TValue;

      MethodRegister.RegisterMethod(nil);
    end, EDidNotCallTheStartRegister);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.IfTheMethodFoundIsAnExpectationCanNotGiveAnException;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('MyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyExpectMethod := TMyExpectMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyExpectMethod);

  It.IsEqualTo('abc');

  MethodRegister.RegisterMethod(Method);

  Assert.WillNotRaise(
    procedure
    var
      Result: TValue;

    begin
      MethodRegister.ExecuteMethod(Method, ['xxx'], Result)
    end);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.TheMethodCountMustIncByOneEveryTimeTheProcedureIsCalled;
begin
  var Method := TMethodInfoCounter.Create;
  var Value := TValue.Empty;

  for var A := 1 to 10 do
    Method.Execute(nil, Value);

  Assert.AreEqual(10, Method.ExecutionCount);

  Method.Free;
end;

procedure TMethodRegisterTest.TheMethodExpectOneMustReturnTrueAlwayWhenCheckingIfWasExecuted;
begin
  var Method := TMethodInfoExpectOnce.Create;

  Assert.IsTrue(Method.ExceptationExecuted);

  Method.Free;
end;

procedure TMethodRegisterTest.TheOneMethodWhenNotExecutedMustReturnMessageInExpectation;
begin
  var Method := TMethodInfoExpectOnce.Create;

  Assert.AreEqual('Expected to call once the method but never called', Method.CheckExpectation);

  Method.Free;
end;

procedure TMethodRegisterTest.ThePropertyExpectMethodsMustReturnOnlyTheMethodThatImplementsTheExpectedInterface;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('AnyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyMethod.Create;
  var MyExpectMethod := TMyExpectMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyExpectMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyExpectMethod);

  MethodRegister.RegisterMethod(Method);

  Assert.AreEqual(2, Length(MethodRegister.ExpectMethods));

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenAExpectationIsRegistredButNotCalledMustReturnError;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('AnyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyExpectMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  Assert.AreEqual('No expectations executed!', MethodRegister.CheckExpectations);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenAProcedureIsLoggedButNotExecutedByParameterDifferenceHasToGiveAnError;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var Method := Context.GetType(TMyClass).GetMethod('MyProcedure');
      var MyMethod := TMyMethod.Create;
      var Result: TValue;

      MethodRegister.StartRegister(MyMethod);

      It.IsEqualTo('abc');

      MethodRegister.RegisterMethod(Method);

      MethodRegister.ExecuteMethod(Method, ['zzz'], Result);
    end, ERegisteredMethodsButDifferentParameters);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenCallAnExceptationMethodMustMarkAsExecuted;
begin
  var Method := TMethodInfoExcept.Create;
  var Result := TValue.Empty;

  Method.Execute(nil, Result);

  Assert.IsTrue(Method.ExceptationExecuted);

  Method.Free;
end;

procedure TMethodRegisterTest.WhenCallAProcedureMustFindTheCorrectProcedureByValueOfCallingParameters;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('AnotherProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyMethod.Create;
  var MyMethodCorrect := TMyMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  It.IsEqualTo('abc');
  It.IsEqualTo(1234);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyMethod);

  It.IsEqualTo('abc');
  It.IsEqualTo(5555);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyMethodCorrect);

  It.IsEqualTo('abc');
  It.IsEqualTo(789);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.ExecuteMethod(Method, ['abc', 789], Result);

  Assert.IsTrue(MyMethodCorrect.FCalled);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenCallExecuteMustCallExecuteFromInterfaceMethod;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(ClassType).GetMethods[0];
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.ExecuteMethod(Method, [], Result);

  Assert.IsTrue(MyMethod.FCalled);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenCallStartRegisterCantRaiseAExpcetionWhenCallRegisterMethod;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillNotRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var Result: TValue;

      MethodRegister.StartRegister(TMyMethod.Create);

      MethodRegister.RegisterMethod(Context.GetType(ClassType).GetMethods[0]);
    end);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenCallStartRegisterMustSetNilToItGlobalVariable;
begin
  GItParams := [TIt.Create];
  var MethodRegister := TMethodRegister.Create;

  MethodRegister.StartRegister(TMyMethod.Create);

  Assert.IsNull(GItParams);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenClassExecuteOfAMethodThatIsNotRegisteredMustRaiseAException;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var MyMethod := TMyMethod.Create;
      var Result: TValue;

      MethodRegister.StartRegister(MyMethod);

      MethodRegister.RegisterMethod(Context.GetType(ClassType).GetMethods[0]);

      MethodRegister.ExecuteMethod(Context.GetType(ClassType).GetMethods[1], [], Result);
    end, EMethodNotRegistered);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenExecuteTheCustomExpectationMustPassTheParamsFromCallingProcedure;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('MyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyMethod.Create;
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  It.IsAny<String>;

  MethodRegister.RegisterMethod(Method);

  MethodRegister.ExecuteMethod(Method, ['String'], Result);

  Assert.AreEqual('String', MyMethod.FParams[0].AsString);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenExistsMoreTheOneExpectationRegisteredMustReturnTheMessageOfAllMethods;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('AnyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyExpectMethod.Create('Expectation message');
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.ExecuteMethod(Method, nil, Result);

  MethodRegister.ExecuteMethod(Method, nil, Result);

  Assert.AreEqual('Expectation message'#13#10'Expectation message', MethodRegister.CheckExpectations);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenRegisteredAMethodOfExpectationMustReturnTheMessageOfExpectationWhenCalled;
begin
  var Context := TRttiContext.Create;
  var Method := Context.GetType(TMyClass).GetMethod('AnyProcedure');
  var MethodRegister := TMethodRegister.Create;
  var MyMethod := TMyExpectMethod.Create('Expectation message');
  var Result: TValue;

  MethodRegister.StartRegister(MyMethod);

  MethodRegister.RegisterMethod(Method);

  MethodRegister.ExecuteMethod(Method, nil, Result);

  Assert.AreEqual('Expectation message', MethodRegister.CheckExpectations);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenRegisteringAProcedureWithParametersYouHaveToRecordTheParametersWithTheItFunction;
begin
  var MethodRegister := TMethodRegister.Create;

  Assert.WillRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var MyMethod := TMyMethod.Create;
      var Result: TValue;

      MethodRegister.StartRegister(MyMethod);

      MethodRegister.RegisterMethod(Context.GetType(TMyClass).GetMethod('MyProcedure'));
    end, EParamsRegisteredMismatch);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenTheNumberOfParametersRecordedIsDifferentFromTheAmountOfParametersTheProcedureHasToRaiseAnError;
begin
  var MethodRegister := TMethodRegister.Create;

  It.IsAny<String>;

  It.IsAny<String>;

  Assert.WillRaise(
    procedure
    begin
      var Context := TRttiContext.Create;
      var MyMethod := TMyMethod.Create;
      var Result: TValue;

      MethodRegister.StartRegister(MyMethod);

      MethodRegister.RegisterMethod(Context.GetType(TMyClass).GetMethod('MyProcedure'));
    end, EParamsRegisteredMismatch);

  MethodRegister.Free;
end;

procedure TMethodRegisterTest.WhenTheOnceMethodIsCalledMoreThenOneTimeMustRegisterInTheMessageTheQuantityOsCalls;
begin
  var Method := TMethodInfoExpectOnce.Create;
  var Value := TValue.Empty;

  for var A := 1 to 10 do
    Method.Execute(nil, Value);

  Assert.AreEqual('Expected to call once the method but was called 10 times', Method.CheckExpectation);

  Method.Free;
end;

procedure TMethodRegisterTest.WhenTheOnceMethodIsCalledOnlyOneTimeTheExpcetationMustReturnEmptyString;
begin
  var Method := TMethodInfoExpectOnce.Create;
  var Value := TValue.Empty;

  Method.Execute(nil, Value);

  Assert.AreEqual(EmptyStr, Method.CheckExpectation);

  Method.Free;
end;

procedure TMethodRegisterTest.WhenUsingTheCustomExpectationMustReturnTheValeuFromFunctionRegistered;
begin
  var Method := TMethodInfoCustomExpectation.Create(
    function (Params: TArray<TValue>): String
    begin
      Result := Params[0].AsString;
    end);
  var Return := TValue.Empty;

  Method.Execute(['Return'], Return);

  Assert.AreEqual('Return', Method.CheckExpectation);

  Method.Free;
end;

{ TMyMethod }

procedure TMyMethod.Execute(const Params: TArray<TValue>; out Result: TValue);
begin
  FCalled := True;
  FParams := Params;
end;

{ TMyClass }

procedure TMyClass.AnotherProcedure(Param: String; Param2: Integer);
begin

end;

procedure TMyClass.AnyProcedure;
begin

end;

procedure TMyClass.MyProcedure(Param: String);
begin

end;

{ TMyExpectMethod }

function TMyExpectMethod.CheckExpectation: String;
begin
  Result := FMessage;
end;

constructor TMyExpectMethod.Create(ExpectationMessage: String);
begin
  inherited Create;

  FMessage := ExpectationMessage;
end;

function TMyExpectMethod.ExceptationExecuted: Boolean;
begin
  Result := FExceptation;
end;

procedure TMyExpectMethod.Execute(const Params: TArray<TValue>; out Result: TValue);
begin
  FExceptation := True;
end;

initialization
  TDUnitX.RegisterTestFixture(TMethodRegisterTest);

end.
