import '../lib/interpret.dart';
import '../lib/parse.dart';

main() {
  final code = r'(let f (\ x (+ x 1)) (f 1))';
  final parsed = parse(code);
  if (parsed.isError) {
    print(parsed);
  } else {
    print(execute(parsed.sExpr));
  }
}
