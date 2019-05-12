import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'package:rumlisp_dart/interpret.dart';
import 'package:rumlisp_dart/parse.dart';
import 'package:rumlisp_dart/typedefs.dart';

void printHelp() {
  print('''Usage:
  \${RUMLISP}             Enter REPL.
  \${RUMLISP} <file>      Execute a source file.

  -e --execute <program>  Execute the program from console.
  -p --parse-only         Show parse result of the program, do not execute.
''');
}

void tryExecute(ParseResult parseResult) {
  if (parseResult != null) {
    if (parseResult.isError) {
      print(parseResult);
    } else {
      parseResult.sExprs.map(execute).forEach((v) => v is! VFunc ? print(v) : null);
    }
  }
}

Future<void> main(List<String> args) async {
  final argParser = ArgParser();
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('parse-only',
      negatable: false, defaultsTo: false);
  argParser.addOption('execute', abbr: 'e');
  final argResult = argParser.parse(args);
  final files = argResult.rest;

  bool showHelp = argResult['help'];
  bool parseOnly = argResult['parse-only'];
  String code = argResult['execute'];

  if (showHelp) {
    printHelp();
    return;
  }

  var parsed;
  if (code != null) {
    parsed = parse(code);
    if (parseOnly) {
      print(parsed);
    } else {
      tryExecute(parsed);
    }
  } else {
    if (files.isEmpty) {
      print('REPL not implemented');
      // TODO:
    } else {
      for (final filename in files) {
        final file = File(filename);
        final content = await file.readAsString(encoding: utf8);
        parsed = parse(content);
        if (files.length > 1) print('FILE: $filename');
        if (parseOnly) {
          print(parsed);
        } else {
          tryExecute(parsed);
        }
        print('');
      }
    }
  }
}
