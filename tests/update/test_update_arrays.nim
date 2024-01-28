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





suite "update - arrays":

  test "[manual] update arrays - ARRAY_REMOVE":

    let q = sqlUpdate(
      "table",
      ["name", "project_ids = ARRAY_REMOVE(project_ids, ?)"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET name = ?, project_ids = ARRAY_REMOVE(project_ids, ?) WHERE id = ?"))


  test "[manual] update arrays - only ARRAY_REMOVE":

    let q = sqlUpdate(
      "table",
      ["project_ids = ARRAY_REMOVE(project_ids, ?)"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_REMOVE(project_ids, ?) WHERE id = ?"))




suite "update - arrays where cond ANY":

  test "array":

    let q = sqlUpdate(
      "table",
      ["name"],
      ["some_ids = ANY(?::INT[])"],
    )
    check querycompare(q, sql("UPDATE table SET name = ? WHERE some_ids = ANY(?::INT[])"))




suite "update - arrays dedicated":

  test "[dedicated] update array - ARRAY_REMOVE":

    let q = sqlUpdateArrayRemove(
      "table",
      ["project_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_REMOVE(project_ids, ?) WHERE id = ?"))


  test "[dedicated] update arrays - ARRAY_REMOVE":

    let q = sqlUpdateArrayRemove(
      "table",
      ["project_ids", "task_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_REMOVE(project_ids, ?), task_ids = ARRAY_REMOVE(task_ids, ?) WHERE id = ?"))


  test "[dedicated] update array - ARRAY_APPEND":

    let q = sqlUpdateArrayAppend(
      "table",
      ["project_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_APPEND(project_ids, ?) WHERE id = ?"))


  test "[dedicated] update arrays - ARRAY_APPEND":

    let q = sqlUpdateArrayAppend(
      "table",
      ["project_ids", "task_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_APPEND(project_ids, ?), task_ids = ARRAY_APPEND(task_ids, ?) WHERE id = ?"))



  test "[macro] update array - ARRAY_REMOVE":

    let q = sqlUpdateMacroArrayRemove(
      "table",
      ["project_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_REMOVE(project_ids, ?) WHERE id = ?"))


  test "[macro] update array - ARRAY_APPEND":

    let q = sqlUpdateMacroArrayAppend(
      "table",
      ["project_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_APPEND(project_ids, ?) WHERE id = ?"))


  test "[macro] update arrays - ARRAY_APPEND":

    let q = sqlUpdateMacroArrayAppend(
      "table",
      ["project_ids", "task_ids"],
      ["id ="],
    )
    check querycompare(q, sql("UPDATE table SET project_ids = ARRAY_APPEND(project_ids, ?), task_ids = ARRAY_APPEND(task_ids, ?)  WHERE id = ?"))





# ORDER BY array_position(array[" & projectIDs & "], project.id)
