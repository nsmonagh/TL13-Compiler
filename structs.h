#ifndef STRUCTS_H
#define STRUCTS_H

#include <stdbool.h>

#include "uthash.h"


typedef struct expression expression;

typedef struct statementSequence statementSequence;

typedef struct declaration declaration;


typedef union factorValue {

    char* ident;

    long num;

    bool boollit;

    expression* expr;

} factorValue;


typedef struct {

    int type;

    factorValue* value;

} factor;


typedef struct {

    factor* factor1;

    factor* factor2;

    char* op2;

} term;


typedef struct {

    term* term1;

    term* term2;

    char* op3;

} simpleExpression;


struct expression {

    simpleExpression* sExpr1;

    simpleExpression* sExpr2;

    char* op4;

};


typedef struct {

    expression* expr;

} writeInt;


typedef struct {

    expression* expr;

    statementSequence* stmtSeq;

} whileStatement;


typedef struct {

    statementSequence* stmtSeq;

} elseClause;


typedef struct {

    expression* expr;

    statementSequence* stmtSeq;

    elseClause* elseCl;

} ifStatement;


typedef struct {

    char* ident;

    expression* expr;

} assignment;


typedef struct {

    int type;

    void *stmtPtr;

} statement;


struct statementSequence {

    statement* stmt;

    statementSequence* rest;

};


struct declaration {

    char* ident;

    int type;

    declaration* rest;

};

typedef struct {

    char* name;

    int type;

    UT_hash_handle hh;

} symbol;


#endif /* STRUCTS_H */
