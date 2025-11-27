import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/interpreter/interpreter.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

void main() async {
  final code = """
  void main() {
    int i = 0;
    
    print("Teste 1: Loop normal (0 a 2)");
    do {
      print(i);
      i = i + 1;
    } while (i < 3);
    
    print("Teste 2: Executa pelo menos uma vez");
    do {
      print(100);
    } while (0);
    
    print("Teste 3: Break");
    int j = 0;
    do {
      print(200);
      j = j + 1;
      if (j == 1) break;
      print(300); // Não deve imprimir
    } while (1);
    
    print("Fim");
  }
  """;
  
  print("Código a ser testado:");
  print(code);
  
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
