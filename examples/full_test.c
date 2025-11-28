// Teste Abrangente do CSubset
// Cobre: Tipos, Arrays, Controle de Fluxo, Funções, Structs, Unions, IO,
// Conversores

#define PI 3.14159
#define MSG "Ola Mundo"

struct Point {
  int x;
  int y;
};

union Data {
  int i;
  float f;
};

// Declaração de função sem retorno
void saudacao(string nome) { printf("Ola, %s!\n", nome); }

// Declaração de função com retorno
int soma(int a, int b) { return a + b; }

// Recursão
int fatorial(int n) {
  if (n <= 1)
    return 1;
  return n * fatorial(n - 1);
}

void main() {
  // 1. Tipos Numéricos e Texto
  int i = 10;
  float f = 2.5;
  string s = "Texto";

  printf("Int: %d, Float: %f, String: %s\n", i, f, s);

  // 2. Arrays e Inicialização
  int arr[3] = {1, 2, 3};
  printf("Array[1]: %d\n", arr[1]);

  // 3. Controle de Fluxo
  if (i > 5) {
    puts("i maior que 5");
  } else {
    puts("i menor ou igual a 5");
  }

  int count = 0;
  while (count < 3) {
    printf("While count: %d\n", count);
    count = count + 1;
  }

  do {
    printf("Do-While count: %d\n", count);
    count = count - 1;
  } while (count > 0);

  for (int k = 0; k < 3; k = k + 1) {
    printf("For k: %d\n", k);
  }

  int val = 2;
  switch (val) {
  case 1:
    puts("Case 1");
    break;
  case 2:
    puts("Case 2");
    break;
  default:
    puts("Default");
  }

  // 4. Operações Matemáticas e Lógicas
  int res = (10 + 5) * 2;
  printf("Math: %d\n", res);

  if (10 > 5 && 2 < 4) {
    puts("Logica AND OK");
  }

  // 5. Funções
  saudacao("Usuario");
  int sres = soma(10, 20);
  printf("Soma: %d\n", sres);
  printf("Fatorial(5): %d\n", fatorial(5));

  // 6. Structs
  struct Point p;
  p.x = 100;
  p.y = 200;
  printf("Struct Point: x=%d, y=%d\n", p.x, p.y);

  // 7. Unions
  union Data d;
  d.i = 42;
  printf("Union Int: %d\n", d.i);
  d.f = 3.14;
  printf("Union Float: %f\n", d.f);

  // 8. IO e Conversores
  // Simulação de input (scanf requer interação, vamos testar conversores)
  string numStr = "123";
  int num = stoi(numStr);
  printf("STOI: %d\n", num + 1);

  string floatStr = "12.5";
  float fnum = stof(floatStr);
  printf("STOF: %f\n", fnum + 0.5);

  puts("Teste Concluido!");
}
