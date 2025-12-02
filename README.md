# Trabalho Final – Compiladores

## 📌 Visão Geral

Este repositório contém a implementação de um compilador desenvolvido como *trabalho final da disciplina de Compiladores. O projeto utiliza a linguagem **Dart* e técnicas clássicas de compiladores, como *análise léxica* e *análise sintática*, aplicadas a partir de uma gramática formalizada.

O objetivo principal é aplicar, na prática, os conceitos estudados em sala de aula, construindo um compilador básico capaz de interpretar, validar e processar uma linguagem definida pelo grupo.

---

## 🛠 Tecnologias e Ferramentas Utilizadas

* *Dart* – Linguagem utilizada para implementar o compilador.
* *ANTLR (ou estrutura própria de análise)* – Para definição de tokens e regras gramaticais (dependendo da implementação adotada).
* *Git e GitHub* – Controle de versão e colaboração.
* *VS Code / IntelliJ / Terminal* – IDEs e ferramentas recomendadas para desenvolvimento.

---

## 📂 Estrutura do Projeto

A estrutura do projeto está organizada da seguinte forma:


trabalho-final-compiladores/
│
├── bin/                → Arquivos principais para execução
├── lib/                → Código-fonte do compilador
├── examples/           → Exemplos de código de entrada
├── test/               → Casos de teste
├── tool/               → Ferramentas auxiliares
│
├── pubspec.yaml        → Dependências do projeto em Dart
├── pubspec.lock        → Versões exatas das dependências
└── README.md           → Documentação do projeto


> Essa estrutura pode sofrer pequenas alterações conforme a evolução do projeto.

---

## ✅ Funcionalidades

O compilador implementa as seguintes funcionalidades principais:

* ✅ *Análise léxica* (tokenização do código)
* ✅ *Análise sintática* (validação da estrutura da linguagem)
* ✅ Verificação de erros léxicos e sintáticos
* ✅ Processamento de código de entrada localizado em arquivos .txt ou equivalentes
* ✅ Suporte a testes baseados em exemplos

---

## 🚀 Como Executar o Projeto

### 1. Instalar o Dart

Certifique-se de ter o Dart instalado em sua máquina:

bash
dart --version


Caso não tenha, instale pelo site oficial:
[https://dart.dev/get-dart](https://dart.dev/get-dart)

---

### 2. Clonar o repositório

bash
git clone https://github.com/educalza/trabalho-final-compiladores.git


Entre na pasta do projeto:

bash
cd trabalho-final-compiladores


---

### 3. Instalar as dependências

bash
dart pub get


---

### 4. Executar o compilador

Dependendo do arquivo principal configurado em bin/, execute:

bash
dart run


Ou de forma mais explícita:

bash
dart run bin/main.dart


(Caso o nome do arquivo principal seja outro, substitua por ele.)

---

## 🧪 Executando exemplos

Na pasta examples/, você encontrará arquivos de exemplo. Para testar um deles:

bash
dart run bin/main.dart examples/nome_do_arquivo.txt


Exemplo:

bash
dart run bin/main.dart examples/teste1.txt


O compilador realizará a análise e exibirá no terminal se a entrada é válida ou se possui erros léxicos/sintáticos.

---

## 🧪 Executando testes automatizados

Se houver arquivos na pasta test/, você pode rodá-los com:

bash
dart test


---

## 📚 Conceitos Aplicados

Este projeto demonstra a aplicação prática dos seguintes conceitos de Compiladores:

* Tokens e Lexemas
* Regex e padrões léxicos
* Gramáticas livres de contexto (GLC)
* Análise Top-Down / Bottom-Up
* Símbolos terminais e não-terminais
* Detecção e tratamento de erros

---

## 👨‍💻 Autores

Projeto desenvolvido como trabalho final da disciplina de *Compiladores*, por alunos do curso de Ciência/Engenharia da Computação.

Repositório:
[https://github.com/educalza/trabalho-final-compiladores](https://github.com/educalza/trabalho-final-compiladores)

---

## 📄 Licença

Este projeto está disponibilizado apenas para fins acadêmicos. Caso deseje utilizar parte do código em outros projetos, entre em contato com os autores.

---

✅ *Dica:* Se você quiser, posso adaptar este README para a ABNT, inglês, ou incluir exemplos reais de código e prints do terminal.
