import 'package:rumlisp_dart/interpret.dart';
import 'package:rumlisp_dart/parse.dart';

main() {
  final code = r'(let f (\ x (+ x 1)) (f 1))';
  final parsed = parse(code);
  if (parsed.isError) {
    print(parsed);
  } else {
    print(parsed.sExprs.map(execute));
  }
}
