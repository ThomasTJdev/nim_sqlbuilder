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



suite "update":

  test "sqlUpdate using genArgs":
    let a3 = genArgs("hje", "")
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a3.query)
    assert testout == "UPDATE my-table SET name = ?, age = ? WHERE id = ?"

    let a4 = genArgs("hje", dbNullVal)
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a4.query)
    assert testout == "UPDATE my-table SET name = ?, age = NULL WHERE id = ?"

  test "sqlUpdate using genArgsColumns":
    let (s, a1) = genArgsColumns((true, "name", ""), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
    discard sqlUpdate("my-table", s, ["id"], a1.query)
    assert testout == "UPDATE my-table SET name = ?, age = ? WHERE id = ?"

  test "sqlUpdate using genArgsSetNull":
    let a2 = genArgsSetNull("hje", "")
    discard sqlUpdate("my-table", ["name", "age"], ["id"], a2.query)
    assert testout == "UPDATE my-table SET name = ?, age = NULL WHERE id = ?"



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