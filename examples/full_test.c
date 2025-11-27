void main() {
    print("=== TESTE COMPLETO ===");

    // 1. Tipos Primitivos
    print("--- Tipos Primitivos ---");
    int i = 10;
    float f = 3.14;
    string s = "Ola Mundo";
    print(i);
    print(f);
    print(s);

    // 2. Arrays
    print("--- Arrays ---");
    int arr[3];
    arr[0] = 100;
    arr[1] = 200;
    arr[2] = 300;
    print(arr[1]);
    
    // Inicialização em lote
    int arr2[2] = {10, 20};
    print(arr2[0] + arr2[1]);

    // 3. If-Else
    print("--- If-Else ---");
    if (i > 5) {
        print("i maior que 5");
    } else {
        print("i menor ou igual a 5");
    }

    if (i == 10) {
        if (f < 4.0) {
            print("i e 10 e f menor que 4.0");
        }
    }

    // 4. Loops
    print("--- Loops ---");
    
    print("For Loop:");
    for (int k = 0; k < 3; k = k + 1) {
        print(k);
    }

    print("While Loop:");
    int w = 0;
    while (w < 3) {
        print(w);
        w = w + 1;
    }

    print("Do-While Loop:");
    int d = 0;
    do {
        print(d);
        d = d + 1;
    } while (d < 3);

    // 5. Switch
    print("--- Switch ---");
    int sw = 2;
    switch (sw) {
        case 1: 
            print("Case 1");
            break;
        case 2:
            print("Case 2");
            break;
        default:
            print("Default");
    }
    
    // 6. Break em Loop
    print("--- Break ---");
    for (int b = 0; b < 10; b = b + 1) {
        if (b == 2) break;
        print(b);
    }

    print("=== FIM ===");
}
