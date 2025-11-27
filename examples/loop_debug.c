void main() {
    print("Debug Do-While");
    int i = 0;
    do {
        print(i);
        i = i + 1;
        if (i > 10) {
            print("Emergency Break");
            break;
        }
    } while (i < 3);
}
