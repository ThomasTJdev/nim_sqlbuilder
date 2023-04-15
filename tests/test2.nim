# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk



import src/sqlbuilderpkg/insert
export insert

import src/sqlbuilderpkg/update
export update

import src/sqlbuilderpkg/delete
export delete

import src/sqlbuilderpkg/utils
export utils

const tablesWithDeleteMarker = ["tasks", "persons"]

include src/sqlbuilderpkg/select


import std/unittest


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



suite "test sqlSelect":

  test "set tablesWithDeleteMarker":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))


suite "test sqlSelectConst":

  test "set tablesWithDeleteMarker":

    let a = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"], #tableWithDeleteMarker
    )



suite "test sqlSelect(converter) legacy":

  test "set tablesWithDeleteMarker":


    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "double delete":


    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id", "persons ON persons.id = tasks.person_id AND persons.is_deleted IS NULL"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        LEFT JOIN persons ON
          (persons.id = tasks.person_id AND persons.is_deleted IS NULL AND persons.is_deleted IS NULL)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))