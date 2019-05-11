import '../lib/parse.dart';

main() {
  final code = r'(let f (\ x (+ x 1)) (f 1))';
  var token = initToken;
  var tokenList = <Token>[];
  var sourcePosition = SourcePosition(code, 0);
  while (token.type != TokenType.eof) {
    token = tokenizer(sourcePosition);
    tokenList.add(token);
  }
  for (final tk in tokenList) {
    print(tk);
  }
}
