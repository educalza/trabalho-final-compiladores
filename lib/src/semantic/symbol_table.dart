/// Representa um tipo básico na linguagem
enum CType { int, float, char, voidType, string, error }

/// Classe base para qualquer símbolo (variável ou função)
abstract class Symbol {
  final String name;
  final CType type;

  Symbol(this.name, this.type);
}

/// Representa uma variável
class VarSymbol extends Symbol {
  VarSymbol(String name, CType type) : super(name, type);
}

/// Representa um array
class ArraySymbol extends VarSymbol {
  final int size;
  final CType elementType;

  ArraySymbol(String name, CType elementType, this.size) 
      : this.elementType = elementType, 
        super(name, elementType); // Tipo base é o do elemento ou um tipo 'array'?
        // Para simplificar, vamos dizer que o tipo do símbolo é o tipo do elemento,
        // mas precisamos distinguir array de variável normal.
        // Melhor: adicionar CType.array? Ou usar is ArraySymbol.
}

/// Representa uma função
class FunctionSymbol extends Symbol {
  final List<VarSymbol> parameters = [];

  FunctionSymbol(String name, CType type) : super(name, type);
}

/// Representa um escopo (tabela de símbolos)
class Scope {
  final Scope? enclosingScope;
  final Map<String, Symbol> symbols = {};

  Scope([this.enclosingScope]);

  /// Define um novo símbolo no escopo atual
  void define(Symbol symbol) {
    symbols[symbol.name] = symbol;
  }

  /// Busca um símbolo pelo nome, subindo a cadeia de escopos se necessário
  Symbol? resolve(String name) {
    var symbol = symbols[name];
    if (symbol != null) return symbol;

    if (enclosingScope != null) {
      return enclosingScope!.resolve(name);
    }

    return null;
  }

  /// Verifica se o símbolo já existe APENAS no escopo atual (para evitar redeclaração)
  bool isDefinedLocally(String name) {
    return symbols.containsKey(name);
  }
}
