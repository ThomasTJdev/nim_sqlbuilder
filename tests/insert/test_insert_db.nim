# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import
    db_connector/db_sqlite
else:
  import
    std/db_sqlite

import
  std/strutils,
  std/unittest

import
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private


import tests/create_db




suite "insert into db":
  test "empty value transform to NULL #5":

    createDB()

    let db = openDB()

    check tryInsertID(db,
            sqlInsert("my_table",
            ["name", "age", "ident"],
            @["john", "", ""]), @["john", "", ""]
      ) > 0

    echo tryInsertID(db,
            sqlInsert("my_table",
            ["name", "age", "ident"],
            @["john", "12", ""]), @["john", "", ""]
      )


