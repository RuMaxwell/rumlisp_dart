import 'typedefs.dart';

enum TokenType {
  init,
  leftParen,
  rightParen,
  leftBrac,
  rightBrac,
  bind,
  number,
  eof
}

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
const Token leftBracToken = Token(TokenType.leftBrac, '');
const Token rightBracToken = Token(TokenType.rightBrac, '');

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
      sp.position < sp.source.length && (sp.char.startsWith(RegExp(r'[\s;]')));
      sp.position++) {
    if (sp.char == ';') {
      // Comments
      for (sp.position++;
          sp.position < sp.source.length && sp.char != ';';
          sp.position++) {}
      sp.position++;
    }
  }
  if (sp.position >= sp.source.length) return eofToken;

  if (sp.char == '(') {
    sp.position++;
    return leftParenToken;
  } else if (sp.char == ')') {
    sp.position++;
    return rightParenToken;
  } else if (sp.char == '[') {
    sp.position++;
    return leftBracToken;
  } else if (sp.char == ']') {
    sp.position++;
    return rightBracToken;
  } else {
    final start = sp.position;
    // Get the end of the token
    sp.position = sp.source.indexOf(RegExp(r'[\s()\[\]]'), start);
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
  ParseResult.sExprs(List<SExprBase> sExprs) {
    this._result = sExprs;
  }

  bool get isError => _result is ParseError;

  List<SExprBase> get sExprs => !isError ? _result as List<SExprBase> : null;

  @override
  String toString() {
    if (isError) {
      return (_result as ParseError).toString();
    } else {
      return (_result as List<SExprBase>).toString();
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
  source = source ?? '';

  final tokenStack = <Token>[];
  final sourcePosition = SourcePosition(source, 0);
  var token = initToken;
  // Store encountered parentheses (including ()s and []s)
  var parenthesesStack = <String>[];

  while (token.type != TokenType.eof) {
    token = tokenizer(sourcePosition);

    if (token.type == TokenType.leftParen) {
      parenthesesStack.add('(');
    } else if (token.type == TokenType.rightParen) {
      if (parenthesesStack.isNotEmpty && parenthesesStack.last == '(') {
        parenthesesStack.removeLast();
      } else {
        return ParseResult.error(
          'Parentheses unmatched: ] at ${sourcePosition.position} (${parenthesesStack.isEmpty ? -1 : ''})');
      }
    } else if (token.type == TokenType.leftBrac) {
      parenthesesStack.add('[');
    } else if (token.type == TokenType.rightBrac) {
      if (parenthesesStack.isNotEmpty && parenthesesStack.last == '[') {
        parenthesesStack.removeLast();
      } else {
        return ParseResult.error(
          'Parentheses unmatched: ] at ${sourcePosition.position} (${parenthesesStack.isEmpty ? -1 : ''})');
      }
    }

    tokenStack.add(token);
  }

  if (parenthesesStack.isNotEmpty) {
    return ParseResult.error('Parentheses unmatched: lack of ${parenthesesStack.length} )s or ]s');
  }

  // Remove the last EOF token
  tokenStack.removeLast();

  final exprStack = <SExprBase>[];

  while (tokenStack.isNotEmpty) {
    token = tokenStack.removeLast();

    if (token.type == TokenType.leftParen) {
      final elements = <SExprBase>[];
      while (exprStack.isNotEmpty) {
        final item = exprStack.removeLast();
        if (item == parenSignal) {
          break;
        } else {
          elements.add(item);
        }
      }
      final expr = SExpr(elements);
      exprStack.add(expr);
    } else if (token.type == TokenType.rightParen) {
      exprStack.add(parenSignal);
    } else if (token.type == TokenType.leftBrac) {
      final elements = <SExprBase>[];
      while (exprStack.isNotEmpty) {
        final item = exprStack.removeLast();
        if (item == bracSignal) {
          break;
        } else {
          elements.add(item);
        }
      }
      final expr = SList(elements);
      exprStack.add(expr);
    } else if (token.type == TokenType.rightBrac) {
      exprStack.add(bracSignal);
    } else if (token.type == TokenType.number) {
      final number = num.parse(token.literal);
      final sNum = SNum(number);
      exprStack.add(sNum);
    } else if (token.type == TokenType.bind) {
      final sBind = SBind(token.literal);
      exprStack.add(sBind);
    }
  }

  if (exprStack.isEmpty) {
    return ParseResult.error('Not yielding a result');
  } else {
    return ParseResult.sExprs(exprStack.reversed.toList());
  }
}
