int soma(int a, int b) {
    return a + b;
}

float pi() {
    return 3.14159;
}

string get_msg() {
    return "Ola do Return";
}

int fatorial(int n) {
    if (n <= 1) return 1;
    return n * fatorial(n - 1);
}

void main() {
    puts("Teste de Return");
    
    int s = soma(10, 20);
    puts("Soma 10 + 20 =");
    print(s);
    
    float p = pi();
    puts("PI =");
    print(p);
    
    string msg = get_msg();
    puts(msg);
    
    puts("Fatorial de 5 =");
    print(fatorial(5)); // 120
    
    // Teste em expressao
    int x = soma(5, 5) * 2; // 20
    puts(" (5+5)*2 =");
    print(x);
}
