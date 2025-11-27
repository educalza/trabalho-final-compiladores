void main() {
    puts("Teste de Operadores");
    
    // Modulo
    int a = 10;
    int b = 3;
    int mod = a % b;
    puts("10 % 3 =");
    print(mod); // Esperado 1
    
    // Logicos
    int t = 1;
    int f = 0;
    
    puts("1 && 1 =");
    print(t && t); // 1
    
    puts("1 && 0 =");
    print(t && f); // 0
    
    puts("0 || 1 =");
    print(f || t); // 1
    
    puts("0 || 0 =");
    print(f || f); // 0
    
    // Precedencia
    // || tem menor precedencia que &&
    // 1 || 0 && 0 -> 1 || (0 && 0) -> 1 || 0 -> 1
    // Se fosse (1 || 0) && 0 -> 1 && 0 -> 0
    puts("Precedencia 1 || 0 && 0 =");
    print(t || f && f); // Esperado 1
    
    // Short-circuit
    // 1 || (erro) -> deve retornar 1 sem erro
    // Mas nao temos como gerar erro facil aqui sem abortar.
    // Vamos confiar na logica implementada.
}
