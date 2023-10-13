# Copyright Thomas T. Jarløv (TTJ)

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






suite "test sqlSelect":

  test "hideIsDeleted = false":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))


  test "from using AS ":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? "))


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = @["t.id ="],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT t.id, t.name, t.description, t.created, t.updated, t.completed FROM tasks AS t WHERE t.id = ? "))


  test "WHERE statements: general":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND updated > ? AND completed IS ? AND description LIKE ? "))
    check string(test).count("?") == 5


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      customSQL = "AND name != 'test' AND created > ? ",
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND updated > ? AND completed IS ? AND description LIKE ? AND name != 'test' AND created > ? "))
    check string(test).count("?") == 6



  test "WHERE statements: = ANY(...)":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "ids_array"],
      where     = @["id =", "= ANY(ids_array)"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? = ANY(ids_array) "))
    check string(test).count("?") == 2



  test "WHERE statements: x IN y":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "ids_array"],
      where     = @["id =", "IN (ids_array)"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? IN (ids_array) "))
    check string(test).count("?") == 2


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "ids_array"],
      where     = @["id =", "id IN"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND id IN (?) "))
    check string(test).count("?") == 2



  test "WHERE statements: `is NULL` ":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name != NULL", "description = NULL"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != NULL AND description = NULL "))
    check string(test).count("?") == 1


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "description = NULL"],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND description = NULL "))
    check string(test).count("?") == 2



suite "test sqlSelect - joins":

  test "LEFT JOIN using AS values":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "p", on: @["p.id = t.project_id", "p.status = 1"])],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects AS p ON (p.id = t.project_id AND p.status = 1) WHERE id = ? "))

  test "LEFT JOIN (default)":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))


  test "INNER JOIN":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      jointype  = INNER,
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t INNER JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))



suite "test sqlSelect - deletemarkers / softdelete":


  test "deletemarkers from seq":
    var test: SqlQuery
    let tableWithDeleteMarkerLet = @["tasks", "history", "tasksitems"]

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))



    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "history", tableAs: "", on: @["history.id = tasks.hid"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid) WHERE id = ? AND tasks.is_deleted IS NULL AND history.is_deleted IS NULL "))



    test = sqlSelect(
      table     = "tasks",
      select    = @["tasks.id", "tasks.name"],
      where     = @["tasks.id ="],
      joinargs  = @[(table: "history", tableAs: "his", on: @["his.id = tasks.hid"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet
    )
    check querycompare(test, sql("SELECT tasks.id, tasks.name FROM tasks LEFT JOIN history AS his ON (his.id = tasks.hid) WHERE tasks.id = ? AND tasks.is_deleted IS NULL AND his.is_deleted IS NULL "))



  test "deletemarkers on the fly":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = @["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))



  test "custom deletemarker override":
    var test: SqlQuery
    let tableWithDeleteMarkerLet = @["tasks", "history", "tasksitems"]

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "history", tableAs: "", on: @["history.id = tasks.hid"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet,
      deleteMarker = ".deleted_at = 543234563"
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid) WHERE id = ? AND tasks.deleted_at = 543234563 AND history.deleted_at = 543234563 "))



  test "complex query":
    var test: SqlQuery

    let tableWithDeleteMarkerLet = @["tasks", "history", "tasksitems"]


    test = sqlSelect(
      table     = "tasksitems",
      tableAs   = "tasks",
      select    = @[
          "tasks.id",
          "tasks.name",
          "tasks.status",
          "tasks.created",
          "his.id",
          "his.name",
          "his.status",
          "his.created",
          "projects.id",
          "projects.name",
          "person.id",
          "person.name",
          "person.email"
        ],
      where     = @[
          "projects.id =",
          "tasks.status >"
        ],
      joinargs  = @[
          (table: "history", tableAs: "his", on: @["his.id = tasks.hid", "his.status = 1"]),
          (table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"]),
          (table: "person", tableAs: "", on: @["person.id = tasks.person_id"])
        ],
      whereInField = "tasks.id",
      whereInValue = @["1", "2", "3"],
      customSQL = "ORDER BY tasks.created DESC",
      tablesWithDeleteMarker = tableWithDeleteMarkerLet
    )
    check querycompare(test, (sql("""
        SELECT
          tasks.id,
          tasks.name,
          tasks.status,
          tasks.created,
          his.id,
          his.name,
          his.status,
          his.created,
          projects.id,
          projects.name,
          person.id,
          person.name,
          person.email
        FROM
          tasksitems AS tasks
        LEFT JOIN history AS his ON
          (his.id = tasks.hid AND his.status = 1)
        LEFT JOIN projects ON
          (projects.id = tasks.project_id AND projects.status = 1)
        LEFT JOIN person ON
          (person.id = tasks.person_id)
        WHERE
              projects.id = ?
          AND tasks.status > ?
          AND tasks.id in (1,2,3)
          AND tasks.is_deleted IS NULL
          AND his.is_deleted IS NULL
        ORDER BY
          tasks.created DESC
      """)))





