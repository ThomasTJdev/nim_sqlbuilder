# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

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


