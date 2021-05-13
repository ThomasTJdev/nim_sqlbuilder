# Copyright Thomas T. Jarløv (TTJ)

import
  std/db_common,
  std/unittest,
  src/sqlbuilder


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
    discard sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a2.query)
    assert testout == "SELECT name, age FROM my-table WHERE id = ? "

    let a3 = genArgs("hje", "")
    discard sqlSelect("my-table AS m", ["m.name", "m.age"], ["p ON p.id = m.id"], ["m.id ="], "", "", "", a3.query)
    assert testout == "SELECT m.name, m.age FROM my-table AS m LEFT JOIN p ON p.id = m.id WHERE m.id = ? "

    let a4 = genArgs("hje", dbNullVal)
    discard sqlSelect("my-table", ["name", "age"], [""], ["id ="], "", "", "", a4.query)
    assert testout == "SELECT name, age FROM my-table WHERE id = ? "