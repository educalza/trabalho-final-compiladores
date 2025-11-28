union Data {
  int i;
  float f;
};

void main() {
  union Data d;
  d.i = 10;
  puts("Int:");
  print(d.i);

  d.f = 3.14;
  puts("Float:");
  print(d.f);
}
