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


suite "delete - normal":

  test "sqlDelete":
    var test: SqlQuery

    test = sqlDelete("my-table", ["name", "age"])
    check querycompare(test, sql("DELETE FROM my-table WHERE name = ? AND age = ?"))

    test = sqlDelete("my-table", [])
    check querycompare(test, sql("DELETE FROM my-table"))


  test "sqlDeleteWhere":
    var test: SqlQuery

    test = sqlDelete("my-table", ["name !=", "age > "])
    check querycompare(test, sql("DELETE FROM my-table WHERE name != ? AND age > ?"))


  test "sqlDelete with null manually":
    var test: SqlQuery

    test = sqlDelete("my-table", ["name IS NULL", "age"])
    check querycompare(test, sql("DELETE FROM my-table WHERE name IS NULL AND age = ?"))




suite "delete - macro":

  test "sqlDelete":
    var test: SqlQuery

    test = sqlDeleteMacro("my-table", ["name", "age"])
    check querycompare(test, sql("DELETE FROM my-table WHERE name = ? AND age = ?"))


  test "sqlDeleteWhere":
    var test: SqlQuery

    test = sqlDeleteMacro("my-table", ["name !=", "age > "])
    check querycompare(test, sql("DELETE FROM my-table WHERE name != ? AND age > ?"))


  test "sqlDelete with null manually":
    var test: SqlQuery

    test = sqlDeleteMacro("my-table", ["name IS NULL", "age"])
    check querycompare(test, sql("DELETE FROM my-table WHERE name IS NULL AND age = ?"))


suite "delete - genArgs":

  test "sqlDelete with genArgs":

    var a = genArgs("123", dbNullVal)

    var test = sqlDelete("tasksQQ", ["id =", "status IS"], a.query)

    check querycompare(test, sql("""DELETE FROM tasksQQ WHERE id = ? AND status IS ?"""))



    a = genArgs("123", dbNullVal, dbNullVal)

    test = sqlDelete("tasksQQ", ["id =", "status IS NOT", "phase IS"], a.query)

    check querycompare(test, sql("""DELETE FROM tasksQQ WHERE id = ? AND status IS NOT ? AND phase IS ?"""))



  test "sqlDelete with genArgsSetNull":

    var a = genArgsSetNull("123", "", "")

    var test = sqlDelete("tasksQQ",  ["id =", "status IS NOT", "phase IS"],  a.query)

    check querycompare(test, sql("""DELETE FROM tasksQQ WHERE id = ? AND status IS NOT ? AND phase IS ?"""))


