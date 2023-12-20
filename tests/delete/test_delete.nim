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



