%{
#include <stdio.h>
#include <string.h>

#include "uthash.h"

#include "structs.h"

extern int yylex();
extern int lines;

void yyerror(const char* s) {
  fprintf(stderr, "%s\n", s);
}

int declarations = 0;
int spaces = 4;
int spacesIncrement = 4;

symbol* symbolTable = (symbol *) NULL;

void printSpaces();

void generateDeclarations(declaration *);
void generateStatementSequence(statementSequence *);
void generateStatement(statement *);
void generateAssignment(assignment *);
void generateIfStatement(ifStatement *);
void generateElseStatement(elseClause *);
void generateWhileStatement(whileStatement *);
void generateWriteInt(writeInt *);
void generateExpression(expression *);
void generateSimpleExpression(simpleExpression *);
void generateTerm(term *);
void generateFactor(factor *);
%}

%file-prefix "y"

%union {
  long  ival;
  char* sval;
  void* nPtr;
}

%start program

%token <ival> num
%token <ival> boollit
%token <sval> ident

%token LP
%token RP
%token ASGN
%token SC
%token <sval> OP2
%token <sval> OP3
%token <sval> OP4

%token IF
%token THEN
%token ELSE
%token BEGIN_TOKEN
%token END
%token WHILE
%token DO
%token PROGRAM
%token VAR
%token AS
%token INT
%token BOOL

%token WRITEINT
%token READINT

%type <nPtr> program
%type <nPtr> declarations
%type <ival> type
%type <nPtr> statementSequence
%type <nPtr> statement
%type <nPtr> assignment
%type <nPtr> ifStatement
%type <nPtr> elseClause
%type <nPtr> whileStatement
%type <nPtr> writeInt
%type <nPtr> expression
%type <nPtr> simpleExpression
%type <nPtr> term
%type <nPtr> factor

%%
program : PROGRAM declarations BEGIN_TOKEN statementSequence END
 {
   printf("#include <stdbool.h>\n");
   printf("#include <stdio.h>\n");
   printf("\nint main() {\n");

   generateDeclarations( (declaration *) $2);
   generateStatementSequence( (statementSequence *) $4);

   printSpaces();
   printf("return 0;\n}\n");
 }
 ;

declarations : VAR ident AS type SC declarations
 {
   declarations++;

   declaration* ptr;
   ptr = malloc( sizeof(declaration) );
   ptr->ident = strdup($2);
   ptr->type = $4;
   ptr->rest = $6;
   $$ = ptr;

   symbol *s;
   HASH_FIND_STR(symbolTable, ptr->ident, s);

   if (s == NULL) {
       s = malloc( sizeof(symbol) );
       s->name = strdup(ptr->ident);
       s->type = ptr->type;
       HASH_ADD_STR(symbolTable, name, s);
   }
   else {
       fprintf(stderr, "error on line %d:\tidentifier '%s' already defined\n", lines-declarations, ptr->ident); exit(1);
   }
 }
 | %empty { $$ = (declaration*) NULL; }
 ;

type : INT { $$ = 0; }
 | BOOL { $$ = 1; }
 ;

statementSequence : statement SC statementSequence
 {
   statementSequence* ptr;
   ptr = malloc( sizeof(statementSequence) );
   ptr->stmt = $1;
   ptr->rest = $3;
   $$ = ptr;
 }
 | %empty { $$ = (statement*) NULL; }
 ;

statement : assignment
 {
   statement* ptr;
   ptr = malloc( sizeof(statement) );
   ptr->type = 0;
   ptr->stmtPtr = (void *) $1;
   $$ = ptr;
 }
 | ifStatement
 {
   statement* ptr;
   ptr = malloc( sizeof(statement) );
   ptr->type = 1;
   ptr->stmtPtr = (void *) $1;
   $$ = ptr;
 }
 | whileStatement
 {
   statement* ptr;
   ptr = malloc( sizeof(statement) );
   ptr->type = 2;
   ptr->stmtPtr = (void *) $1;
   $$ = ptr;
 }
 | writeInt
 {
   statement* ptr;
   ptr = malloc( sizeof(statement) );
   ptr->type = 3;
   ptr->stmtPtr = (void *) $1;
   $$ = ptr;
 }
 ;

assignment : ident ASGN expression
 {
   assignment* ptr;
   ptr = malloc( sizeof(assignment) );
   ptr->ident = $1;
   ptr->expr = $3;
   $$ = ptr;

   symbol *s;
   HASH_FIND_STR(symbolTable, ptr->ident, s);

   if (s == NULL) {
       fprintf(stderr, "error on line %d:\tundefined identifier '%s'\n", lines, ptr->ident); exit(1);
   }
 }
 | ident ASGN READINT
 {
   assignment* ptr;
   ptr = malloc( sizeof(assignment) );
   ptr->ident = $1;
   ptr->expr = (expression *) NULL;
   $$ = ptr;

   symbol *s;
   HASH_FIND_STR(symbolTable, ptr->ident, s);

   if (s == NULL) {
       fprintf(stderr, "error on line %d:\tundefined identifier '%s'\n", lines, ptr->ident); exit(1);
   }
   else if (s->type == 1) {
       fprintf(stderr, "error on line %d:\tidentifier '%s' must be an integer\n", lines, ptr->ident); exit(1);
   }
 }
 ;

ifStatement : IF expression THEN statementSequence elseClause END
 {
   ifStatement* ptr;
   ptr = malloc( sizeof(ifStatement) );
   ptr->expr = $2;
   ptr->stmtSeq = $4;
   ptr->elseCl = $5;
   $$ = ptr;
 }
 ;

elseClause : ELSE statementSequence
 {
   elseClause* ptr;
   ptr = malloc( sizeof(elseClause) );
   ptr->stmtSeq = $2;
   $$ = ptr;
 }
 | %empty { $$ = (elseClause*) NULL; }
 ;

whileStatement : WHILE expression DO statementSequence END
 {
   whileStatement* ptr;
   ptr = malloc( sizeof(whileStatement) );
   ptr->expr = $2;
   ptr->stmtSeq = $4;
   $$ = ptr;
 }
 ;

writeInt : WRITEINT expression
 {
   writeInt* ptr;
   ptr = malloc( sizeof(writeInt) );
   ptr->expr = $2;
   $$ = ptr;
 }
 ;

expression : simpleExpression
 {
   expression* ptr;
   ptr = malloc( sizeof(expression) );
   ptr->sExpr1 = $1;
   ptr->sExpr2 = (simpleExpression *) NULL;
   $$ = ptr;
 }
 | simpleExpression OP4 simpleExpression
 {
   expression* ptr;
   ptr = malloc( sizeof(expression) );
   ptr->sExpr1 = $1;
   ptr->op4 = $2;
   ptr->sExpr2 = $3;
   $$ = ptr;
 }
 ;

simpleExpression : term OP3 term
 {
   simpleExpression* ptr;
   ptr = malloc( sizeof(simpleExpression) );
   ptr->term1 = $1;
   ptr->op3 = $2;
   ptr->term2 = $3;
   $$ = ptr;
 }
 | term
 {
   simpleExpression* ptr;
   ptr = malloc( sizeof(simpleExpression) );
   ptr->term1 = $1;
   ptr->term2 = (term *) NULL;
   $$ = ptr;
 }
 ;

term : factor OP2 factor
 {
   term* ptr;
   ptr = malloc( sizeof(term) );
   ptr->factor1 = $1;
   ptr->op2 = $2;
   ptr->factor2 = $3;
   $$ = ptr;
 }
 | factor
 {
   term* ptr;
   ptr = malloc( sizeof(term) );
   ptr->factor1 = $1;
   ptr->factor2 = (factor *) NULL;
   $$ = ptr;
 }
 ;

factor : ident
 {
   factorValue* valuePtr;
   valuePtr = malloc( sizeof(factorValue) );
   valuePtr->ident = strdup($1);

   factor* ptr;
   ptr = malloc( sizeof(factor) );
   ptr->type = 0;
   ptr->value = valuePtr;

   $$ = ptr;
 }
 | num
 {
   factorValue* valuePtr;
   valuePtr = malloc( sizeof(factorValue) );
   valuePtr->num = $1;

   factor* ptr;
   ptr = malloc( sizeof(factor) );
   ptr->type = 1;
   ptr->value = valuePtr;

   $$ = ptr;
 }
 | boollit
 {
   factorValue* valuePtr;
   valuePtr = malloc( sizeof(factorValue) );
   valuePtr->boollit = $1;

   factor* ptr;
   ptr = malloc( sizeof(factor) );
   ptr->type = 2;
   ptr->value = valuePtr;

   $$ = ptr;
 }
 | LP expression RP
 {
   factorValue* valuePtr;
   valuePtr = malloc( sizeof(factorValue) );
   valuePtr->expr = $2;

   factor* ptr;
   ptr = malloc( sizeof(factor) );
   ptr->type = 3;
   ptr->value = valuePtr;

   $$ = ptr;
 }
 ;
%%

int main() {
    int value = yyparse();

    return value;
}

void printSpaces() {
    for (int i = spaces; i > 0; i--) {
        printf(" ");
    }
}

void generateDeclarations(declaration *declarations) {
    while (declarations != NULL) {
        printSpaces();
        if (declarations->type == 0) {
            printf("int %s = 0;\n", declarations->ident);
        }
        else if (declarations->type == 1) {
            printf("bool %s = false;\n", declarations->ident);
        }
        else {
            fprintf(stderr, "error on line %d:\tinvalid declaration type\n", lines); exit(1);
        }
        declarations = declarations->rest;
    }
}

void generateStatementSequence(statementSequence *sequence) {
    while (sequence != NULL) {
        printSpaces();
        generateStatement(sequence->stmt);
        sequence = sequence->rest;
    }
}

void generateStatement(statement *ptr) {
    if (ptr->type == 0) {
        generateAssignment((assignment *) ptr->stmtPtr);
    }
    else if (ptr->type == 1) {
        generateIfStatement((ifStatement *) ptr->stmtPtr);
    }
    else if (ptr->type == 2) {
        generateWhileStatement((whileStatement *) ptr->stmtPtr);
    }
    else if (ptr->type == 3) {
        generateWriteInt((writeInt *) ptr->stmtPtr);
    }
    else {
        fprintf(stderr, "error on line %d:\tinvalid statement type\n", lines); exit(1);
    }
}

void generateAssignment(assignment *ptr) {
    if (ptr->expr == NULL) {
        printf("scanf( \"%%d\", &%s );\n", ptr->ident);
    }
    else {
        printf("%s = ", ptr->ident);
        generateExpression(ptr->expr);
        printf(";\n");
    }
}

void generateIfStatement(ifStatement *ptr) {
    printf("if ( ");
    generateExpression(ptr->expr);
    printf(" ) {\n");
    spaces = spaces + spacesIncrement;
    generateStatementSequence(ptr->stmtSeq);
    spaces = spaces - spacesIncrement;
    printSpaces();
    printf("}\n");
    if (ptr->elseCl != (elseClause *) NULL)
        generateElseStatement(ptr->elseCl);
}

void generateElseStatement(elseClause *ptr) {
    printSpaces();
    printf("else {\n");
    spaces = spaces + spacesIncrement;
    generateStatementSequence(ptr->stmtSeq);
    spaces = spaces - spacesIncrement;
    printSpaces();
    printf("}\n");
}

void generateWhileStatement(whileStatement *ptr) {
    printf("while ( ");
    generateExpression(ptr->expr);
    printf(" ) {\n");
    spaces = spaces + spacesIncrement;
    generateStatementSequence(ptr->stmtSeq);
    spaces = spaces - spacesIncrement;
    printSpaces();
    printf("}\n");
}

void generateWriteInt(writeInt *ptr) {
    printf("printf( \"%%d\\n\", ");
    generateExpression(ptr->expr);
    printf(" );\n");
}

void generateExpression(expression *ptr) {
    if (ptr->sExpr2 == NULL) {
        generateSimpleExpression(ptr->sExpr1);
    }
    else {
        generateSimpleExpression(ptr->sExpr1);
        if (ptr->op4[0] == '=')
            printf(" == ");
        else
            printf(" %s ", ptr->op4);
        generateSimpleExpression(ptr->sExpr2);
    }
}

void generateSimpleExpression(simpleExpression *ptr) {
    if (ptr->term2 == NULL) {
        generateTerm(ptr->term1);
    }
    else {
        generateTerm(ptr->term1);
        printf(" %s ", ptr->op3);
        generateTerm(ptr->term2);
    }
}

void generateTerm(term *ptr) {
    if (ptr->factor2 == NULL) {
        generateFactor(ptr->factor1);
    }
    else {
        generateFactor(ptr->factor1);
        if (strcmp(ptr->op2, "div") == 0)
            printf(" / ");
        else if (strcmp(ptr->op2, "mod") == 0)
            printf(" %% ");
        else
            printf(" %s ", ptr->op2);
        generateFactor(ptr->factor2);
    }
}

void generateFactor(factor *ptr) {
    if (ptr->type == 0) {
        printf("%s", ptr->value->ident);
    }
    else if (ptr->type == 1) {
        printf("%li", ptr->value->num);
    }
    else if (ptr->type == 2) {
        if (ptr->value->boollit)
            printf("true");
        else
            printf("false");
    }
    else if (ptr->type == 3) {
        printf("( ");
        generateExpression(ptr->value->expr);
        printf(" )");
    }
    else {
        fprintf(stderr, "error on line %d:\tinvalid factor type\n", lines); exit(1);
    }
}
