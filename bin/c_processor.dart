import 'dart:io';
import 'package:antlr4/antlr4.dart';
import 'package:c_processor/src/generated/CSubsetLexer.dart';
import 'package:c_processor/src/generated/CSubsetParser.dart';
import 'package:c_processor/src/interpreter/interpreter.dart';
import 'package:c_processor/src/semantic/semantic_analyzer.dart';

class CustomErrorListener extends BaseErrorListener {
  @override
  void syntaxError(
      Recognizer<dynamic> recognizer,
      Object? offendingSymbol,
      int? line,
      int charPositionInLine,
      String msg,
      RecognitionException<dynamic>? e) {
    print('Erro de sintaxe na linha $line:$charPositionInLine - $msg');
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    await _runRepl();
    return;
  }

  final filePath = arguments[0];
  final file = File(filePath);

  if (!await file.exists()) {
    print('Erro: Arquivo "$filePath" não encontrado.');
    exit(1);
  }

  print('Processando $filePath...');

  try {
    final input = await InputStream.fromPath(filePath);
    final lexer = CSubsetLexer(input);
    final tokens = CommonTokenStream(lexer);
    final parser = CSubsetParser(tokens);

    final tree = parser.program();

    if (parser.numberOfSyntaxErrors > 0) {
      print('Falha na análise sintática: ${parser.numberOfSyntaxErrors} erros encontrados.');
      exit(1);
    }

    print('Análise sintática concluída com sucesso.');
    print('Iniciando análise semântica...');

    final semanticAnalyzer = SemanticAnalyzer();
    semanticAnalyzer.visit(tree);

    print('Análise semântica concluída com sucesso! Nenhum erro encontrado.');
    
    // Opcional: Executar o arquivo também?
    // print('Executando...');
    // final interpreter = Interpreter();
    // interpreter.visit(tree);

  } catch (e) {
    print('Erro durante o processamento:');
    print(e);
    exit(1);
  }
}

Future<void> _runRepl() async {
  print('CSubset REPL (v0.0.1)');
  print('Digite "exit" para sair.');
  
  final interpreter = Interpreter();
  final semanticAnalyzer = SemanticAnalyzer();
  
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync();
    
    if (line == null || line.trim() == 'exit') break;
    if (line.trim().isEmpty) continue;

    try {
      final input = InputStream.fromString(line);
      final lexer = CSubsetLexer(input);
      final tokens = CommonTokenStream(lexer);
      final parser = CSubsetParser(tokens);
      
      parser.removeErrorListeners();
      parser.addErrorListener(CustomErrorListener());
      
      ParseTree tree;
      bool isExpression = false;
      
      if (line.trim().endsWith(';') || line.contains('int ') || line.contains('float ') || line.contains('if') || line.contains('while') || line.contains('switch') || line.contains('for') || line.contains('break')) {
         tree = parser.statement();
      } else {
         tree = parser.expression();
         isExpression = true;
      }
      
      if (parser.numberOfSyntaxErrors > 0) {
        // Erro já impresso pelo listener
        continue;
      }

      // Validação Semântica
      try {
        semanticAnalyzer.visit(tree);
      } catch (e) {
        print(e);
        continue;
      }

      // Executa
      final result = interpreter.visit(tree);
      
      if (isExpression && result != null) {
        print(result);
      }
      
    } catch (e) {
      print('Erro: $e');
    }
  }
}
