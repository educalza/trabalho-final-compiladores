import 'package:antlr4/antlr4.dart';
import '../generated/CSubsetBaseVisitor.dart';
import '../generated/CSubsetParser.dart';
import 'symbol_table.dart';

class SemanticAnalyzer extends CSubsetBaseVisitor<CType> {
  Scope currentScope;

  SemanticAnalyzer() : currentScope = Scope() {
    // Define funções built-in se necessário (ex: print)
  }

  @override
  CType visitProgram(ProgramContext ctx) {
    // Visita todas as declarações no escopo global
    for (var decl in ctx.declarations()) {
      visit(decl);
    }
    return CType.voidType; // Retorno dummy para o programa
  }

  @override
  CType visitFunctionDecl(FunctionDeclContext ctx) {
    final typeName = ctx.typeSpecifier()!.text;
    final name = ctx.ID()!.text!;
    final returnType = _getTypeFromText(typeName);

    // Verifica se função já existe
    if (currentScope.resolve(name) != null) {
      throw Exception("Erro Semântico: Função '$name' já declarada.");
    }

    final functionSymbol = FunctionSymbol(name, returnType);
    currentScope.define(functionSymbol);

    // Cria novo escopo para a função
    final previousScope = currentScope;
    currentScope = Scope(previousScope);

    // Processa parâmetros
    final paramList = ctx.paramList();
    if (paramList != null) {
      for (var param in paramList.params()) {
        final paramType = _getTypeFromText(param.typeSpecifier()!.text);
        final paramName = param.ID()!.text!;
        
        final varSymbol = VarSymbol(paramName, paramType);
        currentScope.define(varSymbol);
        functionSymbol.parameters.add(varSymbol);
      }
    }

    // Visita o corpo da função
    visit(ctx.block()!);

    // Restaura escopo anterior
    currentScope = previousScope;

    return returnType;
  }

  @override
  CType visitVarDecl(VarDeclContext ctx) {
    final typeName = ctx.typeSpecifier()!.text;
    final type = _getTypeFromText(typeName);

    for (var declarator in ctx.varDeclarators()) {
      final name = declarator.ID()!.text!;
      if (currentScope.isDefinedLocally(name)) {
        throw Exception("Erro Semântico: Variável '$name' já declarada neste escopo.");
      }
      
      if (declarator.INT() != null) {
        // É um array
        final size = int.parse(declarator.INT()!.text!);
        currentScope.define(ArraySymbol(name, type, size));
      } else {
        // Variável normal
        currentScope.define(VarSymbol(name, type));
      }
    }
    return type;
  }

  @override
  CType visitBlock(BlockContext ctx) {
    // Blocos criam novo escopo (exceto se for corpo de função, que já tratamos, 
    // mas simplificando: podemos sempre criar escopo para blocos internos)
    // Nota: Na visitFunctionDecl já criamos o escopo dos parâmetros que serve para o bloco.
    // Se visitarmos o bloco diretamente de um if/while, precisamos de novo escopo.
    // Para simplificar, vamos assumir que functionDecl trata seu escopo e block trata escopos aninhados.
    // Mas cuidado para não criar escopo duplo na função.
    
    // Uma abordagem segura: O pai decide se cria escopo ou o bloco cria.
    // Vamos fazer o bloco SEMPRE criar escopo, exceto se o pai for função?
    // Melhor: O bloco sempre cria escopo. Na função, os parâmetros estão no escopo da função, 
    // e o corpo é um bloco que terá seu próprio escopo (filho do escopo da função).
    // Isso é válido em C? Sim, parâmetros são locais à função, variáveis do corpo também.
    
    final previousScope = currentScope;
    currentScope = Scope(previousScope);

    for (var stmt in ctx.statements()) {
      visit(stmt);
    }

    currentScope = previousScope;
    return CType.voidType;
  }

  @override
  CType visitAssignment(AssignmentContext ctx) {
    final name = ctx.ID()!.text!;
    final symbol = currentScope.resolve(name);

    if (symbol == null) {
      throw Exception("Erro Semântico: Variável '$name' não declarada.");
    }

    // Verifica se é atribuição de array
    if (ctx.LBRACKET() != null) { 
      // ID '[' expr ']' '=' expr 
      // ID '[' expr ']' '=' expr
      // ctx.expression(0) é o índice
      // ctx.expression(1) é o valor
      
      if (symbol is! ArraySymbol) {
        throw Exception("Erro Semântico: '$name' não é um array.");
      }
      
      final indexType = visit(ctx.expression(0)!) ?? CType.error;
      if (indexType != CType.int) {
        throw Exception("Erro Semântico: Índice de array deve ser inteiro.");
      }
      
      final valueType = visit(ctx.expression(1)!) ?? CType.error;
      if (!_areTypesCompatible(symbol.elementType, valueType)) {
         throw Exception("Erro Semântico: Atribuição incompatível para elemento de '$name'.");
      }
      return symbol.elementType;
    } else {
      // Atribuição normal: ID '=' expr
      final rightExpr = ctx.expression(0)!;
      
      // Verifica se é literal de array: ID = { ... }
      if (rightExpr is ArrayLiteralContext) {
         if (symbol is! ArraySymbol) {
           throw Exception("Erro Semântico: Não é possível atribuir uma lista a uma variável não-array.");
         }
         
         // Valida tipos dos elementos do literal
         final elementType = visit(rightExpr) ?? CType.error;
         if (!_areTypesCompatible(symbol.elementType, elementType)) {
            throw Exception("Erro Semântico: Tipos dos elementos da lista incompatíveis com array '$name'.");
         }
         
         // Valida tamanho
         final literalSize = rightExpr.expressions().length;
         if (literalSize > symbol.size) {
            throw Exception("Erro Semântico: Tamanho da lista ($literalSize) maior que o array '$name' (${symbol.size}).");
         }
         
         return symbol.elementType;
      }
      
      if (symbol is ArraySymbol) {
        throw Exception("Erro Semântico: Não é possível atribuir a um array inteiro (use índice ou lista {...}).");
      }
      // ... resto da lógica normal ...
    }

    if (symbol == null) {
      throw Exception("Erro Semântico: Variável '$name' não declarada.");
    }
    if (symbol is! VarSymbol) {
      throw Exception("Erro Semântico: '$name' não é uma variável.");
    }

    final exprType = visit(ctx.expression(0)!) ?? CType.error;
    
    if (!_areTypesCompatible(symbol.type, exprType)) {
      throw Exception("Erro Semântico: Atribuição incompatível para '$name'. Esperado ${symbol.type}, recebido $exprType.");
    }

    return symbol.type;
  }

  @override
  CType visitArrayLiteral(ArrayLiteralContext ctx) {
    CType? firstType;
    for (var expr in ctx.expressions()) {
      final type = visit(expr) ?? CType.error;
      if (firstType == null) {
        firstType = type;
      } else {
        if (!_areTypesCompatible(firstType, type)) {
           // Tenta promover
           if (_areTypesCompatible(firstType, type)) {
              // ok
           } else if (_areTypesCompatible(type, firstType)) {
              firstType = type; // Upgrade (ex: int -> float)
           } else {
              throw Exception("Erro Semântico: Elementos da lista devem ter o mesmo tipo.");
           }
        }
      }
    }
    return firstType ?? CType.voidType; // Lista vazia?
  }

  @override
  CType visitIntExpr(IntExprContext ctx) {
    return CType.int;
  }



  @override
  CType visitFloatExpr(FloatExprContext ctx) {
    return CType.float;
  }

  @override
  CType visitStringExpr(StringExprContext ctx) {
    return CType.string;
  }

  @override
  CType visitIdExpr(IdExprContext ctx) {
    final name = ctx.ID()!.text!;
    final symbol = currentScope.resolve(name);
    if (symbol == null) {
      throw Exception("Erro Semântico: Variável '$name' não declarada.");
    }
    return symbol.type;
  }

  @override
  CType visitAddSubExpr(AddSubExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    return _getResultingType(left, right);
  }

  @override
  CType visitMulDivExpr(MulDivExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    return _getResultingType(left, right);
  }

  CType _getTypeFromText(String text) {
    switch (text) {
      case 'int': return CType.int;
      case 'float': return CType.float;
      case 'char': return CType.char;
      case 'void': return CType.voidType;
      case 'string': return CType.string;
      default: return CType.error;
    }
  }

  bool _areTypesCompatible(CType target, CType value) {
    if (target == value) return true;
    if (target == CType.float && value == CType.int) return true; // Promoção
    return false;
  }

  CType _getResultingType(CType t1, CType t2) {
    if (t1 == CType.float || t2 == CType.float) return CType.float;
    if (t1 == CType.int && t2 == CType.int) return CType.int;
    if (t1 == CType.string && t2 == CType.string) return CType.string; // Concatenação
    return CType.error;
  }
}
