void saudacao(string nome) {
    puts("Ola ");
    puts(nome);
}

void soma_print(int a, int b) {
    int res = a + b;
    puts("Soma: ");
    print(res);
}

void main() {
    puts("Teste de Funcoes Void");
    
    saudacao("Mundo");
    
    soma_print(10, 20);
    
    // Teste de validacao (descomente para ver erro)
    // saudacao(123); // Erro: esperado string
    // soma_print(10); // Erro: numero incorreto de argumentos
}
