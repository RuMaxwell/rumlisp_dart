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

String prompt([String message = '>']) {
  stdout.write(message);
  return stdin.readLineSync();
}

void printReplHelp() {
  print(''':help           Show this help message.
:quit :q :exit  Exit the repl.''');
}

void startRepl() {
  print('''rumlisp REPL version 1.0.0
To see help, enter \':help\'''');
  var program;
  while (true) {
    program = prompt('> ');
    program = program.trim();
    if (program[0] == ':') {
      if (program == ':help') {
        printReplHelp();
        continue;
      } else if (program == ':quit' || program == ':q' || program == ':exit') {
        break;
      }
      printReplHelp();
      continue;
    }

    final parseResult = parse(program);
    if (parseResult.isError) {
      print(parseResult);
    } else {
      tryExecute(parseResult);
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
      startRepl();
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
