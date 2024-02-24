# Copyright Thomas T. Jarløv (TTJ)

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/unittest

import
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private







suite "test where cases custom formatting":

  test "where OR":
    var test: SqlQuery


    let
      resNormal   = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR id = ?) ")
      resPrepared = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = $1 OR id = $2) ")


    # Macro normal
    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR id = ?"],
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = false
    )
    check querycompare(test, resNormal)


    # Macro prepared
    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR id = ?"],
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = true
    )
    check querycompare(test, resPrepared)


  test "where OR OR":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR name = ? OR description = ?"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR name = ? OR description = ?) "))


  test "where OR OR parentheses":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR (name = ? OR description = ?)"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR (name = ? OR description = ?)) "))


  test "where AND OR parentheses":
    var test: SqlQuery

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? AND (name = ? OR description = ?)"],
      joinargs  = [],
      useDeleteMarker = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? AND (name = ? OR description = ?)) "))


  test "where OR OR parentheses AND ? = ANY(...)":
    var test: SqlQuery

    let
      resNormal   = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = ? OR (name = ? OR description = ?) AND ? = ANY(ids_array)) ")
      resPrepared = sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE (id = $1 OR (name = $2 OR description = $3) AND $4 = ANY(ids_array)) ")

    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR (name = ? OR description = ?) AND ? = ANY(ids_array)"],
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = false
    )
    check querycompare(test, resNormal)


    test = sqlSelectConst(
      table     = "tasks",
      select    = ["id", "name", "description", "created", "updated", "completed"],
      where     = ["id = ? OR (name = ? OR description = ?) AND ? = ANY(ids_array)"],
      joinargs  = [],
      useDeleteMarker = false,
      usePrepared = true
    )
    check querycompare(test, resPrepared)


  test "where x = 'y'":

    let test = sqlSelectConst(
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

    let test = sqlSelectConst(
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

    let test = sqlSelectConst(
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

    let test = sqlSelectConst(
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

    let test = sqlSelectConst(
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



