struct Point {
  int x;
  int y;
};

void main() {
  struct Point p;
  p.x = 10;
  p.y = 20;

  puts("Ponto:");
  print(p.x);
  print(p.y);

  int sum = p.x + p.y;
  puts("Soma:");
  print(sum);
}
