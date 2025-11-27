import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

void main() async {
  final code = "for (int i = 0; i < 5; i = i + 1) { print(i); }";
  final input = InputStream.fromString(code);
  final lexer = CSubsetLexer(input);
  final tokens = CommonTokenStream(lexer);
  final parser = CSubsetParser(tokens);
  
  // Parse como statement
  final tree = parser.statement();
  
  if (parser.numberOfSyntaxErrors > 0) {
    print("Erros de sintaxe: ${parser.numberOfSyntaxErrors}");
    return;
  }
  
  print("Parsing OK. Visitando...");
  
  final analyzer = SemanticAnalyzer();
  try {
    analyzer.visit(tree);
    print("Análise Semântica OK.");
  } catch (e) {
    print("Erro Semântico: $e");
  }
}
