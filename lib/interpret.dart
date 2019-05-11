import 'typedefs.dart';

T fold1<T>(T Function(T, T) f, Iterable<T> xs) {
  if (xs.isEmpty) throw RangeError('Calling fold1 on an empty iterable');

  final list = xs.toList();
  final tail = list.sublist(1);
  return tail.fold(list[0], f);
}

Binding curryingUnaryOperatorBinding(String op, Env env) {
  // op = (\ x (op x))
  return Binding(op,
      VClos(Closure('____x', SExpr([SBind(op), SBind('____x')]), env)), false);
}

Binding curryingBinaryOperatorBinding(String op, Env env) {
  // op = (\ x (\ y (op y x)))
  return Binding(
      op,
      VClos(Closure(
          '____x',
          SExpr([
            SBind('\\'),
            SBind('____y'),
            SExpr([SBind(op), SBind('____y'), SBind('____x')])
          ]),
          env)),
      false);
}

Value curryingBinaryOperatorAppliedOne(
    String op, SExprBase applyingExpr, Env env) {
  // ((op) x)
  return interpret(
      SExpr([
        SExpr([SBind(op)]),
        applyingExpr
      ]),
      env);
}

List<Binding> builtInBinds() {
  final binds = [
    Binding('#t', VBool(true), false),
    Binding('#f', VBool(false), false),
  ];
  final env = Env(binds);

  for (final op in builtInUnaryOperatorMethods.keys) {
    binds.add(curryingUnaryOperatorBinding(op, env));
  }
  for (final op in builtInBinaryOperatorMethods.keys) {
    binds.add(curryingBinaryOperatorBinding(op, env));
  }

  return binds;
}

final defaultEnv = Env(builtInBinds());

final builtInUnaryOperatorMethods = {
  '!': (x) => x is VBool ? VBool(!x.value) : operatorTypeError([x], '!'),
  '~': (x) => x is VNum ? ~x : operatorTypeError([x], '~'),
};

Value valueEquals(Value x, Value y) =>
    ((x is VNum && y is VNum) || (x is VBool && y is VBool))
        ? VBool(x == y)
        : operatorTypeError([x, y], '=');

Value valueNotEquals(Value x, Value y) =>
    ((x is VNum && y is VNum) || (x is VBool && y is VBool))
        ? VBool(x != y)
        : operatorTypeError([x, y], '=');

final Map<String, dynamic> builtInBinaryOperatorMethods = {
  '+': (x, y) =>
      x is VNum && y is VNum ? x + y : operatorTypeError([x, y], '+'),
  '-': (x, y) =>
      x is VNum && y is VNum ? x - y : operatorTypeError([x, y], '-'),
  '*': (x, y) =>
      x is VNum && y is VNum ? x * y : operatorTypeError([x, y], '*'),
  '/': (x, y) =>
      x is VNum && y is VNum ? x / y : operatorTypeError([x, y], '/'),
  '~/': (x, y) =>
      x is VNum && y is VNum ? x ~/ y : operatorTypeError([x, y], '~/'),
  '%': (x, y) =>
      x is VNum && y is VNum ? x % y : operatorTypeError([x, y], '%'),
  '&': (x, y) =>
      x is VNum && y is VNum ? x & y : operatorTypeError([x, y], '&'),
  '|': (x, y) =>
      x is VNum && y is VNum ? x | y : operatorTypeError([x, y], '|'),
  '^': (x, y) =>
      x is VNum && y is VNum ? x ^ y : operatorTypeError([x, y], '^'),
  '<<': (x, y) =>
      x is VNum && y is VNum ? x << y : operatorTypeError([x, y], '<<'),
  '>>': (x, y) =>
      x is VNum && y is VNum ? x >> y : operatorTypeError([x, y], '>>'),
  '=': (x, y) => valueEquals(x, y),
  '!=': (x, y) => valueNotEquals(x, y),
  '>': (x, y) => x is VNum && y is VNum
      ? x.greaterThan(y)
      : operatorTypeError([x, y], '>'),
  '<': (x, y) =>
      x is VNum && y is VNum ? x.lowerThan(y) : operatorTypeError([x, y], '<'),
  '>=': (x, y) => x is VNum && y is VNum
      ? x.greaterEqualThan(y)
      : operatorTypeError([x, y], '>='),
  '<=': (x, y) => x is VNum && y is VNum
      ? x.lowerEqualThan(y)
      : operatorTypeError([x, y], '<='),
  '&&': (x, y) => x is VBool && y is VBool
      ? VBool(x.value && y.value)
      : operatorTypeError([x, y], '&&'),
  '||': (x, y) => x is VBool && y is VBool
      ? VBool(x.value || y.value)
      : operatorTypeError([x, y], '||'),
};
bool isOperator(String op) {
  return builtInUnaryOperatorMethods.containsKey(op) ||
      builtInBinaryOperatorMethods.containsKey(op);
}

VError operatorTypeError(List<Value> invalidValues, String op,
    [SExprBase sExpr]) {
  return VError(
      message: 'Applying operator $op on improper value(s) $invalidValues',
      source: sExpr?.toString(),
      type: 'TypeError');
}

SExpr multipleArgLambda(List<SBind> argList, SExprBase bindedExpr) {
  return argList.reversed
      .fold(bindedExpr, (expr, arg) => SExpr([SBind('\\'), arg, expr]));
}

Value interpret(SExprBase expr, Env env) {
  // SInt
  if (expr is SNum) {
    return VNum(expr.value);
  }
  // SBind
  else if (expr is SBind) {
    final bind = expr;
    final realBind = env.lookUp(bind.name);
    if (realBind == null) {
      return VError(
          message: 'Can not find binding `${bind.name}\'',
          source: expr.toString(),
          type: 'NameError');
    } else {
      return realBind.value;
    }
  }
  // (......)
  else {
    final sExpr = expr as SExpr;
    // ()
    if (sExpr.length == 0) {
      return VError(
          message: 'Syntax error',
          source: expr.toString(),
          type: 'SyntaxError');
    }
    // (x)
    else if (sExpr.length == 1) {
      return interpret(sExpr.elements[0], env);
    }
    // (x ......)
    else {
      final first = sExpr.elements[0];
      // (SNum ......)
      if (first is SNum) {
        return VError(
            message: 'Calling on uncallable object $first',
            source: expr.toString(),
            type: 'TypeError');
      }
      // (SBind ......)
      else if (first is SBind) {
        final sBind = first;
        // (let ......)
        if (sBind.name == 'let') {
          if (sExpr.length != 4) {
            return VError(
                message:
                    'Syntax error in let binding (expected 4 items, got ${sExpr.length})',
                source: expr.toString(),
                type: 'SyntaxError');
          } else {
            // (let <bindName> <bindValueExpr> <bindedExpr>)
            final second = sExpr.elements[1];
            if (second is! SBind) {
              return VError(
                  message:
                      'Expected a bind name at the second item of let binding',
                  source: expr.toString(),
                  type: 'TypeError');
            } else {
              final bindExpr = sExpr.elements[2];
              final bindValue = interpret(bindExpr, env);
              if (bindValue is VError) {
                return bindValue;
              }
              return interpret(sExpr.elements[3],
                  env.extended((second as SBind).name, bindValue));
            }
          }
        } // (let ......)
        // (\ ......) or (lambda ......)
        else if (sBind.name == '\\' || sBind.name == 'lambda') {
          if (sExpr.length != 3) {
            return VError(
                message:
                    'Syntax error in lambda expression (expected 3 items, got ${sExpr.length})',
                source: expr.toString(),
                type: 'SyntaxError');
          } else {
            final second = sExpr.elements[1];
            if (second is SBind) {
              // (\ <bindName> <bindedExpr>)
              final closure = Closure(second.name, sExpr.elements[2], env);
              return VClos(closure);
            } else if (second is SExpr) {
              if (second.length == 0) {
                // (\ () <bindedExpr>)
                // equals to the binded expression itself
                return interpret(sExpr.elements[2], env);
              }
              // (\ (<arg0> ...) <bindedExpr>)
              final argList = second.elements;
              if (argList.any((arg) => arg is! SBind)) {
                return VError(
                    message:
                        'Expected binding names at the second item of lambda expression',
                    source: expr.toString(),
                    type: 'SyntaxError');
              }
              return interpret(
                  multipleArgLambda(argList.cast<SBind>(), sExpr.elements[2]), env);
            } else {
              return VError(
                  message:
                      'Expected a bind name or an argument list at the second item of lambda expression',
                  source: expr.toString(),
                  type: 'TypeError');
            }
          }
        } // (\ ......)
        // (def ......)
        else if (sBind.name == 'def') {
          if (sExpr.length != 3) {
            return VError(
                message:
                    'Syntax error in function definition (expected 3 items, got ${sExpr.length})',
                source: expr.toString(),
                type: 'SyntaxError');
          } else {
            // (def (<functionName> <argList>) <bindedExpr>)
            final second = sExpr.elements[1];
            if (second is SExpr) {
              final funDef = second.elements;
              final argList = funDef.sublist(1);
              if (funDef.any((arg) => arg is! SBind)) {
                return VError(
                    message:
                        'Expected binding names at the second item of function definition',
                    source: expr.toString(),
                    type: 'SyntaxError');
              }
              final closure =
                  interpret(multipleArgLambda(argList.cast<SBind>(), sExpr.elements[2]), env);
              (closure as VClos).value.env.binds
                  .add(Binding((funDef.first as SBind).name, closure));
              // FIXME: ATTENTION!
              assert(closure != (closure as VClos).value.env.binds.first.value);
              return closure;
              // final namedClosure = NamedClosure(
              //     (funDef.first as SBind).name, (closure as VClos).value);
              // return VFunc(namedClosure);
            } else {
              return VError(
                  message:
                      'Expected a function declaration at the second item of function definition',
                  source: expr.toString(),
                  type: 'SyntaxError');
            }
          }
        } // (def ......)
        // (if ......)
        else if (sBind.name == 'if') {
          if (sExpr.length != 4) {
            return VError(
                message:
                    'Syntax error in if-expression (expected 4 items, got ${sExpr.length})',
                source: expr.toString(),
                type: 'SyntaxError');
          } else {
            final condition = interpret(sExpr.elements[1], env);
            if (condition is VError) {
              return condition;
            } else if (condition is! VBool) {
              return VError(
                  message:
                      'Expected a boolean on if-condition, got ${condition}',
                  source: expr.toString(),
                  type: 'TypeError');
            } else {
              final vBool = condition as VBool;
              if (vBool.value) {
                return interpret(sExpr.elements[2], env);
              } else {
                return interpret(sExpr.elements[3], env);
              }
            }
          }
        } // (if ......)
        // (op ......)
        else if (isOperator(sBind.name)) {
          if (builtInBinaryOperatorMethods.containsKey(sBind.name)) {
            if (sExpr.length == 3) {
              final xValue = interpret(sExpr.elements[1], env);
              final yValue = interpret(sExpr.elements[2], env);
              if (xValue is VError) return xValue;
              if (yValue is VError) return yValue;
              return builtInBinaryOperatorMethods[sBind.name](xValue, yValue);
            } else if (sExpr.length > 3) {
              final values =
                  sExpr.elements.sublist(1).map((expr) => interpret(expr, env));
              return fold1(builtInBinaryOperatorMethods[sBind.name], values);
              // return VError(
              //     message: 'Not yet implemented',
              //     source: expr.toString(),
              //     type: 'NotYetImplementedError');
            } else {
              return curryingBinaryOperatorAppliedOne(
                  sBind.name, sExpr.elements[1], env);
            }
          } else if (builtInUnaryOperatorMethods.containsKey(sBind.name)) {
            if (sExpr.length == 2) {
              final xValue = interpret(sExpr.elements[1], env);
              if (xValue is VError) return xValue;
              return builtInUnaryOperatorMethods[sBind.name](xValue);
            } else if (sExpr.length > 2) {
              return VError(
                  message: 'Required only 1 operand of operator ${sBind.name}',
                  source: expr.toString(),
                  type: 'OperatorError');
            } else {
              // can't go here
            }
          } else {
            // not possible
          }
        } // (op ......)
        else if (sExpr.length == 2) {
        } else {
          final foldedExpr = sExpr.elements
              .sublist(1)
              .fold(sBind, (caller, expr) => SExpr([caller, expr]));
          return interpret(foldedExpr, env);
        } // other (SBind ......)
      } // (SBind ......)
      // other (SBind ...), or (SExpr ......)
      if (sExpr.length == 2) {
        // other (SBind ...), or (SExpr ...)
        final callerValue = interpret(sExpr.elements[0], env);
        final argValue = interpret(sExpr.elements[1], env);
        if (callerValue is VError) return callerValue;
        if (argValue is VError) return argValue;

        if (callerValue is! VClos) {
          return VError(
              message:
                  'Calling on uncallable expression ${sExpr.elements[0]} which evaluates to $callerValue',
              source: expr.toString(),
              type: 'TypeError');
        } else {
          final closure = (callerValue as VClos).value;
          final bindName = closure.bindName;
          final bindExpr = closure.bindExpr;
          final bindEnv = closure.env;
          return interpret(bindExpr, bindEnv.extended(bindName, argValue));
        }
      } // (SExpr ...)
      else {
        // other (SExpr ......)
        final tail = sExpr.elements.sublist(1);
        final folded = tail.fold(
            sExpr.elements[0], (caller, expr) => SExpr([caller, expr]));
        return interpret(folded, env);
      }
    } // (SExpr ......)
  }
}

Value execute(SExprBase expr) => interpret(expr, defaultEnv);
