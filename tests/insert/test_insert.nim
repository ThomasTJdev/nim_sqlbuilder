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
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private



suite "insert - custom args":

  test "sqlInsert - dynamic columns":
    var test: SqlQuery

    let (s, a1) = genArgsColumns(SQLQueryType.INSERT, (true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    test = sqlInsert("my-table", s, a1.query)
    check querycompare(test, sql("INSERT INTO my-table (age) VALUES (?)"))


  test "sqlInsert - setting null":
    var test: SqlQuery

    let a2 = genArgsSetNull("hje", "")
    test = sqlInsert("my-table", ["name", "age"], a2.query)
    check querycompare(test, sql("INSERT INTO my-table (name) VALUES (?)"))



suite "insert - default":

  test "sqlInsert - default":
    var test: SqlQuery

    test = sqlInsert("my-table", ["name", "age"])
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, ?)"))


  test "sqlInsert - with manual null":
    var test: SqlQuery

    test = sqlInsert("my-table", ["name", "age = NULL"])
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, NULL)"))


  test "sqlInsert - with args check for null #1":
    var test: SqlQuery

    let vals = @["thomas", "30"]
    test = sqlInsert("my-table", ["name", "age"], vals)
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, ?)"))


  test "sqlInsert - with args check for null #2":
    var test: SqlQuery

    let vals = @["thomas", ""]
    test = sqlInsert("my-table", ["name", "age"], vals)
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, NULL)"))


suite "insert - macro":

  test "sqlInsert - default":
    var test: SqlQuery

    test = sqlInsertMacro("my-table", ["name", "age"])
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, ?)"))


  test "sqlInsertMacro - with manual null":
    var test: SqlQuery

    test = sqlInsertMacro("my-table", ["name", "age = NULL"])
    check querycompare(test, sql("INSERT INTO my-table (name, age) VALUES (?, NULL)"))