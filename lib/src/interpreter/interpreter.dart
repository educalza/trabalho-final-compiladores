import 'package:antlr4/antlr4.dart';
import '../generated/CSubsetBaseVisitor.dart';
import '../generated/CSubsetParser.dart';
import 'environment.dart';

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
  dynamic visitVarDecl(VarDeclContext ctx) {
    for (var declarator in ctx.varDeclarators()) {
      final name = declarator.ID()!.text!;
      if (declarator.INT() != null) {
        // Array
        final size = int.parse(declarator.INT()!.text!);
        environment.define(name, List<dynamic>.filled(size, null));
      } else {
        environment.define(name, null);
      }
    }
    return null;
  }

  @override
  dynamic visitAssignment(AssignmentContext ctx) {
    final name = ctx.ID()!.text!;
    
    if (ctx.LBRACKET() != null) {
       // Array assignment: ID [ expr ] = expr
       final index = visit(ctx.expression(0)!);
       final value = visit(ctx.expression(1)!);
       
       final array = environment.get(name);
       if (array is! List) throw Exception("Erro de Execução: '$name' não é um array.");
       
       if (index is! int) throw Exception("Erro de Execução: Índice deve ser inteiro.");
       if (index < 0 || index >= array.length) throw Exception("Erro de Execução: Índice fora dos limites.");
       
       array[index] = value;
       return value;
    }
    
    final value = visit(ctx.expression(0)!);
    
    // Verifica se é literal de array
    if (ctx.expression(0) is ArrayLiteralContext) {
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

    if (op == '*') return left * right;
    if (op == '/') return left / right;
    return null;
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
  dynamic visitWhileStmt(WhileStmtContext ctx) {
    while (true) {
      final condition = visit(ctx.expression()!);
      bool isTrue = false;
      if (condition is bool) isTrue = condition;
      if (condition is num) isTrue = condition != 0;

      if (!isTrue) break;
      visit(ctx.statement()!);
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
}
