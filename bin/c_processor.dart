import 'dart:io';
import 'package:antlr4/antlr4.dart';
import 'package:c_processor/c_processor.dart';

import 'package:c_processor/src/interpreter/interpreter.dart';

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

    // Adiciona listener de erro customizado se necessário, 
    // mas o padrão já imprime no console.
    
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
      
      // Tenta parsear como statement primeiro (declaração, if, etc)
      // Mas nossa gramática exige que tudo esteja em função ou global?
      // Vamos tentar parsear como 'statement' ou 'expression' diretamente.
      // Precisamos expor essas regras no parser? Sim, elas são públicas.
      
      // Hack: Tenta parsear como statement. Se falhar, tenta expression.
      // O ANTLR lança erro ou retorna árvore de erro?
      
      // Abordagem simplificada para REPL:
      // Se termina com ';', é statement. Senão tenta expressão.
      
      ParseTree tree;
      bool isExpression = false;
      
      parser.removeErrorListeners(); // Remove console listener padrão
      // parser.addErrorListener(...); // Poderíamos adicionar um customizado
      
      if (line.trim().endsWith(';') || line.contains('int ') || line.contains('float ')) {
         // Tenta statement ou declaração
         // O parser espera 'program' (lista de decls).
         // Vamos tentar 'statement' direto se a gramática permitir.
         // A regra 'statement' existe.
         tree = parser.statement();
      } else {
         tree = parser.expression();
         isExpression = true;
      }
      
      if (parser.numberOfSyntaxErrors > 0) {
        print('Erro de sintaxe.');
        continue;
      }

      // Validação Semântica (Tipagem Forte)
      try {
        semanticAnalyzer.visit(tree);
      } catch (e) {
        print(e); // Exibe erro semântico (ex: tipo incompatível)
        continue; // Não executa se houver erro
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
