# Copyright Thomas T. Jarløv (TTJ)

import
  std/db_common,
  std/strutils,
  std/unittest,
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


suite "test formats":

  test "genArgsColumns":
    let (s, a) = genArgsColumns((true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))

    assert s == ["name", "age"]

    for k, v in a.query:
      if k == 0:
        assert $v == """(val: "", isNull: false)"""
      if k == 1:
        assert $v == """(val: "30", isNull: false)"""
      if k == 3:
        assert $v == """(val: "154", isNull: false)"""

    for k, v in a.args:
      if k == 0:
        assert $v == ""
      if k == 1:
        assert $v == "30"
      if k == 3:
        assert $v == "154"

    let a1 = sqlInsert("my-table", s, a.query)
    let a2 = sqlDelete("my-table", s, a.query)
    let a3 = sqlUpdate("my-table", s, ["id"], a.query)
    let a4 = sqlSelect("my-table", s, [""], ["id ="], "", "", "", a.query)


  test "genArgsSetNull":
    let b = genArgsSetNull("hje", "", "12")
    assert b.args   == @["hje", "12"]
    assert b.query.len() == 3
    for k, v in b.query:
      if k == 0:
        assert $v == """(val: "hje", isNull: false)"""
      if k == 1:
        assert $v == """(val: "", isNull: true)"""
      if k == 2:
        assert $v == """(val: "12", isNull: false)"""

  test "genArgs":
    let b = genArgs("hje", "", "12")
    assert b.args   == @["hje", "", "12"]
    assert b.query.len() == 3
    for k, v in b.query:
      if k == 0:
        assert $v == """(val: "hje", isNull: false)"""
      if k == 1:
        assert $v == """(val: "", isNull: false)"""
      if k == 2:
        assert $v == """(val: "12", isNull: false)"""

  test "genArgs with null":
    let b = genArgs("hje", dbNullVal, "12")
    assert b.args   == @["hje", "12"]
    assert b.query.len() == 3
    for k, v in b.query:
      if k == 0:
        assert $v == """(val: "hje", isNull: false)"""
      if k == 1:
        assert $v == """(val: "", isNull: true)"""
      if k == 2:
        assert $v == """(val: "12", isNull: false)"""

  test "sqlInsert":
    let (s, a1) = genArgsColumns((true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    discard sqlInsert("my-table", s, a1.query)
    assert testout == "INSERT INTO my-table (name, age) VALUES (?, ?)"

    let a2 = genArgsSetNull("hje", "")
    discard sqlInsert("my-table", ["name", "age"], a2.query)
    assert testout == "INSERT INTO my-table (name) VALUES (?)"

  test "sqlUpdate":
    let (s, a1) = genArgsColumns((true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    discard sqlUpdate("my-table", s, ["id"], a1.query)
    assert testout == "UPDATE my-table SET name = ?, age = ? WHERE id = ?"

    let a2 = genArgsSetNull("hje", "")
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a2.query)
    assert testout == "UPDATE my-table SET name = ?, age = NULL WHERE id = ?"

    let a3 = genArgs("hje", "")
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a3.query)
    assert testout == "UPDATE my-table SET name = ?, age = ? WHERE id = ?"

    let a4 = genArgs("hje", dbNullVal)
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a4.query)
    assert testout == "UPDATE my-table SET name = ?, age = NULL WHERE id = ?"

  test "sqlSelect":
    let a2 = genArgsSetNull("hje", "", "123")
    let q1 = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a2.query)
    check querycompare(q1, sql"SELECT name, age FROM my-table WHERE id = ? ")

    let a3 = genArgs("hje", "")
    let q2 = sqlSelect("my-table AS m", ["m.name", "m.age"], ["p ON p.id = m.id"], ["m.id ="], "", "", "", a3.query)
    check querycompare(q2, sql"SELECT m.name, m.age FROM my-table AS m LEFT JOIN p ON (p.id = m.id) WHERE m.id = ? ")

    let a4 = genArgs("hje", dbNullVal)
    let q3 = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a4.query)
    check querycompare(q3, sql"SELECT name, age FROM my-table WHERE id = ? ")


suite "test sqlSelect":

  test "sqlSelect - refactor 2022-01":
    var test: SqlQuery

    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name", "description", "created", "updated", "completed"],
      where     = @["id ="],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name, description, created, updated, completed FROM tasks WHERE id = ? "))


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
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "p", on: @["p.id = t.project_id", "p.status = 1"])],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects AS p ON (p.id = t.project_id AND p.status = 1) WHERE id = ? "))


    test = sqlSelect(
      table     = "tasks",
      tableAs   = "t",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
      hideIsDeleted = false
    )
    check querycompare(test, sql("SELECT id, name FROM tasks AS t LEFT JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))



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
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid AND history.is_deleted IS NULL) WHERE id = ? AND tasks.is_deleted IS NULL "))



    test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["id ="],
      joinargs  = @[(table: "history", tableAs: "", on: @["history.id = tasks.hid"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet,
      deleteMarker = ".deleted_at = 543234563"
    )
    check querycompare(test, sql("SELECT id, name FROM tasks LEFT JOIN history ON (history.id = tasks.hid AND history.deleted_at = 543234563) WHERE id = ? AND tasks.deleted_at = 543234563 "))



    test = sqlSelect(
      table     = "tasks",
      select    = @["tasks.id", "tasks.name"],
      where     = @["tasks.id ="],
      joinargs  = @[(table: "history", tableAs: "his", on: @["his.id = tasks.hid"])],
      tablesWithDeleteMarker = tableWithDeleteMarkerLet
    )
    check querycompare(test, sql("SELECT tasks.id, tasks.name FROM tasks LEFT JOIN history AS his ON (his.id = tasks.hid AND his.is_deleted IS NULL) WHERE tasks.id = ? AND tasks.is_deleted IS NULL "))



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
          (his.id = tasks.hid AND his.status = 1 AND his.is_deleted IS NULL)
        LEFT JOIN projects ON
          (projects.id = tasks.project_id AND projects.status = 1)
        LEFT JOIN person ON
          (person.id = tasks.person_id)
        WHERE
              projects.id = ?
          AND tasks.status > ?
          AND tasks.id in (1,2,3)
          AND tasks.is_deleted IS NULL
        ORDER BY
          tasks.created DESC
      """)))


suite "test sqlSelectMacro":

  test "sqlSelectMacro legacy - refactor 2022-01":

    let q1 = sqlSelectMacro(
      table = "my-table",
      data = ["name", "age"],
      left = [""],
      whereC = ["id ="], "", "", "")

    check querycompare(q1, sql("SELECT name, age FROM my-table WHERE id = ?"))


suite "test sqlSelectConst":

  test "sqlSelectConst - refactor 2022-01":
    let a = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name", "t.description", "t.created", "t.updated", "t.completed"],
      where     = ["t.id ="],
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
          (his.id = tasks.hid AND his.status = 1 AND his.is_deleted IS NULL)
        LEFT JOIN projects ON
          (projects.id = tasks.project_id AND projects.status = 1)
        WHERE
              id = ?
          AND status > ?
          AND tasks.is_deleted IS NULL
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
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        WHERE
              status > ?
          AND tasks.is_deleted IS NULL
        """))


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
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        LEFT JOIN history ON
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        LEFT JOIN history ON
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        LEFT JOIN history ON
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        LEFT JOIN history ON
          (his.id = tasks.hid AND history.is_deleted IS NULL)
        WHERE
              status > ?
          AND tasks.is_deleted IS NULL
        """))


    let e = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name"],
      where     = ["t.id ="],
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


    let f = sqlSelectConst(
      table     = "tasks",
      tableAs   = "t",
      select    = ["t.id", "t.name"],
      where     = ["t.id ="],
      whereInField = "t.id",
      whereInValue = [""],
      tablesWithDeleteMarker = ["tasksQ", "history", "tasksitems"], #tableWithDeleteMarker
    )
    check querycompare(f, sql("SELECT t.id, t.name FROM tasks AS t WHERE t.id = ? AND t.id in (0)"))


suite "test sqlSelect(Convert) - legacy":

  test "sqlSelectConvert - refactor 2022-01":

    var test: SqlQuery


    test = sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "")

    check querycompare(test, sql("SELECT name, age FROM my-table WHERE id = ?"))



    test = sqlSelect("tasks", ["tasks.id", "tasks.name"], ["project ON project.id = tasks.project_id"], ["id ="], "", "", "")

    check querycompare(test, sql("""
        SELECT
          tasks.id,
          tasks.name
        FROM
          tasks
        LEFT JOIN project ON
          (project.id = tasks.project_id)
        WHERE
          id = ?
      """))



    test = sqlSelect("tasks", ["tasks.id", "tasks.name", "p.id"], ["project AS p ON p.id = tasks.project_id"], ["tasks.id ="], "", "", "")

    check querycompare(test, sql("""
        SELECT
          tasks.id,
          tasks.name,
          p.id
        FROM
          tasks
        LEFT JOIN project AS p ON
          (p.id = tasks.project_id)
        WHERE
          tasks.id = ?
      """))



    test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "", "", "")

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
      """))



    test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

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
        ORDER BY
          t.name
      """))



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


  test "sqlSelectConvert with genArgs - refactor 2022-01":


    var a = genArgs("123", dbNullVal)

    var test = sqlSelect("tasks", ["tasks.id", "tasks.name"], [""], ["id =", "status IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasks.id, tasks.name FROM tasks WHERE id = ? AND status IS NULL"""))



    a = genArgs("123", dbNullVal, dbNullVal)

    test = sqlSelect("tasks", ["tasks.id", "tasks.name"], [""], ["id =", "status IS NOT", "phase IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasks.id, tasks.name FROM tasks WHERE id = ? AND status IS NOT NULL AND phase IS NULL"""))


  test "sqlSelectConvert with genArgsSetNull - refactor 2022-01":

    var a = genArgsSetNull("123", "", "")

    var test = sqlSelect("tasks", ["tasks.id", "tasks.name"], [""], ["id =", "status IS NOT", "phase IS"], "", "", "", a.query)

    check querycompare(test, sql("""SELECT tasks.id, tasks.name FROM tasks WHERE id = ? AND status IS NOT NULL AND phase IS NULL"""))