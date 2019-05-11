import 'typedefs.dart';

enum TokenType { init, leftParen, rightParen, bind, number, eof }

class Token {
  final TokenType type;
  final String literal;

  const Token(this.type, this.literal);

  @override
  String toString() {
    return '$type {$literal}';
  }
}

const Token initToken = Token(TokenType.init, '');
const Token eofToken = Token(TokenType.eof, '');
const Token leftParenToken = Token(TokenType.leftParen, '');
const Token rightParenToken = Token(TokenType.rightParen, '');

class SourcePosition {
  final String source;
  int position;

  SourcePosition(this.source, int position) {
    this.position = position;
  }

  String get char => source[position];
}

Token tokenizer(SourcePosition sp) {
  if (sp.position >= sp.source.length) {
    return eofToken;
  }
  for (;
      sp.position < sp.source.length && (sp.char.startsWith(RegExp(r'\s')));
      sp.position++) {}
  if (sp.position == sp.source.length) return eofToken;

  if (sp.char == '(') {
    sp.position++;
    return leftParenToken;
  } else if (sp.char == ')') {
    sp.position++;
    return rightParenToken;
  } else {
    final start = sp.position;
    sp.position = sp.source.indexOf(RegExp(r'[\s()]'), start);
    sp.position = sp.position == -1 ? sp.source.length : sp.position;

    final literal = sp.source.substring(start, sp.position);
    if (literal.startsWith(RegExp(r'^\-?\d+(\.\d*)?$'))) {
      return Token(TokenType.number, literal);
    } else {
      return Token(TokenType.bind, literal);
    }
  }
}

class ParseResult {
  Object _result;

  ParseResult(this._result);

  ParseResult.error(String message) {
    this._result = ParseError(message);
  }
  ParseResult.sExpr(SExprBase sExpr) {
    this._result = sExpr;
  }

  bool get isError => _result is ParseError;

  SExprBase get sExpr => !isError ? _result as SExprBase : null;

  @override
  String toString() {
    if (isError) {
      return (_result as ParseError).toString();
    } else {
      return (_result as SExprBase).toString();
    }
  }
}

class ParseError {
  final String message;

  const ParseError(this.message);

  @override
  String toString() {
    return 'Parse Error: $message';
  }
}

ParseResult parse(String source) {
  final tokenStack = <Token>[];
  final sourcePosition = SourcePosition(source, 0);
  var token = initToken;
  var parenthesesCount = 0;

  while (token.type != TokenType.eof) {
    token = tokenizer(sourcePosition);

    if (token.type == TokenType.leftParen)
      parenthesesCount++;
    else if (token.type == TokenType.rightParen) parenthesesCount--;

    if (parenthesesCount < 0) {
      return ParseResult.error(
          'Parentheses unmatched: $parenthesesCount at ${sourcePosition.position}');
    }

    tokenStack.add(token);
  }

  if (parenthesesCount > 0) {
    return ParseResult.error('Parentheses unmatched: $parenthesesCount');
  }

  // Remove the last EOF token
  tokenStack.removeLast();

  final exprStack = <SExprBase>[];

  while (tokenStack.length > 0) {
    token = tokenStack.removeLast();

    if (token.type == TokenType.leftParen) {
      final elements = <SExprBase>[];
      while (exprStack.length > 0) {
        final item = exprStack.removeLast();
        if (item == null)
          break;
        else
          elements.add(item);
      }
      final expr = SExpr(elements);
      exprStack.add(expr);
    } else if (token.type == TokenType.rightParen) {
      exprStack.add(null);
    } else if (token.type == TokenType.number) {
      final number = num.parse(token.literal);
      final sNum = SNum(number);
      exprStack.add(sNum);
    } else if (token.type == TokenType.bind) {
      final sBind = SBind(token.literal);
      exprStack.add(sBind);
    }
  }

  if (exprStack.length == 0) {
    return ParseResult.error('Not yielding a result');
  } else {
    return ParseResult.sExpr(exprStack.removeLast());
  }
}
