import 'package:rumlisp_dart/interpret.dart';
import 'package:rumlisp_dart/parse.dart';
import 'package:rumlisp_dart/typedefs.dart';

class CompileResult {
  ParseResult _parseResult;
  List<Value> _values;

  CompileResult(this._parseResult, this._values);

  bool get hasError => hasParseError || hasInterpretError;
  bool get hasParseError => _parseResult == null ? true : _parseResult.isError;
  bool get hasInterpretError => _values == null ? true : _values.any((x) => x is VError);
  String get parseResult => hasParseError ? _parseResult.toString() : _parseResult?.sExprs?.join('\r\n');
  List<Value> get value => _values;

  @override
  String toString() {
    if (hasParseError) {
      return 'Parse failed\r\n$parseResult';
    } else {
      return value.where((x) => x is! VFunc).join('\r\n');
    }
  }
}

CompileResult compileFromSource(String source) {
  final parseResult = parse(source);
  var compileResult;
  if (parseResult.isError) {
    compileResult = CompileResult(parseResult, null);
  } else {
    final executeResult = parseResult.sExprs.map(execute).toList();
    compileResult = CompileResult(parseResult, executeResult);
  }
  Global.clear();
  return compileResult;
}
