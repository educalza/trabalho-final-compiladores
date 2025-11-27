grammar CSubset;

// --- Parser Rules ---

// Ponto de entrada: um programa é uma lista de declarações (variáveis ou funções)
program
    : declaration* EOF
    ;

declaration
    : varDecl
    | functionDecl
    ;

// Declaração de Variável: tipo lista_ids;
varDecl
    : typeSpecifier varDeclarator (',' varDeclarator)* ';'
    ;

varDeclarator
    : ID ('[' INT ']')?
    ;

// Declaração de Função: tipo nome(params) { corpo }
functionDecl
    : typeSpecifier ID '(' paramList? ')' block
    ;

paramList
    : param (',' param)*
    ;

param
    : typeSpecifier ID
    ;

// Tipos suportados
typeSpecifier
    : 'int'
    | 'float'
    | 'char'
    | 'void'
    | 'string'
    ;

// Bloco de código
block
    : '{' statement* '}'
    ;

// Comandos (Statements)
statement
    : varDecl               # varDeclStmt
    | ifStmt                # ifStatement
    | whileStmt             # whileStatement
    | returnStmt            # returnStatement
    | assignment ';'        # assignStatement
    | functionCall ';'      # funcCallStatement
    | block                 # blockStatement
    | ';'                   # emptyStatement
    ;

ifStmt
    : 'if' '(' expression ')' statement ('else' statement)?
    ;

whileStmt
    : 'while' '(' expression ')' statement
    ;

returnStmt
    : 'return' expression? ';'
    ;

assignment
    : ID ('[' expression ']')? '=' expression
    ;

functionCall
    : ID '(' argList? ')'
    ;

argList
    : expression (',' expression)*
    ;

// Expressões (com precedência definida pela ordem das alternativas)
expression
    : '(' expression ')'                        # parenExpr
    | functionCall                              # callExpr
    | expression '[' expression ']'             # arrayAccessExpr
    | '{' expression (',' expression)* '}'      # arrayLiteral
    | expression op=('*' | '/') expression      # mulDivExpr
    | expression op=('+' | '-') expression      # addSubExpr
    | expression op=('<' | '>' | '<=' | '>=') expression # relExpr
    | expression op=('==' | '!=') expression    # eqExpr
    | ID                                        # idExpr
    | INT                                       # intExpr
    | FLOAT                                     # floatExpr
    | STRING                                    # stringExpr
    ;

// --- Lexer Rules ---

// Palavras-chave
IF      : 'if';
ELSE    : 'else';
WHILE   : 'while';
RETURN  : 'return';
INT_TYPE: 'int';
FLOAT_TYPE: 'float';
CHAR_TYPE : 'char';
VOID_TYPE : 'void';

// Operadores
PLUS    : '+';
MINUS   : '-';
MULT    : '*';
DIV     : '/';
ASSIGN  : '=';
EQ      : '==';
NEQ     : '!=';
LT      : '<';
GT      : '>';
LE      : '<=';
GE      : '>=';
COMMA   : ',';
SEMI    : ';';
LPAREN  : '(';
RPAREN  : ')';
LBRACE  : '{';
RBRACE  : '}';
LBRACKET: '[';
RBRACKET: ']';

// Identificadores
ID      : [a-zA-Z_] [a-zA-Z0-9_]*;

// Literais
INT     : [0-9]+;
FLOAT   : [0-9]+ '.' [0-9]+;
STRING  : '"' .*? '"';

// Ignorar espaços em branco e comentários
WS      : [ \t\r\n]+ -> skip;
COMMENT : '//' ~[\r\n]* -> skip;
BLOCK_COMMENT : '/*' .*? '*/' -> skip;
