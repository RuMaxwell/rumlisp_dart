class Closure {
  final String bindName;
  final SExprBase bindExpr;
  final Env env;

  const Closure(this.bindName, this.bindExpr, this.env);

  @override
  String toString() {
    return '(\\ ${this.bindName} . ${this.bindExpr}) where ${this.env}';
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
    for (; i < s.length - 1; i++) {
      bind = binds[i];
      s += bind.shouldShow ? '${binds[i].toString()}, ' : '';
    }
    bind = binds[i];
    s += bind.shouldShow ? bind.toString() : '';

    return s;
  }

  @override
  String toString() {
    return '[${_toString()}]';
  }

  Env extended(String name, Value value) {
    return Env([Binding(name, value), ...binds]);
  }

  Binding lookUp(String name) {
    return binds.firstWhere((bind) => bind.name == name, orElse: () => null);
  }
}


abstract class Value {
  const Value();
}

class VNum extends Value {
  final num value;

  const VNum(this.value);

  VNum operator+(VNum x) => VNum(value + x.value);
  VNum operator-(VNum x) => VNum(value - x.value);
  VNum operator*(VNum x) => VNum(value * x.value);
  VNum operator/(VNum x) => VNum(value / x.value);
  VNum operator~/(VNum x) => VNum(value ~/ x.value);
  VNum operator%(VNum x) => VNum(value % x.value);
  VNum operator&(VNum x) => VNum(value.toInt() & x.value.toInt());
  VNum operator|(VNum x) => VNum(value.toInt() | x.value.toInt());
  VNum operator^(VNum x) => VNum(value.toInt() ^ x.value.toInt());
  VNum operator<<(VNum x) => VNum(value.toInt() << x.value.toInt());
  VNum operator>>(VNum x) => VNum(value.toInt() >> x.value.toInt());
  VNum operator~() => VNum(~value.toInt());
  bool operator==(x) {
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

  bool operator==(x) {
    if (x == null || x is! VBool) {
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

class VClos extends Value {
  final Closure value;

  const VClos(this.value);

  @override
  String toString() {
    return value.toString();
  }
}

class VError extends Value {
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
