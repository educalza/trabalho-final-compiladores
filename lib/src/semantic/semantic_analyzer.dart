import 'package:antlr4/antlr4.dart';
import '../generated/CSubsetBaseVisitor.dart';
import '../generated/CSubsetParser.dart';
import 'symbol_table.dart';

class SemanticAnalyzer extends CSubsetBaseVisitor<CType> {
  Scope currentScope;
  CType? _currentFunctionReturnType;
  int _loopOrSwitchDepth = 0;

  SemanticAnalyzer() : currentScope = Scope() {
    final printSymbol = FunctionSymbol('print', CType.voidType);
    printSymbol.parameters.add(VarSymbol('arg', CType.string));
    currentScope.define(printSymbol);
    
    final printfSymbol = FunctionSymbol('printf', CType.voidType);
    printfSymbol.parameters.add(VarSymbol('format', CType.string));
    currentScope.define(printfSymbol);
    
    final scanfSymbol = FunctionSymbol('scanf', CType.voidType);
    scanfSymbol.parameters.add(VarSymbol('format', CType.string));
    currentScope.define(scanfSymbol);
    
    final stoiSymbol = FunctionSymbol('stoi', CType.int);
    stoiSymbol.parameters.add(VarSymbol('s', CType.string));
    currentScope.define(stoiSymbol);
    
    final stofSymbol = FunctionSymbol('stof', CType.float);
    stofSymbol.parameters.add(VarSymbol('s', CType.string));
    currentScope.define(stofSymbol);
    
    final putsSymbol = FunctionSymbol('puts', CType.voidType);
    putsSymbol.parameters.add(VarSymbol('s', CType.string));
    currentScope.define(putsSymbol);

    final getsSymbol = FunctionSymbol('gets', CType.string);
    currentScope.define(getsSymbol);
  }

  @override
  CType visitProgram(ProgramContext ctx) {
    for (var decl in ctx.declarations()) {
      visit(decl);
    }
    return CType.voidType;
  }

  @override
  CType visitFunctionDecl(FunctionDeclContext ctx) {
    final typeName = ctx.typeSpecifier()!.text;
    final name = ctx.ID()!.text!;
    final returnType = _getTypeFromText(typeName);

    if (currentScope.resolve(name) != null) {
      throw Exception("Erro Semântico: Função '$name' já declarada.");
    }

    final functionSymbol = FunctionSymbol(name, returnType);
    currentScope.define(functionSymbol);

    final previousScope = currentScope;
    currentScope = Scope(previousScope);

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

    final previousReturnType = _currentFunctionReturnType;
    _currentFunctionReturnType = returnType;
    
    visit((ctx as dynamic).block()!);
    
    _currentFunctionReturnType = previousReturnType;

    currentScope = previousScope;

    return returnType;
  }

  @override
  CType visitStructDecl(StructDeclContext ctx) {
    final name = ctx.ID()!.text!;
    if (currentScope.resolve(name) != null) {
       throw Exception("Erro Semântico: Struct '$name' já declarada.");
    }
    
    final structSymbol = StructSymbol(name);
    currentScope.define(structSymbol);
    
    final memberScope = Scope(currentScope);
    final previousScope = currentScope;
    currentScope = memberScope;
    
    try {
       for (var decl in ctx.varDecls()) {
          visit(decl);
       }
    } finally {
       currentScope = previousScope;
    }
    
    memberScope.symbols.forEach((memberName, symbol) {
       if (symbol is VarSymbol) {
          structSymbol.defineMember(symbol);
       }
    });
    
    return CType.voidType;
  }

  @override
  CType visitUnionDecl(UnionDeclContext ctx) {
    final name = ctx.ID()!.text!;
    if (currentScope.resolve(name) != null) {
       throw Exception("Erro Semântico: Union '$name' já declarada.");
    }
    
    final unionSymbol = UnionSymbol(name);
    currentScope.define(unionSymbol);
    
    final memberScope = Scope(currentScope);
    final previousScope = currentScope;
    currentScope = memberScope;
    
    try {
       for (var decl in ctx.varDecls()) {
          visit(decl);
       }
    } finally {
       currentScope = previousScope;
    }
    
    memberScope.symbols.forEach((memberName, symbol) {
       if (symbol is VarSymbol) {
          unionSymbol.defineMember(symbol);
       }
    });
    
    return CType.voidType;
  }

  @override
  CType visitMemberAccessExpr(MemberAccessExprContext ctx) {
     final leftExpr = ctx.expression()!;
     final memberName = ctx.ID()!.text!;
     
     if (leftExpr is IdExprContext) {
        final varName = leftExpr.ID()!.text!;
        final symbol = currentScope.resolve(varName);
        
        if (symbol == null) throw Exception("Erro Semântico: '$varName' não declarado.");
        if (symbol is! VarSymbol) throw Exception("Erro Semântico: '$varName' não é variável.");
        
        if (symbol.type != CType.structType && symbol.type != CType.unionType) {
           throw Exception("Erro Semântico: '$varName' não é struct nem union.");
        }
        
        final typeName = symbol.typeName!;
        final typeSymbol = currentScope.resolve(typeName);
        
        if (typeSymbol == null) throw Exception("Erro Semântico: Tipo '$typeName' não definido.");
        
        VarSymbol? member;
        if (typeSymbol is StructSymbol) {
           member = typeSymbol.resolveMember(memberName);
        } else if (typeSymbol is UnionSymbol) {
           member = typeSymbol.resolveMember(memberName);
        }
        
        if (member == null) {
           throw Exception("Erro Semântico: Membro '$memberName' não existe em '$typeName'.");
        }
        
        return member.type;
     }
     
     throw Exception("Erro Semântico: Acesso a membro suportado apenas em variáveis diretas (ex: p.x).");
  }

  CType _getTypeFromContext(TypeSpecifierContext ctx) {
    if (ctx is StructTypeContext) return CType.structType;
    if (ctx is UnionTypeContext) return CType.unionType;
    return _getTypeFromText(ctx.text);
  }

  @override
  CType visitVarDecl(VarDeclContext ctx) {
    final typeCtx = ctx.typeSpecifier()!;
    final type = _getTypeFromContext(typeCtx);
    String? typeName;
    
    if (type == CType.structType || type == CType.unionType) {
       if (typeCtx is StructTypeContext) {
          typeName = typeCtx.ID()!.text!;
       } else if (typeCtx is UnionTypeContext) {
          typeName = typeCtx.ID()!.text!;
       } else {
          throw Exception("Erro Interno: Contexto de tipo inválido para struct/union.");
       }
       
       final typeSymbol = currentScope.resolve(typeName!);
       if (typeSymbol == null) {
          throw Exception("Erro Semântico: Tipo '$typeName' não definido.");
       }
       if (type == CType.structType && typeSymbol is! StructSymbol) {
          throw Exception("Erro Semântico: '$typeName' não é uma struct.");
       }
       if (type == CType.unionType && typeSymbol is! UnionSymbol) {
          throw Exception("Erro Semântico: '$typeName' não é uma union.");
       }
    }

    for (var declarator in ctx.varDeclarators()) {
      final name = declarator.ID()!.text!;
      if (currentScope.isDefinedLocally(name)) {
        throw Exception("Erro Semântico: Variável '$name' já declarada neste escopo.");
      }
      
      Symbol symbol;
      if (declarator.INT() != null) {
        final size = int.parse(declarator.INT()!.text!);
        symbol = ArraySymbol(name, type, size);
        currentScope.define(symbol);
      } else {
        symbol = VarSymbol(name, type, typeName: typeName);
        currentScope.define(symbol);
      }
      
      if (declarator.expression() != null) {
         if (type == CType.structType || type == CType.unionType) {
            throw Exception("Erro Semântico: Inicialização de struct/union na declaração não suportada ainda.");
         }
         final initExpr = declarator.expression()!;
         if (symbol is ArraySymbol) {
            if (initExpr is! ArrayLiteralContext) {
               throw Exception("Erro Semântico: Array '$name' deve ser inicializado com lista {...}.");
            }
            
            final literalSize = initExpr.expressions().length;
            if (literalSize > symbol.size) {
               throw Exception("Erro Semântico: Tamanho da lista ($literalSize) maior que o array '$name' (${symbol.size}).");
            }
            
            final elementType = visit(initExpr) ?? CType.error;
            if (!_areTypesCompatible(symbol.elementType, elementType)) {
               throw Exception("Erro Semântico: Tipos incompatíveis na inicialização do array '$name'.");
            }
            
         } else {
            final initType = visit(initExpr) ?? CType.error;
            if (!_areTypesCompatible(type, initType)) {
               throw Exception("Erro Semântico: Inicialização incompatível para '$name'.");
            }
         }
      }
    }
    return type;
  }

  @override
  CType visitFunctionCall(FunctionCallContext ctx) {
    final name = ctx.ID()!.text!;
    
    if (name == 'print') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length != 1) {
          throw Exception("Erro Semântico: 'print' espera exatamente 1 argumento.");
       }
       visit(ctx.argList()!.expression(0)!);
       return CType.voidType;
    }
    
    if (name == 'puts') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length != 1) {
          throw Exception("Erro Semântico: 'puts' espera exatamente 1 argumento.");
       }
       final argType = visit(ctx.argList()!.expression(0)!);
       if (argType != CType.string) {
          throw Exception("Erro Semântico: 'puts' espera uma string.");
       }
       return CType.voidType;
    }
    
    if (name == 'gets') {
       if (ctx.argList() != null && ctx.argList()!.expressions().isNotEmpty) {
          throw Exception("Erro Semântico: 'gets' não aceita argumentos.");
       }
       return CType.string;
    }
    
    if (name == 'printf') {
       if (ctx.argList() == null || ctx.argList()!.expressions().isEmpty) {
          throw Exception("Erro Semântico: 'printf' requer pelo menos 1 argumento (formato).");
       }
       final formatType = visit(ctx.argList()!.expression(0)!);
       if (formatType != CType.string) {
          throw Exception("Erro Semântico: Primeiro argumento de 'printf' deve ser string.");
       }
       for (int i = 1; i < ctx.argList()!.expressions().length; i++) {
          visit(ctx.argList()!.expression(i)!);
       }
       return CType.voidType;
    }
    
    if (name == 'scanf') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length < 2) {
          throw Exception("Erro Semântico: 'scanf' requer pelo menos 2 argumentos (formato e variável).");
       }
       final formatType = visit(ctx.argList()!.expression(0)!);
       if (formatType != CType.string) {
          throw Exception("Erro Semântico: Primeiro argumento de 'scanf' deve ser string.");
       }
       
       final varExpr = ctx.argList()!.expression(1)!;
       if (varExpr is! IdExprContext) {
          throw Exception("Erro Semântico: Segundo argumento de 'scanf' deve ser uma variável.");
       }
       
       visit(varExpr);
       
       return CType.voidType;
    }
    
    if (name == 'stoi' || name == 'stof') {
       if (ctx.argList() == null || ctx.argList()!.expressions().length != 1) {
          throw Exception("Erro Semântico: '$name' espera exatamente 1 argumento.");
       }
       final argType = visit(ctx.argList()!.expression(0)!);
       if (argType != CType.string) {
          throw Exception("Erro Semântico: '$name' espera string.");
       }
       return name == 'stoi' ? CType.int : CType.float;
    }

    final symbol = currentScope.resolve(name);
    if (symbol == null) {
      throw Exception("Erro Semântico: Função '$name' não declarada.");
    }
    if (symbol is! FunctionSymbol) {
      throw Exception("Erro Semântico: '$name' não é uma função.");
    }
    
    final params = symbol.parameters;
    final args = ctx.argList()?.expressions() ?? [];
    
    if (params.length != args.length) {
       throw Exception("Erro Semântico: Função '$name' espera ${params.length} argumentos, mas recebeu ${args.length}.");
    }
    
    for (int i = 0; i < params.length; i++) {
       final argType = visit(args[i]) ?? CType.error;
       final paramType = params[i].type;
       
       if (!_areTypesCompatible(paramType, argType)) {
          throw Exception("Erro Semântico: Argumento ${i+1} de '$name' incompatível. Esperado $paramType, recebido $argType.");
       }
    }
    
    return symbol.type;
  }

  @override
  CType visitBlock(BlockContext ctx) {
    final previousScope = currentScope;
    currentScope = Scope(previousScope);

    for (var stmt in ctx.statements()) {
      visit(stmt);
    }

    currentScope = previousScope;
    return CType.voidType;
  }

  @override
  CType visitAssignExpr(AssignExprContext ctx) {
    final leftExpr = ctx.expression(0)!;
    final rightExpr = ctx.expression(1)!;
    
    Symbol? symbol;
    CType targetType = CType.error;
    
    if (leftExpr is IdExprContext) {
       final name = leftExpr.ID()!.text!;
       symbol = currentScope.resolve(name);
       if (symbol == null) {
          throw Exception("Erro Semântico: Variável '$name' não declarada.");
       }
       if (symbol is! VarSymbol) {
          throw Exception("Erro Semântico: '$name' não é uma variável.");
       }
       
       if (symbol is ArraySymbol) {
          if (rightExpr is ArrayLiteralContext) {
             final literalSize = rightExpr.expressions().length;
             if (literalSize > symbol.size) {
                throw Exception("Erro Semântico: Tamanho da lista ($literalSize) maior que o array '$name' (${symbol.size}).");
             }
             
             final elementType = visit(rightExpr) ?? CType.error;
             if (!_areTypesCompatible(symbol.elementType, elementType)) {
                throw Exception("Erro Semântico: Tipos incompatíveis na inicialização do array '$name'.");
             }
             return symbol.elementType;
          } else {
             throw Exception("Erro Semântico: Não é possível atribuir a um array inteiro (use índice).");
          }
       }
       
       targetType = symbol.type;
       
    } else if (leftExpr is ArrayAccessExprContext) {
       targetType = visit(leftExpr) ?? CType.error;
    } else if (leftExpr is MemberAccessExprContext) {
       targetType = visit(leftExpr) ?? CType.error;
    } else {
       throw Exception("Erro Semântico: Lado esquerdo da atribuição deve ser uma variável, elemento de array ou membro de struct/union.");
    }
    
    final valueType = visit(rightExpr) ?? CType.error;
    
    if (!_areTypesCompatible(targetType, valueType)) {
       throw Exception("Erro Semântico: Atribuição incompatível. Esperado $targetType, recebido $valueType.");
    }
    
    return targetType;
  }

  @override
  CType visitArrayAccessExpr(ArrayAccessExprContext ctx) {
    final leftExpr = ctx.expression(0)!;
    if (leftExpr is! IdExprContext) throw Exception("Erro Semântico: Acesso complexo não suportado.");
    
    final name = (leftExpr as IdExprContext).ID()!.text!;
    final symbol = currentScope.resolve(name);
    
    if (symbol == null) {
       throw Exception("Erro Semântico: Array '$name' não declarado.");
    }
    if (symbol is! ArraySymbol) {
       throw Exception("Erro Semântico: '$name' não é um array.");
    }
    
    final indexType = visit(ctx.expression(1)!) ?? CType.error;
    if (indexType != CType.int) {
       throw Exception("Erro Semântico: Índice deve ser inteiro.");
    }
    
    return symbol.elementType;
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
           if (_areTypesCompatible(firstType, type)) {
           } else if (_areTypesCompatible(type, firstType)) {
              firstType = type;
           } else {
              throw Exception("Erro Semântico: Elementos da lista devem ter o mesmo tipo.");
           }
        }
      }
    }
    return firstType ?? CType.voidType;
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
    final op = ctx.op!.text!;
    
    if (op == '%') {
       if (left != CType.int || right != CType.int) {
          throw Exception("Erro Semântico: Operador '%' requer operandos inteiros.");
       }
       return CType.int;
    }
    
    return _getResultingType(left, right);
  }

  @override
  CType visitParenExpr(ParenExprContext ctx) {
    return visit(ctx.expression()!) ?? CType.error;
  }

  @override
  CType visitLogicAndExpr(LogicAndExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    
    if (!_isNumeric(left) || !_isNumeric(right)) {
       throw Exception("Erro Semântico: Operandos lógicos devem ser numéricos.");
    }
    return CType.int;
  }

  @override
  CType visitLogicOrExpr(LogicOrExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    
    if (!_isNumeric(left) || !_isNumeric(right)) {
       throw Exception("Erro Semântico: Operandos lógicos devem ser numéricos.");
    }
    return CType.int;
  }

  @override
  CType visitRelExpr(RelExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    
    if (!_areTypesCompatible(left, right) && !_areTypesCompatible(right, left)) {
       if (!((left == CType.int || left == CType.float) && (right == CType.int || right == CType.float))) {
          throw Exception("Erro Semântico: Operandos de comparação devem ser numéricos.");
       }
    }
    return CType.int;
  }

  @override
  CType visitEqExpr(EqExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    
    if (!_areTypesCompatible(left, right) && !_areTypesCompatible(right, left)) {
       throw Exception("Erro Semântico: Tipos incompatíveis para igualdade.");
    }
    return CType.int;
  }

  @override
  CType visitIfStmt(IfStmtContext ctx) {
    final conditionType = visit(ctx.expression()!) ?? CType.error;
    if (conditionType != CType.int && conditionType != CType.float) {
       throw Exception("Erro Semântico: Condição do IF deve ser numérica (int ou float).");
    }
    
    visit(ctx.statement(0)!);
    if (ctx.statement(1) != null) {
       visit(ctx.statement(1)!);
    }
    return CType.voidType;
  }

  @override
  CType visitWhileStmt(WhileStmtContext ctx) {
    final conditionType = visit(ctx.expression()!) ?? CType.error;
    if (conditionType != CType.int && conditionType != CType.float) {
       throw Exception("Erro Semântico: Condição do WHILE deve ser numérica.");
    }
    visit(ctx.statement()!);
    return CType.voidType;
  }

  @override
  CType visitDoWhileStmt(DoWhileStmtContext ctx) {
    _loopOrSwitchDepth++;
    try {
       visit(ctx.statement()!);
    } finally {
       _loopOrSwitchDepth--;
    }
    
    final conditionType = visit(ctx.expression()!) ?? CType.error;
    if (conditionType != CType.int && conditionType != CType.float) {
       throw Exception("Erro Semântico: Condição do DO-WHILE deve ser numérica.");
    }
    
    return CType.voidType;
  }

  @override
  CType visitSwitchStmt(SwitchStmtContext ctx) {
    final exprType = visit(ctx.expression()!) ?? CType.error;
    if (exprType != CType.int && exprType != CType.char) {
       throw Exception("Erro Semântico: Expressão do switch deve ser int ou char.");
    }
    
    _loopOrSwitchDepth++;
    try {
       visit(ctx.switchBlock()!);
    } finally {
       _loopOrSwitchDepth--;
    }
    return CType.voidType;
  }
  
  @override
  CType visitSwitchBlock(SwitchBlockContext ctx) {
     for (var i = 0; i < ctx.childCount; i++) {
        visit(ctx.getChild(i)!);
     }
     return CType.voidType;
  }
  
  @override
  CType visitCaseStmt(CaseStmtContext ctx) {
     final exprType = visit(ctx.expression()!) ?? CType.error;
     if (exprType != CType.int && exprType != CType.char) {
        throw Exception("Erro Semântico: Case deve ser int ou char.");
     }
     return CType.voidType;
  }
  
  @override
  CType visitDefaultStmt(DefaultStmtContext ctx) {
     return CType.voidType;
  }

  @override
  CType visitForStmt(ForStmtContext ctx) {
    final previousScope = currentScope;
    currentScope = Scope(previousScope);
    
    try {
       if (ctx.varDecl() != null) {
          visit(ctx.varDecl()!);
       }
       
       int semiCount = 0;
       for (var child in ctx.children!) {
          if (child.text == ';') {
             semiCount++;
          } else if (child is ExpressionContext) {
             if (semiCount == 0) {
                if (ctx.varDecl() == null) visit(child);
             } else if (semiCount == 1) {
                final condType = visit(child) ?? CType.error;
                if (condType != CType.int && condType != CType.float) {
                   throw Exception("Erro Semântico: Condição do FOR deve ser numérica.");
                }
             } else if (semiCount == 2) {
                visit(child);
             }
          }
       }
       
       _loopOrSwitchDepth++;
       try {
          visit(ctx.statement()!);
       } finally {
          _loopOrSwitchDepth--;
       }
       
    } finally {
       currentScope = previousScope;
    }
    return CType.voidType;
  }
  
  @override
  CType visitReturnStmt(ReturnStmtContext ctx) {
    CType returnType = CType.voidType;
    if (ctx.expression() != null) {
       returnType = visit(ctx.expression()!) ?? CType.error;
    }
    
    if (_currentFunctionReturnType == null) {
       // Ignora return fora de função se necessário, ou lança erro
    } else {
       if (!_areTypesCompatible(_currentFunctionReturnType!, returnType)) {
          throw Exception("Erro Semântico: Tipo de retorno incompatível. Esperado $_currentFunctionReturnType, recebido $returnType.");
       }
    }
    
    return CType.voidType;
  }

  @override
  CType visitBreakStmt(BreakStmtContext ctx) {
     if (_loopOrSwitchDepth <= 0) {
        throw Exception("Erro Semântico: 'break' fora de loop ou switch.");
     }
     return CType.voidType;
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
    if (target == CType.float && value == CType.int) return true;
    return false;
  }

  CType _getResultingType(CType t1, CType t2) {
    if (t1 == CType.float || t2 == CType.float) return CType.float;
    if (t1 == CType.int && t2 == CType.int) return CType.int;
    if (t1 == CType.string && t2 == CType.string) return CType.string;
    return CType.error;
  }
  
  bool _isNumeric(CType type) {
     return type == CType.int || type == CType.float;
  }
}
