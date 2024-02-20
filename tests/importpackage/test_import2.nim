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
  ./test_sql_import_with_deletemarkers as sqlUno,
  ./test_sql_import_with_deletemarkers2 as sqlDos


suite "delete marker - package import - first import sqlUno":

  test "useDeleteMarker = tasks":
    var test: SqlQuery

    test = sqlUno.sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))

  test "useDeleteMarker = tasks (const)":
    var test: SqlQuery

    test = sqlUno.sqlSelectConst(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      joinargs  = []
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))


suite "delete marker - package import - second import sqlDos":

  test "useDeleteMarker = project":
    var test: SqlQuery

    test = sqlDos.sqlSelect(
      table     = "project",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM project WHERE id = ? AND project.is_deleted IS NULL "))

  test "useDeleteMarker = project (const)":
    var test: SqlQuery

    test = sqlDos.sqlSelectConst(
      table     = "project",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      joinargs  = []
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM project WHERE id = ? AND project.is_deleted IS NULL "))

