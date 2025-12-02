# Trabalho Final – Compiladores

## 📌 Visão Geral

Este repositório contém a implementação de um interpretador desenvolvido como *trabalho final da disciplina de Compiladores. O projeto utiliza a linguagem **Dart* e técnicas clássicas de compiladores, como *análise léxica* e *análise sintática*, aplicadas a partir de uma gramática formalizada.

O objetivo principal é aplicar, na prática, os conceitos estudados em sala de aula, construindo um interpretador básico capaz de interpretar, validar e processar uma linguagem definida pelo grupo.

---

## 🛠 Tecnologias e Ferramentas Utilizadas

* *Dart* – Linguagem utilizada para implementar o interpretador.
* *ANTLR * – Para definição de tokens e regras gramaticais.

---

## 📂 Estrutura do Projeto

A estrutura do projeto está organizada da seguinte forma:


trabalho-final-compiladores/
│
├── bin/                → Arquivos principais para execução
├── lib/                → Código-fonte do interpretador
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

O interpretador implementa as seguintes funcionalidades principais:

* ✅ *Análise léxica* (tokenização do código)
* ✅ *Análise sintática* (validação da estrutura da linguagem)
* ✅ Verificação de erros léxicos e sintáticos
* ✅ Processamento de código de entrada localizado em arquivos .txt ou equivalentes
* ✅ Suporte a testes baseados em exemplos

---

## 🚀 Como Executar o Projeto

### 1. Instalar o Dart

Certifique-se de ter o Dart instalado em sua máquina:

dart --version


Caso não tenha, instale pelo site oficial:
[https://dart.dev/get-dart](https://dart.dev/get-dart)

---

### 2. Clonar o repositório

git clone https://github.com/educalza/trabalho-final-compiladores.git


Entre na pasta do projeto:

cd trabalho-final-compiladores


---

### 3. Instalar as dependências


dart pub get


---

### 4. Executar o compilador

Dependendo do arquivo principal configurado em bin/, execute:

dart run bin/c_processor.dart examples/full_test.c


Ou na forma REPL:

dart run bin/c_processor.dart


---

## 🧪 Executando exemplos

Na pasta examples/, você encontrará arquivos de exemplo. Para testar um deles:

dart run bin/c_processor.dart examples/full_test.c


Exemplo:

dart run bin/c_processor.dart examples/test_ops.c


O compilador realizará a análise e exibirá no terminal se a entrada é válida ou se possui erros léxicos/sintáticos.

---

## 🧪 Executando testes automatizados

Os arquivos na pasta test/, você pode rodá-los com:

dart test


---


## 👨‍💻 Autores

Projeto desenvolvido como trabalho final da disciplina de *Compiladores*, por alunos do curso de Ciência/Engenharia da Computação.

Repositório:
[https://github.com/educalza/trabalho-final-compiladores](https://github.com/educalza/trabalho-final-compiladores)

---

## 📄 Licença

Este projeto está disponibilizado apenas para fins acadêmicos. Caso deseje utilizar parte do código em outros projetos, entre em contato com os autores.


