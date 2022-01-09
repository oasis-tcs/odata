#! /bin/bash

SQLCLI_BIN=hdbsql # take it from $PATH
[ ! -z "$(which $SQLCLI_BIN)" ] || { echo "$SQLCLI_BIN missing. Stop."; exit 1; }

echo "using $SQLCLI_BIN version $($SQLCLI_BIN -v)"
echo ""

[ $# -eq 2 ] || { echo "$0 <userstore-key> <sql-file>"; exit 1; }

COMPOUND_SQL_FILE="/tmp/sqlscript.$$"
cat create-schema.sql "$2" > "$COMPOUND_SQL_FILE"
"$SQLCLI_BIN" -U "$1" -f -I "$COMPOUND_SQL_FILE"
rm -f "$COMPOUND_SQL_FILE"


