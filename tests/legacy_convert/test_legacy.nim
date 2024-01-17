# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

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





suite "legacy - sqlSelect(Convert)":


  test "legacy - sqlSelect - simple":
    let a2 = genArgsSetNull("hje", "", "123")
    let q1 = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a2.query)
    check querycompare(q1, sql"SELECT name, age FROM my-table WHERE id = ? ")

    let a3 = genArgs("hje", "")
    let q2 = sqlSelect("my-table AS m", ["m.name", "m.age"], ["p ON p.id = m.id"], ["m.id ="], "", "", "", a3.query)
    check querycompare(q2, sql"SELECT m.name, m.age FROM my-table AS m LEFT JOIN p ON (p.id = m.id) WHERE m.id = ? ")

    let a4 = genArgs("hje", dbNullVal)
    let q3 = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a4.query)
    check querycompare(q3, sql"SELECT name, age FROM my-table WHERE id = ? ")


  test "sqlSelect - #1":
    var test: SqlQuery

    test = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "")

    check querycompare(test, sql("SELECT name, age FROM my-table WHERE id = ?"))


  test "sqlSelect - #2 - join":
    var test: SqlQuery

    test = sqlSelect("tasksQQ", ["tasksQQ.id", "tasksQQ.name"], ["project ON project.id = tasksQQ.project_id"], ["id ="], "", "", "")

    check querycompare(test, sql("""
        SELECT
          tasksQQ.id,
          tasksQQ.name
        FROM
          tasksQQ
        LEFT JOIN project ON
          (project.id = tasksQQ.project_id)
        WHERE
          id = ?
      """))


  test "sqlSelect - #3 - join with alias":
    var test: SqlQuery

    test = sqlSelect("tasksQQ", ["tasksQQ.id", "tasksQQ.name", "p.id"], ["project AS p ON p.id = tasksQQ.project_id"], ["tasksQQ.id ="], "", "", "")

    check querycompare(test, sql("""
        SELECT
          tasksQQ.id,
          tasksQQ.name,
          p.id
        FROM
          tasksQQ
        LEFT JOIN project AS p ON
          (p.id = tasksQQ.project_id)
        WHERE
          tasksQQ.id = ?
      """))


  test "sqlSelect - #4 - alias all the way":
    var test: SqlQuery

    test = sqlSelect("tasksQQ AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "", "", "")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasksQQ AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
          t.id = ?
      """))


  test "sqlSelect - #5 - alias all the way with IN":
    var test: SqlQuery

    test = sqlSelect("tasksQQ AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasksQQ AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
        ORDER BY
          t.name
      """))


  test "sqlSelect - #6 - alias all the way with IN and delete marker":
    var test: SqlQuery

    test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name", tablesWithDeleteMarker = ["tasks", "persons"])

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


  test "complex query":

    var test: SqlQuery

    test = sqlSelect("tasksitems AS tasks",
        [
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
        [
          "history AS his ON his.id = tasks.hid AND his.status = 1",
          "projects ON projects.id = tasks.project_id AND projects.status = 1",
          "person ON person.id = tasks.person_id"
        ],
        [
          "projects.id =",
          "tasks.status >"
        ],
        "1,2,3",
        "tasks.id",
        "ORDER BY tasks.created DESC"
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
        ORDER BY
          tasks.created DESC
      """)))



suite "legacy - sqlSelect(Convert) - genArgs":

  test "sqlSelect with genArgs - refactor 2022-01":

    var a = genArgs("123", dbNullVal)

    var test = sqlSelect("tasksQQ", ["tasksQQ.id", "tasksQQ.name"], [""], ["id =", "status IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasksQQ.id, tasksQQ.name FROM tasksQQ WHERE id = ? AND status IS NULL"""))



    a = genArgs("123", dbNullVal, dbNullVal)

    test = sqlSelect("tasksQQ", ["tasksQQ.id", "tasksQQ.name"], [""], ["id =", "status IS NOT", "phase IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasksQQ.id, tasksQQ.name FROM tasksQQ WHERE id = ? AND status IS NOT NULL AND phase IS NULL"""))



  test "sqlSelect with genArgsSetNull - refactor 2022-01":

    var a = genArgsSetNull("123", "", "")

    var test = sqlSelect("tasksQQ", ["tasksQQ.id", "tasksQQ.name"], [""], ["id =", "status IS NOT", "phase IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasksQQ.id, tasksQQ.name FROM tasksQQ WHERE id = ? AND status IS NOT NULL AND phase IS NULL"""))




suite "test sqlSelectMacro":

  test "sqlSelectMacro legacy - refactor 2022-01":

    let q1 = sqlSelectMacro(
      table = "my-table",
      data = ["name", "age"],
      left = [""],
      whereC = ["id ="], "", "", "")

    check querycompare(q1, sql("SELECT name, age FROM my-table WHERE id = ?"))




suite "test various":

  test "xxx":

    let q1 = sqlSelect("locker", ["name"], [""], ["project_id =", "name =", "info ="], "", "", "")

    check querycompare(q1, sql("SELECT name FROM locker WHERE project_id = ? AND name = ? AND info = ?"))


