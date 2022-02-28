%{
#include <string.h>
#include "y.tab.h"

extern int yylex();
extern void yyerror(const char* s);

int lines = 1;

int checkOverflow(char *);
%}

%option noinput
%option nounput
%option noyywrap

%%
[ \f\r\t\v]                 ; // whitespace

\n                          lines++;

"%".*                       ; // comment

[1-9][0-9]*|0               {
                                if (checkOverflow(yytext) == 0) {
                                    yylval.ival = atol(yytext);
                                    return num;
                                }
                                else {
                                    fprintf(stderr, "error on line %d:\tillegal number '%s'\n", lines, yytext); exit(1);
                                }
                            }
false|true                  {
                                if ( strcmp(yytext, "true") )
                                    yylval.ival = 0;
                                else
                                    yylval.ival = 1;
                                return boollit;
                            }
[A-Z][A-Z0-9]*              {
                                yylval.sval = strdup(yytext);
                                return ident;
                            }

"("                         return LP;
")"                         return RP;
":="                        return ASGN;
";"                         return SC;

"*"|"div"|"mod"             {
                                yylval.sval = strdup(yytext);
                                return OP2;                 
                            }
"+"|"-"                     {
                                yylval.sval = strdup(yytext);
                                return OP3;
                            }
"="|"!="|"<"|">"|"<="|">="  {
                                yylval.sval = strdup(yytext);
                                return OP4;
                            }

"if"                        return IF;
"then"                      return THEN;
"else"                      return ELSE;
"begin"                     return BEGIN_TOKEN;
"end"                       return END;
"while"                     return WHILE;
"do"                        return DO;
"program"                   return PROGRAM;
"var"                       return VAR;
"as"                        return AS;
"int"                       return INT;
"bool"                      return BOOL;

"writeInt"                  return WRITEINT;
"readInt"                   return READINT;

.                           {
                              fprintf(stderr, "error on line %d:\tunknown character '%c'\n", lines, yytext[0]); exit(1);
                            }
%%

int checkOverflow(char *num) {
    int length = strlen(num);

    if (length > 10)
        return 1;

    long long longNum = atoll(num);

    if (longNum > 2147483647)
        return 1;

    return 0;
}
