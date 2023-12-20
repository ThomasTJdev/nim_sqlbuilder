# Copyright Thomas T. Jarløv (TTJ)

import
  std/unittest

import
  src/sqlbuilder





suite "test formats":

  test "genArgsColumns":
    let (s, a) = genArgsColumns(SQLQueryType.INSERT, (true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))

    check s == ["age"]

    for k, v in a.query:
      if k == 0:
        check $v == """(val: "30", isNull: false)"""
      if k == 2:
        check $v == """(val: "154", isNull: false)"""

    for k, v in a.args:
      if k == 0:
        check $v == "30"
      if k == 2:
        check $v == "154"

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
