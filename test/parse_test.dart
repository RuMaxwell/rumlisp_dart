import 'package:rumlisp_dart/parse.dart';

main() {
  final code = r'(let f (\ x (+ x 1)) (f 1))';
  final result = parse(code);
  print(result);
}
