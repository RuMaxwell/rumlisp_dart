class Closure {
  final String bindName;
  final SExprBase bindExpr;
  final Env env;

  const Closure(this.bindName, this.bindExpr, this.env);

  @override
  String toString() {
    final test = (Binding bind) =>
        bind.value is VClos && (bind.value as VClos).value == this;
    if (env.binds.any(test)) {
      final _this = env.binds.where(test);
      final _env = Env(env.binds.where((b) => !test(b)).toList())
          .extended(_this.first.name, VString('<NamedThis>'));
      return Closure(bindName, bindExpr, _env).toString();
    }
    return '(\\ ${bindName} . ${bindExpr}) where ${env}';
  }
}

class Binding {
  final String name;
  final Value value;
  final bool shouldShow;

  const Binding(this.name, this.value, [this.shouldShow = true]);

  @override
  String toString() {
    return '<${this.name} = ${this.value}>';
  }
}

class Env {
  final List<Binding> binds;

  const Env(this.binds);

  String _toString() {
    var s = '';
    if (binds.isEmpty) return s;

    var i = 0;
    Binding bind;
    for (; i < binds.length; i++) {
      bind = binds[i];
      if (bind.shouldShow) break;
    }
    s += bind.shouldShow ? bind.toString() : '';
    for (i++; i < binds.length; i++) {
      bind = binds[i];
      s += bind.shouldShow ? ', ${binds[i].toString()}' : '';
    }

    return s;
  }

  Env extended(String name, Value value) {
    return Env([Binding(name, value), ...binds]);
  }

  Binding lookUp(String name) {
    return binds.firstWhere((bind) => bind.name == name, orElse: () => null);
  }

  @override
  String toString() {
    return '[${_toString()}]';
  }
}

abstract class Value {
  const Value();
  dynamic get value;
}

class VNum extends Value {
  final num value;

  const VNum(this.value);

  VNum operator +(VNum x) => VNum(value + x.value);
  VNum operator -(VNum x) => VNum(value - x.value);
  VNum operator *(VNum x) => VNum(value * x.value);
  VNum operator /(VNum x) => VNum(value / x.value);
  VNum operator ~/(VNum x) => VNum(value ~/ x.value);
  VNum operator %(VNum x) => VNum(value % x.value);
  VNum operator &(VNum x) => VNum(value.toInt() & x.value.toInt());
  VNum operator |(VNum x) => VNum(value.toInt() | x.value.toInt());
  VNum operator ^(VNum x) => VNum(value.toInt() ^ x.value.toInt());
  VNum operator <<(VNum x) => VNum(value.toInt() << x.value.toInt());
  VNum operator >>(VNum x) => VNum(value.toInt() >> x.value.toInt());
  VNum operator ~() => VNum(~value.toInt());
  bool operator ==(x) {
    if (x is! VNum) {
      return false;
    } else {
      return value == (x as VNum).value;
    }
  }

  VBool greaterThan(VNum x) => VBool(value > x.value);
  VBool greaterEqualThan(VNum x) => VBool(value >= x.value);
  VBool lowerThan(VNum x) => VBool(value < x.value);
  VBool lowerEqualThan(VNum x) => VBool(value <= x.value);

  @override
  String toString() {
    return '$value';
  }
}

class VBool extends Value {
  final bool value;

  const VBool(this.value);

  bool operator ==(x) {
    if (x is! VBool) {
      return false;
    } else {
      return value == (x as VBool).value;
    }
  }

  @override
  String toString() {
    return value ? '#t' : '#f';
  }
}

class VString extends Value {
  final String value;

  const VString(this.value);

  bool operator ==(x) {
    if (x is! VString) {
      return false;
    } else {
      return value == (x as VString).value;
    }
  }

  @override
  String toString() {
    return value;
  }
}

class VClos extends Value {
  final Closure value;

  const VClos(this.value);

  @override
  String toString() {
    return value.toString();
  }
}

class VFunc extends Value {
  static final List<VFunc> functions = [];
  static VFunc lookUp(String name) {
    return functions.isEmpty
        ? null
        : functions.firstWhere((func) => func.name == name, orElse: () => null);
  }

  final String name;
  final Closure value;

  VFunc(this.name, this.value) {
    functions.add(this);
  }

  @override
  String toString() {
    return 'Fn{$name $value}';
  }
}

// used for yielding VFunc result that it not important
final VFunc nullFunc = VFunc(null, null);

class Global {
  static final List<VFunc> functions = VFunc.functions;
  static final List<Binding> bindings = [];

  static final lookUpFunction = VFunc.lookUp;
  static Binding lookUpBinding(String name) {
    return bindings.isEmpty ? null : bindings.firstWhere((b) => b.name == name);
  }
  static void clear() {
    bindings.clear();
    functions.clear();
  }
}

class VError extends Value {
  final VError value = null;
  final String message;
  final String source;
  final String type;

  const VError({this.message = '', this.source = '', this.type = ''});

  @override
  String toString() {
    return '${type.isEmpty ? 'Error' : type}: $message at $source';
  }
}

abstract class SExprBase {
  const SExprBase();
}

class SNum extends SExprBase {
  final num value;

  const SNum(this.value);

  @override
  String toString() {
    return value.toString();
  }
}

class SBind extends SExprBase {
  final String name;

  const SBind(this.name);

  @override
  String toString() {
    return name;
  }
}

class SExpr extends SExprBase {
  final List<SExprBase> elements;

  const SExpr(this.elements);

  int get length => elements.length;

  String _toString() {
    if (elements.isEmpty) return '';
    var s = '';
    for (var i = 0; i < elements.length - 1; i++) {
      s += elements[i].toString();
      s += ' ';
    }
    s += elements[elements.length - 1].toString();
    return s;
  }

  @override
  String toString() {
    return '(${_toString()})';
  }
}
