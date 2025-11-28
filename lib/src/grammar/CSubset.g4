grammar CSubset;

// --- Parser Rules ---

// Ponto de entrada: um programa é uma lista de declarações (variáveis ou funções)
program
    : declaration* EOF
    ;

declaration
    : varDecl
    | functionDecl
    | structDecl
    | unionDecl
    ;

// Declaração de Variável: tipo lista_ids;
varDecl
    : typeSpecifier varDeclarator (',' varDeclarator)* ';'
    ;

varDeclarator
    : ID ('[' INT ']')? ('=' expression)?
    ;

// Declaração de Função: tipo nome(params) { corpo }
functionDecl
    : typeSpecifier ID '(' paramList? ')' funcBody=block
    ;

// Declaração de Struct
structDecl
    : STRUCT ID '{' varDecl* '}' ';'
    ;

// Declaração de Union
unionDecl
    : UNION ID '{' varDecl* '}' ';'
    ;

paramList
    : param (',' param)*
    ;

param
    : typeSpecifier ID
    ;

// Tipos suportados
typeSpecifier
    : 'int'      # intType
    | 'float'    # floatType
    | 'char'     # charType
    | 'void'     # voidType
    | 'string'   # stringType
    | STRUCT ID  # structType
    | UNION ID   # unionType
    ;

// Bloco de código
block
    : '{' statement* '}'
    ;

// Comandos (Statements)
statement
    : varDecl               # varDeclStmt
    | structDecl            # structDeclStmt
    | unionDecl             # unionDeclStmt
    | ifStmt                # ifStatement
    | whileStmt             # whileStatement
    | returnStmt            # returnStatement
    | expression ';'        # exprStatement
    | switchStmt            # switchStatement
    | forStmt               # forStatement
    | doWhileStmt           # doWhileStatement
    | breakStmt             # breakStatement
    | block                 # blockStatement
    | ';'                   # emptyStatement
    ;

switchStmt
    : SWITCH '(' expression ')' '{' switchBlock '}'
    ;

switchBlock
    : (caseLabel statement*)*
    ;

caseLabel
    : CASE expression ':'   # caseStmt
    | DEFAULT ':'           # defaultStmt
    ;

forStmt
    : FOR '(' (varDecl | expression ';' | ';') expression? ';' expression? ')' statement
    ;

breakStmt
    : BREAK ';'
    ;

returnStmt
    : 'return' expression? ';'
    ;

ifStmt
    : 'if' '(' expression ')' statement ('else' statement)?
    ;

whileStmt
    : 'while' '(' expression ')' statement
    ;

doWhileStmt
    : DO statement WHILE '(' expression ')' ';'
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
    | expression '.' ID                         # memberAccessExpr
    | '{' expression (',' expression)* '}'      # arrayLiteral
    | expression op=('*' | '/' | '%') expression # mulDivExpr
    | expression op=('+' | '-') expression      # addSubExpr
    | expression op=('<' | '>' | '<=' | '>=') expression # relExpr
    | expression op=('==' | '!=') expression    # eqExpr
    | expression op='&&' expression             # logicAndExpr
    | expression op='||' expression             # logicOrExpr
    | <assoc=right> expression '=' expression   # assignExpr
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
SWITCH  : 'switch';
CASE    : 'case';
DEFAULT : 'default';
FOR     : 'for';
DO      : 'do';
BREAK   : 'break';
STRUCT  : 'struct';
UNION   : 'union';

// Operadores
PLUS    : '+';
MINUS   : '-';
MULT    : '*';
DIV     : '/';
MOD     : '%';
ASSIGN  : '=';
EQ      : '==';
NEQ     : '!=';
LT      : '<';
GT      : '>';
LE      : '<=';
GE      : '>=';
AND     : '&&';
OR      : '||';
COMMA   : ',';
SEMI    : ';';
COLON   : ':';
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
