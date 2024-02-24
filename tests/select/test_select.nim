# Copyright Thomas T. Jarløv (TTJ)

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private





suite "test sqlSelect":

  test "useDeleteMarker = false":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))


  test "from using AS ":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? "))


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = @["t.id ="],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT t.id, t.name, t.description, t.created, t.updated, t.completed FROM tasks AS t WHERE t.id = ? "))


  test "from using AS inline ":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks AS t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? "))



  test "WHERE statements: general":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND updated > ? AND completed IS ? AND description LIKE ? "))
    check string(test).count("?") == 5


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      customSQL = "AND name != 'test' AND created > ? ",
      useDeleteMarker = false
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
      useDeleteMarker = false
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
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? IN (ids_array) "))
    check string(test).count("?") == 2


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "ids_array"],
      where     = @["id =", "id IN"],
      useDeleteMarker = false
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
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != NULL AND description = NULL "))
    check string(test).count("?") == 1


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id =", "name !=", "description = NULL"],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND description = NULL "))
    check string(test).count("?") == 2



suite "test sqlSelect - joins":

  test "LEFT JOIN [no values] using empty []":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t WHERE id = ? "))

  test "LEFT JOIN [no values] using varargs instead of seq":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t WHERE id = ? "))

  test "LEFT JOIN using AS values with varargs":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "p", on: @["p.id = t.project_id", "p.status = 1"])],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects AS p ON (p.id = t.project_id AND p.status = 1) WHERE id = ? "))

  test "LEFT JOIN using AS values":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "p", on: @["p.id = t.project_id", "p.status = 1"])],
      useDeleteMarker = false
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
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))

  test "LEFT JOIN (default) from table as inline":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks AS t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      useDeleteMarker = false
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
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t INNER JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))

  test "CROSS JOIN":
    var test: SqlQuery

    test = sqlSelect(
      table     = "a",
      select    = @["id"],
      joinargs  = @[(table: "b", tableAs: "", on: @["a.id = b.id"])],
      jointype  = CROSS,
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id FROM a CROSS JOIN b ON (a.id = b.id)"))



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

    let tableWithDeleteMarkerLet = @["history", "tasksitems"]


    test = sqlSelect(
      table     = "tasksitems",
      tableAs   = "tasks",
      select    = [
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
      where     = [
          "projects.id =",
          "tasks.status >"
        ],
      joinargs  = [
          (table: "history", tableAs: "his", on: @["his.id = tasks.hid", "his.status = 1"]),
          (table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"]),
          (table: "person", tableAs: "", on: @["person.id = tasks.person_id"])
        ],
      whereInField = "tasks.id",
      whereInValue = ["1", "2", "3"],
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



suite "test where cases custom formatting":

  test "where OR":
    var test: SqlQuery

    const
      table     = "tasks"
      select    = ["id", "name", "description", "created", "updated", "completed"]
      where     = ["id = ? OR id = ?"]

    let
      resNormal   = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR id = ?) ")
      resPrepared = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = $1 OR id = $2) ")

    # Normal
    test = sqlSelect(
      table     = table,
      select    = select,
      where     = where,
      useDeleteMarker = false,
      usePrepared = false
    )
    check querycompare(test, resNormal)


    # Prepared
    test = sqlSelect(
      table     = table,
      select    = select,
      where     = where,
      useDeleteMarker = false,
      usePrepared = true
    )
    check querycompare(test, resPrepared)


    # Macro normal
    test = sqlSelectConst(
      table     = "tasks",
      select    = select,
      where     = where,
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = false
    )
    check querycompare(test, resNormal)


    # Macro prepared
    test = sqlSelectConst(
      table     = "tasks",
      select    = select,
      where     = where,
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = true
    )
    check querycompare(test, resPrepared)


  test "where OR OR":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id = ? OR name = ? OR description = ?"],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR name = ? OR description = ?) "))


  test "where OR OR parentheses":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id = ? OR (name = ? OR description = ?)"],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR (name = ? OR description = ?)) "))


  test "where AND OR parentheses":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id = ? AND (name = ? OR description = ?)"],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? AND (name = ? OR description = ?)) "))


  test "where OR OR parentheses AND ? = ANY(...)":
    var test: SqlQuery
    const
      table     = "tasks"
      select    = @["id", "name", "description", "created", "updated", "completed"]
      where     = @["id = ? OR (name = ? OR description = ?) AND ? = ANY(ids_array)"]

    let
      resNormal   = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR (name = ? OR description = ?) AND ? = ANY(ids_array)) ")
      resPrepared = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = $1 OR (name = $2 OR description = $3) AND $4 = ANY(ids_array)) ")

    test = sqlSelect(
      table     = table,
      select    = select,
      where     = where,
      useDeleteMarker = false,
      usePrepared = false
    )
    check querycompare(test, resNormal)


    test = sqlSelect(
      table     = table,
      select    = select,
      where     = where,
      useDeleteMarker = false,
      usePrepared = true
    )
    check querycompare(test, resPrepared)


  test "where x = 'y'":

    let test = sqlSelect(
      table   = "history",
      tableAs = "h",
      select  = [
        "h.uuid",
        "h.text",
        "h.creation",
        "person.name"
      ],
      where = [
        "h.project_id =",
        "h.item_id =",
        "h.element = 'tasks'",
      ],
      joinargs = [
        (table: "person", tableAs: "person", on: @["person.id = h.user_id"]),
      ],
      customSQL = "ORDER BY h.creation DESC",
    )

    check querycompare(test, sql("SELECT h.uuid, h.text, h.creation, person.name FROM history AS h LEFT JOIN person ON (person.id = h.user_id) WHERE h.project_id = ? AND h.item_id = ? AND h.element = 'tasks' ORDER BY h.creation DESC"))


  test "where x = 'y' and x = 'y' and x = ::int":

    let test = sqlSelect(
      table   = "history",
      tableAs = "h",
      select  = [
        "h.uuid",
        "h.text",
        "h.creation",
        "person.name"
      ],
      where = [
        "h.project_id =",
        "h.item_id = 33",
        "h.element = 'tasks'",
        "h.data = 'special'",
        "h.ident = 99",
      ],
      joinargs = [
        (table: "person", tableAs: "person", on: @["person.id = h.user_id"]),
      ],
      customSQL = "ORDER BY h.creation DESC",
    )

    check querycompare(test, sql("SELECT h.uuid, h.text, h.creation, person.name FROM history AS h LEFT JOIN person ON (person.id = h.user_id) WHERE h.project_id = ? AND h.item_id = 33 AND h.element = 'tasks' AND h.data = 'special' AND h.ident = 99 ORDER BY h.creation DESC"))



  test "where x = 'y' and x = 'y' and x = ::int with fake spaces":

    let test = sqlSelect(
      table   = "history",
      tableAs = "h",
      select  = [
        "h.uuid",
        "h.text",
        "h.creation",
        "person.name"
      ],
      where = [
        "h.project_id = ",
        "h.item_id =  ",
        "h.data   =     ",
        "h.ident   =   33   ",
      ],
      joinargs = [
        (table: "person", tableAs: "person", on: @["person.id = h.user_id"]),
      ],
      customSQL = "ORDER BY h.creation DESC",
    )

    check querycompare(test, sql("SELECT h.uuid, h.text, h.creation, person.name FROM history AS h LEFT JOIN person ON (person.id = h.user_id) WHERE h.project_id =  ? AND h.item_id =   ? AND h.data   =      ? AND h.ident   =   33    ORDER BY h.creation DESC"))



  test "where - complex where item - with parenthesis around":

    let test = sqlSelect(
      table = "history",
      tableAs = "history",
      select = [
        "person.name as user_id",
        "history.creation"
      ],
      where = [
        "history.project_id =",
        "history.item_id =",
        "history.is_deleted IS NULL",
        "(history.choice = 'Comment' OR history.choice = 'Picture' OR history.choice = 'File' OR history.choice = 'Design' OR history.choice = 'Update' OR history.choice = 'Create')"
      ],
      joinargs = [
        (table: "person", tableAs: "", on: @["history.user_id = person.id"])
      ],
      customSQL = "ORDER BY history.creation DESC, history.id DESC"
    )

    check querycompare(test, sql("SELECT person.name as user_id, history.creation FROM history LEFT JOIN person ON (history.user_id = person.id) WHERE history.project_id = ? AND history.item_id = ? AND history.is_deleted IS NULL AND (history.choice = 'Comment' OR history.choice = 'Picture' OR history.choice = 'File' OR history.choice = 'Design' OR history.choice = 'Update' OR history.choice = 'Create') ORDER BY history.creation DESC, history.id DESC"))



  test "where - complex where item - without parenthesis around":

    let test = sqlSelect(
      table = "history",
      tableAs = "history",
      select = [
        "person.name as user_id",
        "history.creation"
      ],
      where = [
        "history.project_id =",
        "history.item_id =",
        "history.is_deleted IS NULL",
        "history.choice = 'Comment' OR history.choice = 'Picture' OR history.choice = 'File' OR history.choice = 'Design' OR history.choice = 'Update' OR history.choice = 'Create'"
      ],
      joinargs = [
        (table: "person", tableAs: "", on: @["history.user_id = person.id"])
      ],
      customSQL = "ORDER BY history.creation DESC, history.id DESC"
    )

    check querycompare(test, sql("SELECT person.name as user_id, history.creation FROM history LEFT JOIN person ON (history.user_id = person.id) WHERE history.project_id = ? AND history.item_id = ? AND history.is_deleted IS NULL AND (history.choice = 'Comment' OR history.choice = 'Picture' OR history.choice = 'File' OR history.choice = 'Design' OR history.choice = 'Update' OR history.choice = 'Create') ORDER BY history.creation DESC, history.id DESC"))



suite "test using DB names for columns":

  test "info => in, nonull => null, anything => any":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id =", "user =", "info =", "IN info", "anything =", "IN nonull"],
    )
    check querycompare(test, sql(" SELECT id, name FROM tasks WHERE id = ? AND user = ? AND info = ? AND ? IN info AND anything = ? AND ? IN nonull"))




suite "catch bad formats":

  test "malicious ?":

    const mal = [
      "id = ?, AND ?",
      "id = ?, OR ?",
      "id = ? ?",
      "id = ? AND ?",
      "id = ? OR ?",
    ]

    for m in mal:
      check hasIllegalFormats(m) != ""





