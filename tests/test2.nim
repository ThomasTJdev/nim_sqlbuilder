# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk



# import src/sqlbuilderpkg/insert
# export insert

# import src/sqlbuilderpkg/update
# export update

# import src/sqlbuilderpkg/delete
# export delete

# import src/sqlbuilderpkg/utils
# export utils

import std/unittest
const tablesWithDeleteMarkerInit = ["tasks", "persons"]

include src/sqlbuilder_include




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



suite "test sqlSelect with inline NULL":

  test "set tablesWithDeleteMarker":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name = NULL"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? AND name = NULL "))



suite "test sqlSelectConst":

  test "set tablesWithDeleteMarker":

    let a = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      # joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"]), (table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      where     = ["t.id ="],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"], #tableWithDeleteMarker
    )

