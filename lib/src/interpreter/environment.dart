/// Gerencia a memória (variáveis e seus valores) durante a execução
class Environment {
  final Environment? enclosing;
  final Map<String, dynamic> values = {};

  Environment([this.enclosing]);

  /// Define uma variável no escopo atual
  void define(String name, dynamic value) {
    values[name] = value;
  }

  /// Busca o valor de uma variável (sobe a cadeia de escopos)
  dynamic get(String name) {
    if (values.containsKey(name)) {
      return values[name];
    }
    if (enclosing != null) {
      return enclosing!.get(name);
    }
    throw Exception("Erro de Execução: Variável '$name' não definida.");
  }

  /// Atualiza o valor de uma variável existente
  void assign(String name, dynamic value) {
    if (values.containsKey(name)) {
      values[name] = value;
      return;
    }
    if (enclosing != null) {
      enclosing!.assign(name, value);
      return;
    }
    throw Exception("Erro de Execução: Variável '$name' não declarada.");
  }
}
