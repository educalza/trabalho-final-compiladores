import 'dart:io';
import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/interpreter/interpreter.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

void main() async {
  final file = File('examples/loop_debug_2.c');
  final code = await file.readAsString();
  print("Executando examples/loop_debug_2.c...");
  
  final input = InputStream.fromString(code);
  final lexer = CSubsetLexer(input);
  final tokens = CommonTokenStream(lexer);
  final parser = CSubsetParser(tokens);
  
  final tree = parser.program();
  
  final analyzer = SemanticAnalyzer();
  try {
    analyzer.visit(tree);
  } catch (e) {
    print("Erro Semântico: $e");
    return;
  }
  
  final interpreter = Interpreter();
  interpreter.visit(tree);
  
  try {
     final callCode = "main();";
     final callLexer = CSubsetLexer(InputStream.fromString(callCode));
     final callParser = CSubsetParser(CommonTokenStream(callLexer));
     final callTree = callParser.statement();
     interpreter.visit(callTree);
  } catch (e) {
     print("Erro na execução de main: $e");
  }
}
