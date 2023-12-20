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





suite "test sqlSelectConst":

  test "useDeleteMarker = false":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id ="],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))



  test "from using AS ":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id ="],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? "))


    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
      joinargs  = [],
      useDeleteMarker = false,
      customSQL = "ORDER BY t.created DESC"
    )
    check querycompare(test, sql("SELECT t.id, t.name, t.description, t.created, t.updated, t.completed FROM tasks AS t WHERE t.id = ? ORDER BY t.created DESC "))



  test "WHERE statements: general":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND updated > ? AND completed IS ? AND description LIKE ? "))
    check string(test).count("?") == 5


    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id =", "name !=", "updated >", "completed IS", "description LIKE"],
      joinargs  = [],
      customSQL = "AND name != 'test' AND created > ? ",
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND updated > ? AND completed IS ? AND description LIKE ? AND name != 'test' AND created > ? "))
    check string(test).count("?") == 6



  test "WHERE statements: = ANY(...)":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "ids_array"],
      where     = ["id =", "= ANY(ids_array)"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? = ANY(ids_array) "))
    check string(test).count("?") == 2



  test "WHERE statements: = ANY(...) multiple instances":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "ids_array"],
      where     = ["id =", "= ANY(ids_array)", "= ANY(user_array)", "= ANY(tasks_array)"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? = ANY(ids_array) AND ? = ANY(user_array) AND ? = ANY(tasks_array) "))
    check string(test).count("?") == 4



  test "WHERE statements: x IN y":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "ids_array"],
      where     = ["id =", "IN (ids_array)"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND ? IN (ids_array) "))
    check string(test).count("?") == 2


    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "ids_array"],
      where     = ["id =", "id IN"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, ids_array FROM tasks AS t WHERE id = ? AND id IN (?) "))
    check string(test).count("?") == 2



  test "WHERE statements: `is NULL` ":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id =", "name != NULL", "description = NULL"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != NULL AND description = NULL "))
    check string(test).count("?") == 1


    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id =", "name !=", "description = NULL"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t WHERE id = ? AND name != ? AND description = NULL "))
    check string(test).count("?") == 2




suite "test sqlSelectConst - joins":

  test "LEFT JOIN using AS values":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "p", on: @["p.id = t.project_id", "p.status = 1"])],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects AS p ON (p.id = t.project_id AND p.status = 1) WHERE id = ? "))

  test "LEFT JOIN (default) - 1 value":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))

  test "LEFT JOIN (default) - 2 value":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"]), (table: "invoice", tableAs: "", on: @["invoice.id = t.invoice_id", "invoice.status = 1"])],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) LEFT JOIN invoice ON (invoice.id = t.invoice_id AND invoice.status = 1) WHERE id = ? "))

  test "LEFT JOIN (default) - 3 value":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"]), (table: "invoice", tableAs: "", on: @["invoice.id = t.invoice_id", "invoice.status = 1"]), (table: "letter", tableAs: "", on: @["letter.id = t.letter_id", "letter.status = 1"])],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) LEFT JOIN invoice ON (invoice.id = t.invoice_id AND invoice.status = 1) LEFT JOIN letter ON (letter.id = t.letter_id AND letter.status = 1) WHERE id = ? "))


  test "INNER JOIN":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      jointype  = INNER,
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t INNER JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))


  test "JOIN #1":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      useDeleteMarker = false,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))


  test "JOIN #2":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      useDeleteMarker = false,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT t.id, t.name, t.description, t.created, t.updated, t.completed FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE t.id = ? "))


  test "JOIN #3":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
      # joinargs  = [],
      joinargs  = [
        (table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"]),
        (table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])
      ],
      useDeleteMarker = false,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT t.id, t.name, t.description, t.created, t.updated, t.completed FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE t.id = ? "))




suite "test sqlSelectConst - deletemarkers / softdelete":



  test "deletemarkers from const - 1 value":
    let test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = ["tasks"],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))


  test "deletemarkers from const - 2 values":
    let test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = ["tasks", "history"],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))


  test "deletemarkers from const - 3 values":
    let test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = ["tasks", "history", "person"],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))



  test "deletemarkers from const":
    const tableWithDeleteMarkerLet = ["tasks", "history", "tasksitems"]

    let test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      # tablesWithDeleteMarker = tableWithDeleteMarkerLet,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))




  test "deletemarkers from inline":
    var test: SqlQuery
    # const tableWithDeleteMarkerLet = ["tasks", "history", "tasksitems"]

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      # tablesWithDeleteMarker = [] #tableWithDeleteMarkerLet,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))




  test "deletemarkers from inline (without join)":
    var test: SqlQuery
    # const tableWithDeleteMarkerLet = ["tasks", "history", "tasksitems"]

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [],
      # joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      # tablesWithDeleteMarker = [] #tableWithDeleteMarkerLet,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks WHERE id = ? AND tasks.is_deleted IS NULL "))



  test "deletemarkers from inline with WHERE IN":
    var test: SqlQuery
    const tableWithDeleteMarkerLet = ["tasks", "history", "tasksitems"]

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      # tablesWithDeleteMarker = [] #tableWithDeleteMarkerLet,
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"],

      whereInField = "tasks",
      whereInValue = ["1", "2", "3"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks in (1,2,3) AND tasks.is_deleted IS NULL "))


  test "deletemarkers misc":
    var test: SqlQuery
    # const tableWithDeleteMarkerLet = ["tasks", "history", "tasksitems"]

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "history", tableAs: "", on: @["history.id = tasks.hid"])],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid) WHERE id = ? AND tasks.is_deleted IS NULL AND history.is_deleted IS NULL "))



    test = sqlSelectConst(
      table     = "tasks",
      select    = ["tasks.id", "tasks.name"],
      where     = ["tasks.id ="],
      joinargs  = [(table: "history", tableAs: "his", on: @["his.id = tasks.hid"])],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT tasks.id, tasks.name FROM tasks LEFT JOIN history AS his ON (his.id = tasks.hid) WHERE tasks.id = ? AND tasks.is_deleted IS NULL AND his.is_deleted IS NULL "))



  test "deletemarkers on the fly":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"])],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN projects ON (projects.id = tasks.project_id AND projects.status = 1) WHERE id = ? AND tasks.is_deleted IS NULL "))



  test "custom deletemarker override":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name"],
      where     = ["id ="],
      joinargs  = [(table: "history", tableAs: "", on: @["history.id = tasks.hid"])],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"],
      deleteMarker = ".deleted_at = 543234563"
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid) WHERE id = ? AND tasks.deleted_at = 543234563 AND history.deleted_at = 543234563 "))



  test "complex query":
    var test: SqlQuery

    test = sqlSelectConst(
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
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
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






suite "sqlSelectConst":

  test "with delete marker":
    let a = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
      joinargs  = [],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"], #tableWithDeleteMarker
    )

    check querycompare(a, (sql("""
        SELECT
          t.id, t.name, t.description, t.created, t.updated, t.completed
        FROM
          tasks AS t
        WHERE
              t.id = ?
          AND t.is_deleted IS NULL
        """)))


  test "deletemarkers + joind":
    let b = sqlSelectConst(
      table     = "tasks",
      # tableAs   = "t",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id =", "status >"],
      joinargs  = [
          (table: "history", tableAs: "his", on: @["his.id = tasks.hid", "his.status = 1"]),
          (table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"]),
        ],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"] #tableWithDeleteMarker
    )

    check querycompare(b, sql("""
        SELECT
          id, name, description, created, updated, completed
        FROM
          tasks
        LEFT JOIN history AS his ON
          (his.id = tasks.hid AND his.status = 1)
        LEFT JOIN projects ON
          (projects.id = tasks.project_id AND projects.status = 1)
        WHERE
              id = ?
          AND status > ?
          AND tasks.is_deleted IS NULL
          AND his.is_deleted IS NULL
        """))


    let c = sqlSelectConst(
      table     = "tasks",
      select    = ["tasks.id"],
      where     = ["status >"],
      joinargs  = [
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
        ],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(c, sql("""
        SELECT
          tasks.id
        FROM
          tasks
        LEFT JOIN history ON
          (his.id = tasks.hid)
        WHERE
              status > ?
          AND tasks.is_deleted IS NULL
          AND history.is_deleted IS NULL
        """))


  test "deletemarkers + join-mess":
    let d = sqlSelectConst(
      table     = "tasks",
      select    = ["tasks.id"],
      where     = ["status >"],
      joinargs  = [
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
          (table: "history", tableAs: "", on: @["his.id = tasks.hid"]),
        ],
      tablesWithDeleteMarker = ["tasks", "history", "tasksitems"]
    )
    check querycompare(d, sql("""
        SELECT
          tasks.id
        FROM
          tasks
        LEFT JOIN history ON
          (his.id = tasks.hid)
        LEFT JOIN history ON
          (his.id = tasks.hid)
        LEFT JOIN history ON
          (his.id = tasks.hid)
        LEFT JOIN history ON
          (his.id = tasks.hid)
        LEFT JOIN history ON
          (his.id = tasks.hid)
        WHERE
              status > ?
          AND tasks.is_deleted IS NULL
          AND history.is_deleted IS NULL
        """))


  test "where in values (preformatted)":
    let e = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name"],
      where     = ["t.id ="],
      joinargs  = [],
      whereInField = "t.name",
      whereInValue = ["'1aa'", "'2bb'", "'3cc'"],
      tablesWithDeleteMarker = ["tasksQ", "history", "tasksitems"], #tableWithDeleteMarker
    )
    check querycompare(e, sql("""
        SELECT
          t.id, t.name
        FROM
          tasks AS t
        WHERE
              t.id = ?
          AND t.name in ('1aa','2bb','3cc')"""))


  test "where in values (empty)":

    let f = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name"],
      where     = ["t.id ="],
      joinargs  = [],
      whereInField = "t.id",
      whereInValue = [""],
      tablesWithDeleteMarker = ["tasksQ", "history", "tasksitems"], #tableWithDeleteMarker
    )
    check querycompare(f, sql("SELECT t.id, t.name FROM tasks AS t WHERE t.id = ? AND t.id in (0)"))
