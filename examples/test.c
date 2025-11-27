int globalVar;

void main() {
    int a;
    int b;
    a = 10;
    b = 20;

    if (a < b) {
        int temp;
        temp = a;
        a = b;
        b = temp;
    }

    while (b > 0) {
        b = b - 1;
    }
}

int soma(int x, int y) {
    return x + y;
}
