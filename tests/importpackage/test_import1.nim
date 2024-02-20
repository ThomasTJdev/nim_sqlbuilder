# Copyright Thomas T. Jarløv (TTJ)

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilderpkg/utils_private

import
  ./test_sql_import_with_deletemarkers


suite "delete marker - package import":

  test "useDeleteMarker = default":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))

  test "useDeleteMarker = default":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      joinargs  = []
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))
