# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import
    db_connector/db_common
else:
  import
    std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilder

proc querycompare(a, b: SqlQuery): bool =
  var
    a1: seq[string]
    b1: seq[string]
  for c in splitWhitespace(string(a)):
    a1.add($c)
  for c in splitWhitespace(string(b)):
    b1.add($c)

  if a1 != b1:
    echo ""
    echo "a1: ", string(a)
    echo "b1: ", string(b).replace("\n", " ").splitWhitespace().join(" ")
    echo ""

  return a1 == b1


suite "insert":

  test "sqlInsert - dynamic columns":
    var test: SqlQuery

    let (s, a1) = genArgsColumns((true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    test = sqlInsert("my-table", s, a1.query)
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, ?)"))


  test "sqlInsert - setting null":
    var test: SqlQuery

    let a2 = genArgsSetNull("hje", "")
    test = sqlInsert("my-table", ["name", "age"], a2.query)
    # discard tryInsertID(sqlInsert("my-table", ["name", "age"], a2.query), a2.args)
    check querycompare(test, sql("INSERT INTO my-table (name) VALUES (?)"))