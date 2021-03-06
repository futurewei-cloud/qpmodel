/*
MIT License

Copyright (c) 2012-2017 Hasso-Plattner-Institut

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR

IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
/*
 * revised for andb 
 */
 /**
 * lexer
 *
 *
 */


/***************************
 ** Section 1: Definitions
 ***************************/
%{

#include <cstdio>
#include <cstring>

#include <stdint.h>

#include <locale>
#include <vector>
#include <iostream>
#include <sstream>
#include <new>

#include "common/common.h"
#include "common/dbcommon.h"
#include "parser/include/expr.h"
#include "parser/include/stmt.h"
#include "optimizer/binder.h"
#include "parser/include/sqlparserresult.h"
#include "parser/include/parser_typedef.h"

#include "andb_parser.h"

using namespace andb;

#define TOKEN(name) { return SQL_##name; }

static thread_local std::stringstream strbuf;

%}
%x singlequotedstring

/***************************
 ** Section 2: Rules
 ***************************/

/* Define the output files */
%option header-file="flex_lexer.h"
%option outfile="flex_lexer.cpp"

/* Make reentrant */
%option reentrant
%option bison-bridge

/* performance tweeks */
%option never-interactive
%option batch

/* other flags */
%option noyywrap
%option nounput
%option warn
%option case-insensitive
%option prefix="andb_"
%option bison-locations
/* %option nodefault */


%s COMMENT

/***************************
 ** Section 3: Rules
 ***************************/
%%

--				BEGIN(COMMENT);
<COMMENT>[^\n]*	/* skipping comment content until a end of line is read */;
<COMMENT>\n 	BEGIN(INITIAL);

[ \t\n]+	/* skip whitespace */;

DEALLOCATE	TOKEN(DEALLOCATE)
PARAMETERS	TOKEN(PARAMETERS)
INTERSECT	TOKEN(INTERSECT)
TEMPORARY	TOKEN(TEMPORARY)
TIMESTAMP	TOKEN(TIMESTAMP)
DESCRIBE	TOKEN(DESCRIBE)
DISTINCT	TOKEN(DISTINCT)
NVARCHAR	TOKEN(NVARCHAR)
RESTRICT	TOKEN(RESTRICT)
TRUNCATE	TOKEN(TRUNCATE)
ANALYZE		TOKEN(ANALYZE)
BETWEEN		TOKEN(BETWEEN)
CASCADE		TOKEN(CASCADE)
COLUMNS		TOKEN(COLUMNS)
CONTROL		TOKEN(CONTROL)
DEFAULT		TOKEN(DEFAULT)
EXECUTE		TOKEN(EXECUTE)
EXPLAIN		TOKEN(EXPLAIN)
INTEGER		TOKEN(INTEGER)
NATURAL		TOKEN(NATURAL)
PREPARE		TOKEN(PREPARE)
PRIMARY		TOKEN(PRIMARY)
SCHEMAS		TOKEN(SCHEMAS)
SPATIAL		TOKEN(SPATIAL)
VARCHAR		TOKEN(VARCHAR)
VIRTUAL		TOKEN(VIRTUAL)
BEFORE		TOKEN(BEFORE)
COLUMN		TOKEN(COLUMN)
CREATE		TOKEN(CREATE)
DELETE		TOKEN(DELETE)
DIRECT		TOKEN(DIRECT)
DOUBLE		TOKEN(DOUBLE)
ESCAPE		TOKEN(ESCAPE)
EXCEPT		TOKEN(EXCEPT)
EXISTS		TOKEN(EXISTS)
EXTRACT 	TOKEN(EXTRACT)
CAST		TOKEN(CAST)
FORMAT		TOKEN(FORMAT)
GLOBAL		TOKEN(GLOBAL)
HAVING		TOKEN(HAVING)
IMPORT		TOKEN(IMPORT)
INSERT		TOKEN(INSERT)
ISNULL		TOKEN(ISNULL)
OFFSET		TOKEN(OFFSET)
RENAME		TOKEN(RENAME)
SCHEMA		TOKEN(SCHEMA)
SELECT		TOKEN(SELECT)
SORTED		TOKEN(SORTED)
TABLES		TOKEN(TABLES)
UNIQUE		TOKEN(UNIQUE)
UNLOAD		TOKEN(UNLOAD)
UPDATE		TOKEN(UPDATE)
VALUES		TOKEN(VALUES)
AFTER		TOKEN(AFTER)
ALTER		TOKEN(ALTER)
ARRAY		TOKEN(ARRAY)
CROSS		TOKEN(CROSS)
DELTA		TOKEN(DELTA)
FLOAT		TOKEN(FLOAT)
GROUP		TOKEN(GROUP)
INDEX		TOKEN(INDEX)
INNER		TOKEN(INNER)
LIMIT		TOKEN(LIMIT)
LOCAL		TOKEN(LOCAL)
MERGE		TOKEN(MERGE)
MINUS		TOKEN(MINUS)
ORDER		TOKEN(ORDER)
OUTER		TOKEN(OUTER)
RIGHT		TOKEN(RIGHT)
TABLE		TOKEN(TABLE)
UNION		TOKEN(UNION)
USING		TOKEN(USING)
WHERE		TOKEN(WHERE)
CALL		TOKEN(CALL)
CASE		TOKEN(CASE)
CHAR		TOKEN(CHAR)
COPY		TOKEN(COPY)
DATE		TOKEN(DATE)
DATETIME	TOKEN(DATETIME)
DESC		TOKEN(DESC)
DROP		TOKEN(DROP)
ELSE		TOKEN(ELSE)
FILE		TOKEN(FILE)
FROM		TOKEN(FROM)
FULL		TOKEN(FULL)
HASH		TOKEN(HASH)
HINT		TOKEN(HINT)
INTO		TOKEN(INTO)
JOIN		TOKEN(JOIN)
LEFT		TOKEN(LEFT)
LIKE		TOKEN(LIKE)
ILIKE		TOKEN(ILIKE)
LOAD		TOKEN(LOAD)
LONG		TOKEN(LONG)
NULL		TOKEN(NULL)
PLAN		TOKEN(PLAN)
SHOW		TOKEN(SHOW)
TEXT		TOKEN(TEXT)
THEN		TOKEN(THEN)
TIME		TOKEN(TIME)
VIEW		TOKEN(VIEW)
WHEN		TOKEN(WHEN)
WITH		TOKEN(WITH)
ADD			TOKEN(ADD)
ALL			TOKEN(ALL)
AND			TOKEN(AND)
ASC			TOKEN(ASC)
END			TOKEN(END)
FOR			TOKEN(FOR)
INT			TOKEN(INT)
KEY			TOKEN(KEY)
NOT			TOKEN(NOT)
OFF			TOKEN(OFF)
SET			TOKEN(SET)
TOP			TOKEN(TOP)
AS			TOKEN(AS)
BY			TOKEN(BY)
IF			TOKEN(IF)
IN			TOKEN(IN)
IS			TOKEN(IS)
OF			TOKEN(OF)
ON			TOKEN(ON)
OR			TOKEN(OR)
TO			TOKEN(TO)
SECOND      TOKEN(SECOND)
MINUTE      TOKEN(MINUTE)
HOUR        TOKEN(HOUR)
DAY         TOKEN(DAY)
MONTH       TOKEN(MONTH)
YEAR        TOKEN(YEAR)
TRUE		TOKEN(TRUE)
FALSE		TOKEN(FALSE)
TRANSACTION TOKEN(TRANSACTION)
BEGIN       TOKEN(BEGIN)
ROLLBACK    TOKEN(ROLLBACK)
COMMIT      TOKEN(COMMIT)

                /* Allow =/== see https://sqlite.org/lang_expr.html#collateop */
"=="		TOKEN(EQUALS)
"!=" 		TOKEN(NOTEQUALS)
"<>" 		TOKEN(NOTEQUALS)
"<="		TOKEN(LESSEQ)
">="		TOKEN(GREATEREQ)
"||"		TOKEN(CONCAT)

[-+*/(){},.;<>=^%:?[\]|]	{ return yytext[0]; }

-?[0-9]+"."[0-9]* |
"."[0-9]*	{
	yylval->fval = atof(yytext);
	return SQL_FLOATVAL;
}

-?[0-9]+	{
	yylval->ival = atol(yytext);
	return SQL_INTVAL;
}

\"[^\"\n]+\" {
	// Crop the leading and trailing quote char
	char *str = andb::substr(yytext, 1, strlen(yytext)-1);
	yylval->sval = new std::string(str);
   delete str;
#ifdef __DEBUG_PARSER_MEMLEAK
   std::cout << __FILE__ << " " << __LINE__ << " LEX ID " << yylval->sval << " PTR " << (void*)yylval->sval << std::endl;
#endif
	return SQL_IDENTIFIER;
}

[A-Za-z][A-Za-z0-9_]* {
	yylval->sval = new std::string(yytext);
#ifdef __DEBUG_PARSER_MEMLEAK
   std::cout << __FILE__ << " " << __LINE__ << " LEX ID " << yylval->sval << " PTR " << (void*)yylval->sval << std::endl;
#endif
	return SQL_IDENTIFIER;
}

\'                          { BEGIN singlequotedstring; strbuf = std::stringstream{}; }
<singlequotedstring>\'\'    { strbuf << '\''; }
<singlequotedstring>[^']*   { strbuf << yytext; }
<singlequotedstring>\'      {
                              BEGIN 0;
                              yylval->sval = new std::string(strbuf.str().c_str());
#ifdef __DEBUG_PARSER_MEMLEAK
                             std::cout << __FILE__ << " " << __LINE__ << " LEX SQSTR " << yylval->sval << " PTR " << (void*)yylval->sval << std::endl;
#endif
                              return SQL_STRING;
                            }
<singlequotedstring><<EOF>> { fprintf(stderr, "[SQL-Lexer-Error] Unterminated string\n"); return 0; }

. { fprintf(stderr, "[SQL-Lexer-Error] Unknown Character: %c\n", yytext[0]); return 0; }


%%
/***************************
 ** Section 3: User code
 ***************************/

int yyerror(const char *msg) {
    fprintf(stderr, "[SQL-Lexer-Error] %s\n",msg); return 0;
}
