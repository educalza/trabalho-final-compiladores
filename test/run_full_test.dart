import 'dart:io';
import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/interpreter/interpreter.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

void main() async {
  final file = File('examples/full_test.c');
  if (!await file.exists()) {
    print("Arquivo examples/full_test.c não encontrado.");
    return;
  }
  
  final code = await file.readAsString();
  print("Executando examples/full_test.c...");
  
  final input = InputStream.fromString(code);
  final lexer = CSubsetLexer(input);
  final tokens = CommonTokenStream(lexer);
  final parser = CSubsetParser(tokens);
  
  final tree = parser.program();
  
  if (parser.numberOfSyntaxErrors > 0) {
    print("Erros de sintaxe: ${parser.numberOfSyntaxErrors}");
    return;
  }
  
  print("Parsing OK. Executando Análise Semântica...");
  
  final analyzer = SemanticAnalyzer();
  try {
    analyzer.visit(tree);
    print("Análise Semântica OK.");
  } catch (e) {
    print("Erro Semântico: $e");
    return;
  }
  
  print("Executando Interpretador...");
  final interpreter = Interpreter();
  interpreter.visit(tree);
  
  print("Chamando main()...");
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
