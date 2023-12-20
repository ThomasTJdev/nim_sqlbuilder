# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk


when NimMajor >= 2:
  import db_connector/db_sqlite
else:
  import std/db_sqlite

import
  std/logging,
  std/strutils,
  std/unittest

import
  src/sqlbuilderpkg/query_calls

import
  tests/create_db


var consoleLog = newConsoleLogger()
addHandler(consoleLog)



#
# Set up a test database
#
createDB()
let db = openDB()

for i in 1..5:
  db.exec(sql("INSERT INTO my_table (name, age, ident, is_nimmer) VALUES (?, ?, ?, ?)"), "Call-" & $i, $i, "Call", (if i <= 2: "true" else: "false"))



suite "Query calls":

  test "getRowTry() - with match":
    let row = getRowTry(db, sql("SELECT name, age, ident, is_nimmer FROM my_table WHERE name = ?"), ["Call-1"])
    check row == @["Call-1", "1", "Call", "true"]

  test "getRowTry() - without match":
    let row = getRowTry(db, sql("SELECT name, age, ident, is_nimmer FROM my_table WHERE name = ?"), ["Call-"])
    check row == @["", "", "", ""]

  test "getRowTry() - missing args":
    let row = getRowTry(db, sql("SELECT name, age, ident, is_nimmer FROM my_table WHERE name = ?"), [])
    check row.len() == 0

  test "getRowTry() - missing args auto fill":
    let row = getRowTry(db, sql("SELECT name, age, ident, is_nimmer FROM my_table WHERE name = ?"), [], fillIfNull = 4)
    check row == @["", "", "", ""]