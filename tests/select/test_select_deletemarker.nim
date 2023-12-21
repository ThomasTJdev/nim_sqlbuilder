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


const tablesWithDeleteMarkerInit = ["tasks"]

include src/sqlbuilder_include


suite "sqlSelect - delete marker const":

  test "useDeleteMarker = default":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      # useDeleteMarker = true
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))


  test "useDeleteMarker = true":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      useDeleteMarker = true
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))


  test "useDeleteMarker = false":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))


