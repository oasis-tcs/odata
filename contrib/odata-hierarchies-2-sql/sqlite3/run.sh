#! /bin/bash

SQLCLI_BIN=sqlite3 # take it from $PATH
[ ! -z "$(which $SQLCLI_BIN)" ] || { echo "$SQLCLI_BIN missing. Stop."; exit 1; }

echo "using $SQLCLI_BIN version $($SQLCLI_BIN -version)"
echo ""


DBFILE="/tmp/db.$$"
[ $# -eq 1 ] || { echo "Usage: $0 <sql-file>"; exit 1; }
"$SQLCLI_BIN" "$DBFILE" -cmd ".echo on" ".read \"$1\""
rm -f "$DBFILE"

