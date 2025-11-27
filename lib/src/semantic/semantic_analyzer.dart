import 'package:antlr4/antlr4.dart';
import '../generated/CSubsetBaseVisitor.dart';
import '../generated/CSubsetParser.dart';
import 'symbol_table.dart';

class SemanticAnalyzer extends CSubsetBaseVisitor<CType> {
  Scope currentScope;
  CType? _currentFunctionReturnType;
  int _loopOrSwitchDepth = 0; // Para validar break

  SemanticAnalyzer() : currentScope = Scope() {
    // Define funções built-in
    // print aceita qualquer coisa, mas vamos definir como void print(string) para validação básica
    // ou melhor, vamos tratar print como especial no visitFunctionCall
    final printSymbol = FunctionSymbol('print', CType.voidType);
    // Adiciona um parâmetro genérico ou deixa vazio e valida magicamente?
    // Vamos adicionar um parâmetro 'any' (usando string como placeholder ou criando CType.any se necessário)
    // Para simplificar: print aceita 1 argumento.
    printSymbol.parameters.add(VarSymbol('arg', CType.string)); // Tipo dummy, validaremos dinamicamente
    currentScope.define(printSymbol);
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
    final previousReturnType = _currentFunctionReturnType;
    _currentFunctionReturnType = returnType;
    
    visit(ctx.block()!);
    
    _currentFunctionReturnType = previousReturnType;

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
      
      Symbol symbol;
      if (declarator.INT() != null) {
        // É um array
        final size = int.parse(declarator.INT()!.text!);
        symbol = ArraySymbol(name, type, size);
        currentScope.define(symbol);
      } else {
        // Variável normal
        symbol = VarSymbol(name, type);
        currentScope.define(symbol);
      }
      
      // Verifica inicialização
      if (declarator.expression() != null) {
         final initExpr = declarator.expression()!;
         
         if (symbol is ArraySymbol) {
            // Inicialização de array: int arr[2] = {1, 2};
            // O parser permite '=' expression. A expression deve ser ArrayLiteral.
            if (initExpr is! ArrayLiteralContext) {
               throw Exception("Erro Semântico: Array '$name' deve ser inicializado com lista {...}.");
            }
            // A validação do literal é feita visitando-o, mas precisamos validar compatibilidade com o array
            // Podemos reutilizar a lógica de atribuição ou chamar visitArrayLiteral e checar tipo.
            // Vamos simplificar chamando visit e checando compatibilidade.
            
            // Mas visitArrayLiteral retorna o tipo do elemento (ou void).
            // Precisamos validar tamanho também.
            
            final literalSize = initExpr.expressions().length;
            if (literalSize > symbol.size) {
               throw Exception("Erro Semântico: Tamanho da lista ($literalSize) maior que o array '$name' (${symbol.size}).");
            }
            
            final elementType = visit(initExpr) ?? CType.error;
            if (!_areTypesCompatible(symbol.elementType, elementType)) {
               throw Exception("Erro Semântico: Tipos incompatíveis na inicialização do array '$name'.");
            }
            
         } else {
            // Variável normal
            final initType = visit(initExpr) ?? CType.error;
            if (!_areTypesCompatible(type, initType)) {
               throw Exception("Erro Semântico: Inicialização incompatível para '$name'. Esperado $type, recebido $initType.");
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
       // Validação especial para print: aceita 1 argumento de qualquer tipo
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

    final symbol = currentScope.resolve(name);
    if (symbol == null) {
      throw Exception("Erro Semântico: Função '$name' não declarada.");
    }
    if (symbol is! FunctionSymbol) {
      throw Exception("Erro Semântico: '$name' não é uma função.");
    }
    
    // Validação de argumentos
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
  CType visitAssignExpr(AssignExprContext ctx) {
    // Lado esquerdo deve ser ID ou ArrayAccess
    // Como expression é recursiva, precisamos checar o tipo do contexto do lado esquerdo.
    // ctx.expression(0) é o lado esquerdo.
    
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
       // Se for array sem índice, erro (exceto se right for array literal, mas array literal não é expression normal)
       // ArrayLiteral é expression, então ok.
       
       if (symbol is ArraySymbol) {
          // Atribuição direta a array só permitida se right for ArrayLiteral
          if (rightExpr is ArrayLiteralContext) {
             // Validação de literal já feita no visitArrayLiteral?
             // Não, visitArrayLiteral retorna tipo do elemento.
             // Precisamos validar tamanho e tipo aqui.
             
             final literalSize = rightExpr.expressions().length;
             if (literalSize > symbol.size) {
                throw Exception("Erro Semântico: Tamanho da lista ($literalSize) maior que o array '$name' (${symbol.size}).");
             }
             
             final elementType = visit(rightExpr) ?? CType.error;
             if (!_areTypesCompatible(symbol.elementType, elementType)) {
                throw Exception("Erro Semântico: Tipos incompatíveis na inicialização do array '$name'.");
             }
             return symbol.elementType; // Retorna tipo do elemento? Ou void? Em C, array assignment não é expression válida padrão, mas aqui permitimos init.
             // Mas espere, C não permite 'arr = {1,2}' depois da declaração.
             // Vamos permitir? O usuário pediu "inicialização de array".
             // Se for assignment normal, C não permite.
             // Mas nossa gramática permite. Vamos permitir por conveniência?
             // Sim.
          } else {
             throw Exception("Erro Semântico: Não é possível atribuir a um array inteiro (use índice).");
          }
       }
       
       targetType = symbol.type;
       
    } else if (leftExpr is ArrayAccessExprContext) {
       // Valida o array access
       targetType = visit(leftExpr) ?? CType.error;
       // visitArrayAccessExpr já valida se é array e índice int.
    } else {
       throw Exception("Erro Semântico: Lado esquerdo da atribuição deve ser uma variável ou elemento de array.");
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
    // Simplificação: assume ID
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
       // Permite int vs float
       if (!((left == CType.int || left == CType.float) && (right == CType.int || right == CType.float))) {
          throw Exception("Erro Semântico: Operandos de comparação devem ser numéricos.");
       }
    }
    return CType.int; // Representa boolean (0 ou 1)
  }

  @override
  CType visitEqExpr(EqExprContext ctx) {
    final left = visit(ctx.expression(0)!) ?? CType.error;
    final right = visit(ctx.expression(1)!) ?? CType.error;
    
    if (!_areTypesCompatible(left, right) && !_areTypesCompatible(right, left)) {
       throw Exception("Erro Semântico: Tipos incompatíveis para igualdade.");
    }
    return CType.int; // Representa boolean
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
       // Visita o bloco do switch manualmente para validar os cases
       // A gramática define switchBlock como lista de (caseLabel statement*)
       // Mas o parser gera switchBlockContext.
       // Vamos visitar o switchBlock.
       visit(ctx.switchBlock()!);
    } finally {
       _loopOrSwitchDepth--;
    }
    return CType.voidType;
  }
  
  @override
  CType visitSwitchBlock(SwitchBlockContext ctx) {
     // O switchBlock contém filhos que são CaseStmt ou DefaultStmt (via caseLabel) e statements.
     // Precisamos iterar sobre os filhos.
     // Mas a regra é: switchBlock : (caseLabel statement*)*
     // O ANTLR gera métodos para acessar caseLabel() e statement().
     // Vamos simplificar: visitar todos os filhos.
     
     for (var i = 0; i < ctx.childCount; i++) {
        visit(ctx.getChild(i)!);
     }
     return CType.voidType;
  }
  
  @override
  CType visitCaseStmt(CaseStmtContext ctx) {
     final exprType = visit(ctx.expression()!) ?? CType.error;
     // Idealmente verificar se é constante e compatível com o switch, mas aqui só validamos tipo básico
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
    currentScope = Scope(previousScope); // Escopo para init
    // print("DEBUG: Criado escopo ${currentScope.hashCode} para FOR (pai: ${previousScope.hashCode})");
    
    try {
       // Implementação robusta baseada em iteração de filhos para identificar partes do FOR
       
       // Primeiro, tratar Init se for VarDecl (pois VarDecl não é ExpressionContext)
       if (ctx.varDecl() != null) {
          visit(ctx.varDecl()!);
       }
       
       int semiCount = 0;
       for (var child in ctx.children!) {
          if (child.text == ';') {
             semiCount++;
          } else if (child is ExpressionContext) {
             if (semiCount == 0) {
                // Init expression (se não for varDecl)
                if (ctx.varDecl() == null) visit(child);
             } else if (semiCount == 1) {
                // Condition
                final condType = visit(child) ?? CType.error;
                if (condType != CType.int && condType != CType.float) {
                   throw Exception("Erro Semântico: Condição do FOR deve ser numérica.");
                }
             } else if (semiCount == 2) {
                // Update
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
       // Return fora de função? (Na main ou global)
       // Vamos assumir que main é void ou int, mas o parser garante que estamos dentro de função?
       // Não necessariamente. Mas nossa estrutura de visitação sim.
       // Se estivermos no nível global (visitProgram), não deveríamos encontrar returnStmt solto fora de função se a gramática não permitir.
       // A gramática diz: program : declaration*. declaration : varDecl | functionDecl.
       // Statements só existem dentro de block, que está dentro de functionDecl.
       // Então _currentFunctionReturnType deve estar setado se visitarmos corretamente.
       // Mas cuidado com blocos aninhados.
    }
    
    if (!_areTypesCompatible(_currentFunctionReturnType ?? CType.voidType, returnType)) {
       throw Exception("Erro Semântico: Tipo de retorno incompatível. Esperado $_currentFunctionReturnType, recebido $returnType.");
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
    if (target == CType.float && value == CType.int) return true; // Promoção
    return false;
  }

  CType _getResultingType(CType t1, CType t2) {
    if (t1 == CType.float || t2 == CType.float) return CType.float;
    if (t1 == CType.int && t2 == CType.int) return CType.int;
    if (t1 == CType.string && t2 == CType.string) return CType.string; // Concatenação
    return CType.error;
  }
  
  bool _isNumeric(CType type) {
     return type == CType.int || type == CType.float;
  }
}
