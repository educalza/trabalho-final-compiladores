import 'package:test/test.dart';
import 'package:antlr4/antlr4.dart';
import 'package:c_processor/c_processor.dart';

void main() {
  // Função auxiliar para processar código fonte
  void processCode(String code) {
    final input = InputStream.fromString(code);
    final lexer = CSubsetLexer(input);
    final tokens = CommonTokenStream(lexer);
    final parser = CSubsetParser(tokens);
    
    // Adiciona listener de erro para falhar o teste em erro de sintaxe
    parser.removeErrorListeners();
    parser.addErrorListener(DiagnosticErrorListener());

    final tree = parser.program();
    
    if (parser.numberOfSyntaxErrors > 0) {
      throw Exception("Erro de sintaxe detectado");
    }

    final semanticAnalyzer = SemanticAnalyzer();
    semanticAnalyzer.visit(tree);
  }

  group('Análise Sintática e Semântica Básica', () {
    test('Deve aceitar declaração de variáveis globais', () {
      final code = 'int a; float b; char c;';
      expect(() => processCode(code), returnsNormally);
    });

    test('Deve aceitar função main vazia', () {
      final code = 'void main() {}';
      expect(() => processCode(code), returnsNormally);
    });

    test('Deve aceitar atribuições válidas', () {
      final code = '''
        void main() {
          int a;
          a = 10;
        }
      ''';
      expect(() => processCode(code), returnsNormally);
    });

    test('Deve aceitar estruturas de controle', () {
      final code = '''
        void main() {
          int a;
          a = 0;
          if (a < 10) {
            a = a + 1;
          }
          while (a > 0) {
            a = a - 1;
          }
        }
      ''';
      expect(() => processCode(code), returnsNormally);
    });
  });

  group('Erros Semânticos', () {
    test('Deve rejeitar variável não declarada', () {
      final code = '''
        void main() {
          a = 10;
        }
      ''';
      expect(() => processCode(code), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("Variável 'a' não declarada"))));
    });

    test('Deve rejeitar redeclaração de variável no mesmo escopo', () {
      final code = '''
        void main() {
          int a;
          int a;
        }
      ''';
      expect(() => processCode(code), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("Variável 'a' já declarada"))));
    });

    test('Deve rejeitar atribuição de tipos incompatíveis (int = float)', () {
      // Nota: Nossa regra diz que int = float pode ser erro ou warning. Implementamos como erro?
      // Vamos verificar a implementação: _areTypesCompatible(int, float) -> false.
      final code = '''
        void main() {
          int a;
          float b;
          b = 1.5;
          a = b; 
        }
      ''';
      expect(() => processCode(code), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("Atribuição incompatível"))));
    });
    
    test('Deve aceitar promoção de tipo (float = int)', () {
      final code = '''
        void main() {
          float a;
          int b;
          b = 10;
          a = b;
        }
      ''';
      expect(() => processCode(code), returnsNormally);
    });
  });
  
  group('Escopo', () {
    test('Deve permitir shadowing (variável local ocultando global)', () {
      final code = '''
        int a;
        void main() {
          int a;
          a = 10; 
        }
      ''';
      expect(() => processCode(code), returnsNormally);
    });

    test('Variável local não deve ser visível fora do escopo', () {
      final code = '''
        void main() {
          if (1) {
            int a;
          }
          a = 10;
        }
      ''';
      // O analisador atual trata blocos como escopos? Sim, visitBlock cria escopo.
      expect(() => processCode(code), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("Variável 'a' não declarada"))));
    });
  });
}
