import 'dart:io';
import 'package:antlr4/antlr4.dart';
import '../generated/CSubsetBaseVisitor.dart';
import '../generated/CSubsetParser.dart';
import 'environment.dart';

class BreakException implements Exception {}

class ReturnException implements Exception {
  final dynamic value;
  ReturnException(this.value);
}

class Interpreter extends CSubsetBaseVisitor<dynamic> {
  Environment environment;

  Interpreter() : environment = Environment();

  @override
  dynamic visitProgram(ProgramContext ctx) {
    for (var decl in ctx.declarations()) {
      visit(decl);
    }
    return null;
  }

  @override
  dynamic visitFunctionCall(FunctionCallContext ctx) {
    final name = ctx.ID()!.text!;
    
    if (name == 'print') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length != 1) {
          throw Exception("Erro de Execução: 'print' espera exatamente 1 argumento.");
       }
       final arg = visit(ctx.argList()!.expression(0)!);
       print(arg);
       return null;
    }
    
    if (name == 'puts') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length != 1) {
          throw Exception("Erro de Execução: 'puts' espera exatamente 1 argumento.");
       }
       final arg = visit(ctx.argList()!.expression(0)!);
       print(arg);
       return null;
    }

    if (name == 'gets') {
       if (ctx.argList() != null && ctx.argList()!.expressions().isNotEmpty) {
          throw Exception("Erro de Execução: 'gets' não aceita argumentos.");
       }
       return stdin.readLineSync() ?? "";
    }
    
    if (name == 'printf') {
       final format = visit(ctx.argList()!.expression(0)!) as String;
       final args = <dynamic>[];
       for (int i = 1; i < ctx.argList()!.expressions().length; i++) {
          args.add(visit(ctx.argList()!.expression(i)!));
       }
       
       String output = format;
       int argIndex = 0;
       output = output.replaceAllMapped(RegExp(r'%[dfs]'), (match) {
          if (argIndex < args.length) {
             return args[argIndex++].toString();
          }
          return match.group(0)!;
       });
       output = output.replaceAll(r'\n', '\n');
       stdout.write(output);
       return null;
    }
    
    if (name == 'scanf') {
       final format = visit(ctx.argList()!.expression(0)!) as String;
       final varExpr = ctx.argList()!.expression(1)! as IdExprContext;
       final varName = varExpr.ID()!.text!;
       final input = stdin.readLineSync() ?? "";
       dynamic value;
       if (format.contains("%d")) {
          value = int.tryParse(input) ?? 0;
       } else if (format.contains("%f")) {
          value = double.tryParse(input) ?? 0.0;
       } else {
          value = input;
       }
       environment.assign(varName, value);
       return null;
    }
    
    if (name == 'stoi') {
       final str = visit(ctx.argList()!.expression(0)!) as String;
       return int.tryParse(str) ?? 0;
    }
    
    if (name == 'stof') {
       final str = visit(ctx.argList()!.expression(0)!) as String;
       return double.tryParse(str) ?? 0.0;
    }
    
    // Recupera a função do ambiente
    final function = environment.get(name);
    if (function == null) {
       throw Exception("Erro de Execução: Função '$name' não definida.");
    }
    
    if (function is FunctionDeclContext) {
       final previousEnv = environment;
       environment = Environment(previousEnv);
       
       try {
          final paramList = (function as FunctionDeclContext).paramList();
          if (paramList != null) {
             final params = paramList.params();
             final args = ctx.argList()?.expressions() ?? [];
             
             if (params.length != args.length) {
                throw Exception("Erro de Execução: Número incorreto de argumentos para '$name'. Esperado ${params.length}, recebido ${args.length}.");
             }
             
             for (int i = 0; i < params.length; i++) {
                final paramName = params[i].ID()!.text!;
                final argValue = visit(args[i]);
                environment.define(paramName, argValue);
             }
          }
          
          visit((function as dynamic).block()!);
          
       } catch (e) {
          if (e is ReturnException) {
             return e.value;
          }
          rethrow;
       } finally {
          environment = previousEnv;
       }
       return null;
    }
    
    throw Exception("Erro de Execução: '$name' não é uma função.");
  }

  @override
  dynamic visitFunctionDecl(FunctionDeclContext ctx) {
     final name = ctx.ID()!.text!;
     // Armazena a definição da função no ambiente atual (global)
     environment.define(name, ctx);
     return null;
  }

  @override
  dynamic visitStructDecl(StructDeclContext ctx) {
     final name = ctx.ID()!.text!;
     environment.define(name, ctx);
     return null;
  }

  @override
  dynamic visitUnionDecl(UnionDeclContext ctx) {
     final name = ctx.ID()!.text!;
     environment.define(name, ctx);
     return null;
  }

  @override
  dynamic visitVarDecl(VarDeclContext ctx) {
    final typeSpec = ctx.typeSpecifier()!;
    String? structOrUnionName;
    bool isStruct = false;
    bool isUnion = false;
    
    if (typeSpec is StructTypeContext) {
       structOrUnionName = typeSpec.ID()!.text!;
       isStruct = true;
    } else if (typeSpec is UnionTypeContext) {
       structOrUnionName = typeSpec.ID()!.text!;
       isUnion = true;
    }

    for (var declarator in ctx.varDeclarators()) {
      final name = declarator.ID()!.text!;
      
      dynamic initialValue;
      if (declarator.expression() != null) {
         initialValue = visit(declarator.expression()!);
      }
      
      if (declarator.INT() != null) {
        // Array
        final size = int.parse(declarator.INT()!.text!);
        final array = List<dynamic>.filled(size, null);
        
        if (initialValue != null) {
           if (initialValue is List) {
              for (int i = 0; i < initialValue.length; i++) {
                 if (i < size) array[i] = initialValue[i];
              }
           }
        }
        environment.define(name, array);
      } else {
        // Variável normal (pode ser struct/union)
        if (isStruct || isUnion) {
           // Instancia struct/union
           final typeDef = environment.get(structOrUnionName!);
           if (typeDef == null) throw Exception("Erro de Execução: Tipo '$structOrUnionName' não definido.");
           
           final instance = <String, dynamic>{};
           
           // Popula campos com null
           List<VarDeclContext> fields = [];
           if (isStruct && typeDef is StructDeclContext) {
              fields = typeDef.varDecls();
           } else if (isUnion && typeDef is UnionDeclContext) {
              fields = typeDef.varDecls();
           } else {
              throw Exception("Erro de Execução: Definição de '$structOrUnionName' inválida.");
           }
           
           for (var fieldDecl in fields) {
              for (var fieldDeclarator in fieldDecl.varDeclarators()) {
                 instance[fieldDeclarator.ID()!.text!] = null;
              }
           }
           
           // Se for union, talvez precise de lógica especial, mas Map resolve por enquanto (todos compartilham memória? Não em Dart Map. 
           // Para simular union, deveríamos ter apenas UM valor ativo. Mas para simplificar, vamos usar Map e permitir todos.
           // O comportamento de "corromper" outros campos não será simulado aqui.)
           
           environment.define(name, instance);
        } else {
           environment.define(name, initialValue);
        }
      }
    }
    return null;
  }
  
  @override
  dynamic visitMemberAccessExpr(MemberAccessExprContext ctx) {
     final left = visit(ctx.expression()!);
     final member = ctx.ID()!.text!;
     
     if (left is Map) {
        if (!left.containsKey(member)) {
           throw Exception("Erro de Execução: Membro '$member' não encontrado.");
        }
        return left[member];
     }
     throw Exception("Erro de Execução: Acesso a membro em algo que não é struct/union.");
  }
  
  @override
  dynamic visitExprStatement(ExprStatementContext ctx) {
    return visit(ctx.expression()!);
  }

  @override
  dynamic visitAssignExpr(AssignExprContext ctx) {
    final leftExpr = ctx.expression(0)!;
    final rightExpr = ctx.expression(1)!;
    
    final value = visit(rightExpr);
    
    if (leftExpr is IdExprContext) {
       final name = leftExpr.ID()!.text!;
       
       // Verifica se é literal de array
       if (rightExpr is ArrayLiteralContext) {
          final array = environment.get(name);
          if (array is! List) throw Exception("Erro de Execução: '$name' não é um array.");
          
          final listValues = value as List;
          for (int i = 0; i < listValues.length; i++) {
             if (i < array.length) {
                array[i] = listValues[i];
             }
          }
          return value;
       }
       
       environment.assign(name, value);
       return value;
       
    } else if (leftExpr is ArrayAccessExprContext) {
       // ... (código existente)
       final arrayExpr = leftExpr.expression(0)!; // ID
       if (arrayExpr is! IdExprContext) throw Exception("Acesso complexo não suportado.");
       
       final name = (arrayExpr as IdExprContext).ID()!.text!;
       final array = environment.get(name);
       if (array is! List) throw Exception("Erro de Execução: '$name' não é um array.");
       
       final index = visit(leftExpr.expression(1)!);
       if (index is! int) throw Exception("Erro de Execução: Índice deve ser inteiro.");
       if (index < 0 || index >= array.length) throw Exception("Erro de Execução: Índice fora dos limites.");
       
       array[index] = value;
       return value;
       
    } else if (leftExpr is MemberAccessExprContext) {
       // Atribuição a membro: p.x = 10
       final objectExpr = leftExpr.expression()!;
       final member = leftExpr.ID()!.text!;
       
       final object = visit(objectExpr);
       if (object is! Map) throw Exception("Erro de Execução: Atribuição a membro de não-struct.");
       
       if (!object.containsKey(member)) {
          throw Exception("Erro de Execução: Membro '$member' não existe.");
       }
       
       object[member] = value;
       return value;
       
    } else {
       throw Exception("Erro de Execução: Lado esquerdo inválido para atribuição.");
    }
  }

  @override
  dynamic visitArrayLiteral(ArrayLiteralContext ctx) {
    final list = <dynamic>[];
    for (var expr in ctx.expressions()) {
      list.add(visit(expr));
    }
    return list;
  }

  @override
  dynamic visitArrayAccessExpr(ArrayAccessExprContext ctx) {
    final leftExpr = ctx.expression(0)!;
    // Simplificação: assume ID
    if (leftExpr is! IdExprContext) throw Exception("Acesso complexo não suportado.");
    
    final name = (leftExpr as IdExprContext).ID()!.text!;
    final array = environment.get(name);
    
    if (array is! List) throw Exception("Erro de Execução: '$name' não é um array.");
    
    final index = visit(ctx.expression(1)!);
    if (index is! int) throw Exception("Erro de Execução: Índice deve ser inteiro.");
    if (index < 0 || index >= array.length) throw Exception("Erro de Execução: Índice fora dos limites.");
    
    return array[index];
  }

  @override
  dynamic visitIdExpr(IdExprContext ctx) {
    return environment.get(ctx.ID()!.text!);
  }

  @override
  dynamic visitIntExpr(IntExprContext ctx) {
    return int.parse(ctx.INT()!.text!);
  }



  @override
  dynamic visitFloatExpr(FloatExprContext ctx) {
    return double.parse(ctx.FLOAT()!.text!);
  }

  @override
  dynamic visitStringExpr(StringExprContext ctx) {
    final text = ctx.STRING()!.text!;
    // Remove as aspas do início e fim
    return text.substring(1, text.length - 1);
  }

  @override
  dynamic visitAddSubExpr(AddSubExprContext ctx) {
    final left = visit(ctx.expression(0)!);
    final right = visit(ctx.expression(1)!);
    final op = ctx.op!.text!;

    if (op == '+') {
      // Concatenação de strings se um dos operandos for string
      if (left is String || right is String) {
        return left.toString() + right.toString();
      }
      return left + right;
    }
    if (op == '-') return left - right;
    return null;
  }

  @override
  dynamic visitMulDivExpr(MulDivExprContext ctx) {
    final left = visit(ctx.expression(0)!);
    final right = visit(ctx.expression(1)!);
    final op = ctx.op!.text!;

    if (left == null || right == null) {
       throw Exception("Erro de Execução: Operando nulo em operação '$op'.");
    }

    if (op == '*') return left * right;
    if (op == '/') return left / right;
    if (op == '%') return (left as num).toInt() % (right as num).toInt();
    return null;
  }

  @override
  dynamic visitParenExpr(ParenExprContext ctx) {
    return visit(ctx.expression()!);
  }


  @override
  dynamic visitLogicAndExpr(LogicAndExprContext ctx) {
    // Short-circuit
    final left = visit(ctx.expression(0)!);
    bool leftTrue = false;
    if (left is bool) leftTrue = left;
    if (left is num) leftTrue = left != 0;
    
    if (!leftTrue) return 0; // Falso
    
    final right = visit(ctx.expression(1)!);
    bool rightTrue = false;
    if (right is bool) rightTrue = right;
    if (right is num) rightTrue = right != 0;
    
    return rightTrue ? 1 : 0;
  }

  @override
  dynamic visitLogicOrExpr(LogicOrExprContext ctx) {
    // Short-circuit
    final left = visit(ctx.expression(0)!);
    bool leftTrue = false;
    if (left is bool) leftTrue = left;
    if (left is num) leftTrue = left != 0;
    
    if (leftTrue) return 1; // Verdadeiro
    
    final right = visit(ctx.expression(1)!);
    bool rightTrue = false;
    if (right is bool) rightTrue = right;
    if (right is num) rightTrue = right != 0;
    
    return rightTrue ? 1 : 0;
  }

  @override
  dynamic visitBlock(BlockContext ctx) {
    final previous = environment;
    environment = Environment(previous);
    try {
      for (var stmt in ctx.statements()) {
        visit(stmt);
      }
    } finally {
      environment = previous;
    }
    return null;
  }

  @override
  dynamic visitIfStmt(IfStmtContext ctx) {
    final condition = visit(ctx.expression()!);
    // Em C, 0 é falso, qualquer outra coisa é verdadeiro.
    // Aqui vamos assumir que comparações retornam bool ou int.
    bool isTrue = false;
    if (condition is bool) isTrue = condition;
    if (condition is num) isTrue = condition != 0;

    if (isTrue) {
      visit(ctx.statement(0)!);
    } else if (ctx.statement(1) != null) {
      visit(ctx.statement(1)!);
    }
    return null;
  }


  
  @override
  dynamic visitSwitchStmt(SwitchStmtContext ctx) {
    final value = visit(ctx.expression()!);
    
    // Simplificação: iterar sobre os filhos do bloco e encontrar o case correto
    // Isso é ineficiente mas funciona para AST visitor simples.
    // Melhor: encontrar o índice do filho onde começar a executar.
    
    final block = ctx.switchBlock()!;
    int startIndex = -1;
    bool foundDefault = false;
    int defaultIndex = -1;
    
    // 1. Encontrar o case correspondente
    for (int i = 0; i < block.childCount; i++) {
       final child = block.getChild(i);
       if (child is CaseStmtContext) {
          final caseValue = visit(child.expression()!);
          if (caseValue == value) {
             startIndex = i;
             break;
          }
       } else if (child is DefaultStmtContext) {
          foundDefault = true;
          defaultIndex = i;
       }
    }
    
    if (startIndex == -1 && foundDefault) {
       startIndex = defaultIndex;
    }
    
    if (startIndex != -1) {
       try {
          // Executar a partir do case encontrado (fall-through)
          for (int i = startIndex; i < block.childCount; i++) {
             final child = block.getChild(i);
             if (child is! CaseStmtContext && child is! DefaultStmtContext) {
                // É um statement
                visit(child!);
             }
          }
       } catch (e) {
          if (e is BreakException) {
             // Saiu do switch
             return null;
          }
          rethrow;
       }
    }
    
    return null;
  }
  
  @override
  dynamic visitForStmt(ForStmtContext ctx) {
    final previous = environment;
    environment = Environment(previous);
    
    try {
       // Init
       if (ctx.varDecl() != null) {
          visit(ctx.varDecl()!);
       } else {
          // Init expression
          // Verifica se o primeiro ';' vem depois de uma expressão
          // Se child(2) for ';', então NÃO tem init expression (FOR '(' ';')
          if (ctx.getChild(2)?.text != ';') {
             // Tem init expression. É a primeira da lista.
             if (ctx.expressions().isNotEmpty) {
                visit(ctx.expressions()[0]);
             }
          }
       }
       
       while (true) {
          // Condition
          // Precisamos encontrar a expressão de condição.
          // Ela está entre o primeiro e o segundo ';'.
          ExpressionContext? condExpr;
          ExpressionContext? updateExpr;
          
          int semiCount = ctx.varDecl() != null ? 1 : 0;
          
          // Varre filhos para achar condition e update
          for (var child in ctx.children!) {
             if (child.text == ';') {
                semiCount++;
             } else if (child is ExpressionContext) {
                if (semiCount == 1) {
                   condExpr = child;
                } else if (semiCount == 2) {
                   updateExpr = child;
                }
             }
          }
          
          if (condExpr != null) {
             final condition = visit(condExpr);
             bool isTrue = false;
             if (condition is bool) isTrue = condition;
             if (condition is num) isTrue = condition != 0;
             if (!isTrue) break;
          }
          
          try {
             visit(ctx.statement()!);
          } catch (e) {
             if (e is BreakException) break;
             rethrow;
          }
          
          if (updateExpr != null) {
             visit(updateExpr);
          }
       }
       
    } finally {
       environment = previous;
    }
    return null;
  }
  
  @override
  dynamic visitReturnStmt(ReturnStmtContext ctx) {
    dynamic value;
    if (ctx.expression() != null) {
       value = visit(ctx.expression()!);
    }
    throw ReturnException(value);
  }

  @override
  dynamic visitBreakStmt(BreakStmtContext ctx) {
     throw BreakException();
  }
  
  @override
  dynamic visitWhileStmt(WhileStmtContext ctx) {
    while (true) {
      final condition = visit(ctx.expression()!);
      bool isTrue = false;
      if (condition is bool) isTrue = condition;
      if (condition is num) isTrue = condition != 0;

      if (!isTrue) break;
      
      try {
        visit(ctx.statement()!);
      } catch (e) {
         if (e is BreakException) break;
         rethrow;
      }
    }
    return null;
  }
  
  // Implementar comparações para if/while funcionar
  @override
  dynamic visitRelExpr(RelExprContext ctx) {
    final left = visit(ctx.expression(0)!);
    final right = visit(ctx.expression(1)!);
    final op = ctx.op!.text!;
    
    switch(op) {
      case '<': return left < right;
      case '>': return left > right;
      case '<=': return left <= right;
      case '>=': return left >= right;
      default: return false;
    }
  }
  
  @override
  dynamic visitEqExpr(EqExprContext ctx) {
    final left = visit(ctx.expression(0)!);
    final right = visit(ctx.expression(1)!);
    final op = ctx.op!.text!;
    
    if (op == '==') return left == right;
    if (op == '!=') return left != right;
    return false;
  }

  @override
  dynamic visitDoWhileStmt(DoWhileStmtContext ctx) {
    while (true) {
       try {
          visit(ctx.statement()!);
       } catch (e) {
          if (e is BreakException) break;
          rethrow;
       }
       
       final condition = visit(ctx.expression()!);
       bool isTrue = false;
       if (condition is bool) isTrue = condition;
       if (condition is num) isTrue = condition != 0;
       
       if (!isTrue) break;
    }
    return null;
  }
}
