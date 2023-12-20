
#
# This sets a global delete marker
#


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


suite "select with tablesWithDeleteMarkerInit init":

  test "constants":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id ="],
      joinargs  = [noJoin],
      useDeleteMarker = true
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))


  test "dynamic":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id ="],
      joinargs  = [noJoin],
      useDeleteMarker = true
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))
