# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/unittest

import
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private



suite "update - custom args":

  test "sqlUpdate using genArgs #1":
    let a3 = genArgs("hje", "")
    let q = sqlUpdate("my-table", ["name", "age"], ["id"], a3.query)
    check querycompare(q, sql("UPDATE my-table SET name = ?, age = ? WHERE id = ?"))

  test "sqlUpdate using genArgs #2":
    let a4 = genArgs("hje", dbNullVal)
    let q2 = sqlUpdate("my-table", ["name", "age"], ["id"], a4.query)
    check querycompare(q2, sql("UPDATE my-table SET name = ?, age = NULL WHERE id = ?"))

  test "sqlUpdate using genArgsColumns #1":
    let (s, a1) = genArgsColumns(SQLQueryType.UPDATE, (true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    let q = sqlUpdate("my-table", s, ["id"], a1.query)
    check querycompare(q, sql("UPDATE my-table SET name = NULL, age = ? WHERE id = ?"))

  test "sqlUpdate using genArgsColumns #2 - empty string IS NULL (nim-field)":
    let (s, a1) = genArgsColumns(SQLQueryType.UPDATE, (true, "name", ""), (true, "age", 30), (true, "nim", ""), (true, "", "154"))
    let q = sqlUpdate("my-table", s, ["id"], a1.query)
    check querycompare(q, sql("UPDATE my-table SET name = NULL, age = ?, nim = NULL WHERE id = ?"))

  test "sqlUpdate using genArgsColumns #2 - empty string is ignored (nim-field)":
    let (s, a1) = genArgsColumns(SQLQueryType.UPDATE, (true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    let q = sqlUpdate("my-table", s, ["id"], a1.query)
    check querycompare(q, sql("UPDATE my-table SET name = NULL, age = ? WHERE id = ?"))

  test "sqlUpdate using genArgsColumns #3":
    let (s, a1) = genArgsColumns(SQLQueryType.UPDATE, (true, "name", ""), (false, "age", 30), (false, "nim", ""), (true, "", "154"))
    let q = sqlUpdate("my-table", s, ["id"], a1.query)
    check querycompare(q, sql("UPDATE my-table SET name = NULL WHERE id = ?"))

  test "sqlUpdate using genArgsSetNull":
    let a2 = genArgsSetNull("hje", "")
    let q = sqlUpdate("my-table", ["name", "age"], ["id"], a2.query)
    check querycompare(q, sql("UPDATE my-table SET name = ?, age = NULL WHERE id = ?"))


suite "update - queries":

  test "update value":
    let q = sqlUpdate(
      "table",
      ["name", "age", "info"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = ? WHERE id = ?"))



  test "update value with NULL":
    let q = sqlUpdate(
      "table",
      ["name", "age", "info = NULL"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = NULL WHERE id = ?"))



  test "update value with NULL multiple":
    let q = sqlUpdate(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ?"))



  test "update value with spaces":
    let q = sqlUpdate(
      "table",
      ["name =   ", "age  ", "info  =", "hey  =  NULL  "],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = ?, hey = NULL WHERE id = ?"))




  test "update value with WHERE params":
    let q = sqlUpdate(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id =", "epoch >", "parent IS NULL", "name IS NOT NULL", "age != 22", "age !="],
    )
    check querycompare(q, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ? AND epoch > ? AND parent IS NULL AND name IS NOT NULL AND age != 22 AND age != ?"))


  test "update value with WHERE params with spaces":
    let q2 = sqlUpdate(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id =", "  epoch >", "parent   IS NULL", "name IS  NOT   NULL", "age  !=   22  ", "  age   !="],
    )
    check querycompare(q2, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ? AND epoch > ? AND parent IS NULL AND name IS NOT NULL AND age != 22 AND age != ?"))



  test "update arrays":
    let q = sqlUpdate(
      "table",
      ["parents = ARRAY_APPEND(id, ?)", "age = ARRAY_REMOVE(id, ?)", "info = NULL"],
      ["last_name NOT IN ('Anderson', 'Johnson', 'Smith')"],
    )
    check querycompare(q, sql("UPDATE table SET parents = ARRAY_APPEND(id, ?), age = ARRAY_REMOVE(id, ?), info = NULL WHERE last_name NOT IN ('Anderson', 'Johnson', 'Smith')"))




suite "update - queries with specified NULL in data and ? in where":

  test "set NULL and where = ?":
    let q = sqlUpdate(
      "table",
      ["name", "age", "info = NULL"],
      ["id = ?"],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = NULL WHERE id = ?"))


  test "set NULL and where=?":
    let q = sqlUpdate(
      "table",
      ["name", "age", "info = NULL"],
      ["id=?"],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = NULL WHERE id=?"))

  test "set =NULL and where=?":
    let q = sqlUpdate(
      "table",
      ["name", "age", "info=NULL"],
      ["id=?"],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info=NULL WHERE id=?"))




suite "update macro":

  test "update value":
    let q = sqlUpdateMacro(
      "table",
      ["name", "age", "info"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = ? WHERE id = ?"))


  test "update value":
    let q = sqlUpdateMacro(
      "table",
      ["name", "age", "info"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = ? WHERE id = ?"))



  test "update value with NULL":
    let q = sqlUpdateMacro(
      "table",
      ["name", "age", "info = NULL"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = NULL WHERE id = ?"))



  test "update value with NULL multiple":
    let q = sqlUpdateMacro(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ?"))



  test "update value with spaces":
    let q = sqlUpdateMacro(
      "table",
      ["name =   ", "age  ", "info  =", "hey  =  NULL  "],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, age = ?, info = ?, hey = NULL WHERE id = ?"))




  test "update value with WHERE params":
    let q = sqlUpdateMacro(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id =", "epoch >", "parent IS NULL", "name IS NOT NULL", "age != 22", "age !="],
    )
    check querycompare(q, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ? AND epoch > ? AND parent IS NULL AND name IS NOT NULL AND age != 22 AND age != ?"))


  test "update value with WHERE params with spaces":
    let q2 = sqlUpdateMacro(
      "table",
      ["name = NULL", "age", "info = NULL"],
      ["id =", "  epoch >", "parent   IS NULL", "name IS  NOT   NULL", "age  !=   22  ", "  age   !="],
    )
    check querycompare(q2, sql("UPDATE table SET name = NULL, age = ?, info = NULL WHERE id = ? AND epoch > ? AND parent IS NULL AND name IS NOT NULL AND age != 22 AND age != ?"))


  test "update arrays":
    let q = sqlUpdateMacro(
      "table",
      ["parents = ARRAY_APPEND(id, ?)", "age = ARRAY_REMOVE(id, ?)", "info = NULL"],
      ["last_name NOT IN ('Anderson', 'Johnson', 'Smith')"],
    )
    check querycompare(q, sql("UPDATE table SET parents = ARRAY_APPEND(id, ?), age = ARRAY_REMOVE(id, ?), info = NULL WHERE last_name NOT IN ('Anderson', 'Johnson', 'Smith')"))


