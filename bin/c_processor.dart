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
    // Pré-processamento
    String code = await _preprocess(filePath);
    // print("Código Pré-processado:\n$code"); // Debug

    final input = InputStream.fromString(code);
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
    
    print('Executando...');
    final interpreter = Interpreter();
    interpreter.visit(tree); // Carrega funções
    
    // Invoca main()
    try {
       final callCode = "main();";
       final callLexer = CSubsetLexer(InputStream.fromString(callCode));
       final callParser = CSubsetParser(CommonTokenStream(callLexer));
       final callTree = callParser.statement();
       interpreter.visit(callTree);
    } catch (e) {
       print("Erro de Execução: $e");
    }

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

// Função de pré-processamento
Future<String> _preprocess(String filePath, [Set<String>? visited, Map<String, String>? defines]) async {
  visited ??= {};
  defines ??= {};
  
  final file = File(filePath);
  if (!await file.exists()) {
     throw Exception("Arquivo não encontrado: $filePath");
  }
  
  // Evita inclusão cíclica
  final absolutePath = file.absolute.path;
  if (visited.contains(absolutePath)) {
     return ""; // Já incluído
  }
  visited.add(absolutePath);
  
  final lines = await file.readAsLines();
  final processedLines = <String>[];
  
  for (var line in lines) {
     final trimmed = line.trim();
     
     // #include "arquivo"
     if (trimmed.startsWith('#include')) {
        final match = RegExp(r'#include\s+"([^"]+)"').firstMatch(trimmed);
        if (match != null) {
           final includedPath = match.group(1)!;
           // Resolve caminho relativo ao arquivo atual
           final currentDir = file.parent.path;
           final fullIncludedPath = "$currentDir/$includedPath"; // Simplificado
           
           // Passa os mesmos defines para o arquivo incluído
           final includedContent = await _preprocess(fullIncludedPath, visited, defines);
           processedLines.add(includedContent);
        } else {
           processedLines.add(line); // Include inválido ou <system>? Mantém.
        }
        continue;
     }
     
     // #define KEY VALUE
     if (trimmed.startsWith('#define')) {
        final match = RegExp(r'#define\s+(\w+)\s+(.+)').firstMatch(trimmed);
        if (match != null) {
           final key = match.group(1)!;
           final value = match.group(2)!.trim();
           defines[key] = value;
        }
        // Remove a linha do define
        processedLines.add(""); 
        continue;
     }
     
     // Substituição de defines
     String processedLine = line;
     defines.forEach((key, value) {
        // Substituição simples (cuidado com substrings)
        // Ideal: usar regex com word boundary \b
        processedLine = processedLine.replaceAll(RegExp(r'\b' + key + r'\b'), value);
     });
     
     processedLines.add(processedLine);
  }
  
  return processedLines.join('\n');
}
