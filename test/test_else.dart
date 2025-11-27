import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/interpreter/interpreter.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

void main() async {
  final code = """
  void main() {
    int x = 10;
    if (x > 5) {
      print(1);
    } else {
      print(0);
    }
    
    if (x < 5) {
      print(0);
    } else {
      print(2);
    }
    
    if (x == 10) {
      print(3);
    }
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
  
  // Executa main()
  print("Chamando main()...");
  try {
     // Simula chamada de função main()
     // Precisamos criar um FunctionCallContext fake ou invocar via método interno se exposto.
     // Como visitFunctionCall espera contexto, vamos criar um contexto mínimo ou usar environment direto.
     // Mas environment é privado/interno.
     // Vamos usar um truque: parsear uma chamada "main();" e visitar.
     
     final callCode = "main();";
     final callLexer = CSubsetLexer(InputStream.fromString(callCode));
     final callParser = CSubsetParser(CommonTokenStream(callLexer));
     final callTree = callParser.statement(); // statement -> exprStmt -> functionCall
     interpreter.visit(callTree);
     
  } catch (e) {
     print("Erro na execução de main: $e");
  }
}
