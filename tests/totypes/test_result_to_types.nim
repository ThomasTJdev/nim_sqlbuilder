# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk



import std/unittest

when NimMajor >= 2:
  import db_connector/db_sqlite
else:
  import std/db_sqlite

import
  std/strutils

import
  src/sqlbuilderpkg/select,
  src/sqlbuilderpkg/totypes

import
  tests/create_db

type
  Person = ref object
    id: int
    name: string
    age: int
    ident: string
    is_nimmer: bool

#
# Set up a test database
#
createDB()
let db = openDB()
# let db = open("tests/db_types.db", "", "", "")

# db.exec(sql"DROP TABLE IF EXISTS my_table")
# db.exec(sql"""CREATE TABLE my_table (
#                 id   INTEGER,
#                 name VARCHAR(50) NOT NULL,
#                 age  INTEGER,
#                 ident TEXT,
#                 is_nimmer BOOLEAN
#               )""")

# db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)", "Jack")

# for i in 1..5:
#   db.exec(sql("INSERT INTO my_table (id, name, age, ident, is_nimmer) VALUES (?, ?, ?, ?, ?)"), $i, "Joe-" & $i, $i, "Nim", (if i <= 2: "true" else: "false"))

# for i in 6..10:
#   db.exec(sql("INSERT INTO my_table (id, name, age, ident) VALUES (?, ?, ?, ?)"), $i, "Cathrine-" & $i, $i, "Lag")



#
# Start testing
#
suite "Map result to types":

  test "getRow() result map post call":
    let
      columns = @["id","name"]
      val = db.getRow(sql("SELECT " & columns.join(",") & " FROM my_table WHERE id = 1"))
      res = sqlToType(Person, columns, val)

    check res.id == 1
    check res.name == "Joe-1"
    check res.age == 0
    check res.ident == ""


  test "getRow() with mixed column order":
    let
      columns = @["name","id","ident"]
      val = db.getRow(sql("SELECT " & columns.join(",") & " FROM my_table WHERE id = 1"))
      res = sqlToType(Person, columns, val)

    check res.id == 1
    check res.name == "Joe-1"
    check res.age == 0
    check res.ident == "Nim"


  test "getAllRows in a seq[T]":
    let
      columns = @["id","ident","name", "age", "is_nimmer"]
      vals = Person.sqlToType(
            columns,
            db.getAllRows(sql("SELECT " & columns.join(",") & " FROM my_table WHERE ident = 'Nim'"))
          )

    check vals.len == 5

    check vals[0].id == 1
    check vals[0].name == "Joe-1"

    check vals[1].id == 2
    check vals[1].name == "Joe-2"

    check vals[1].isNimmer == true
    check vals[3].isNimmer == false


  test "getRow() with select()":
    let
      columns = @["name","id","ident"]
      res = sqlToType(Person, columns, db.getRow(
        sqlSelect(
          table     = "my_table",
          tableAs   = "t",
          select    = columns,
          where     = @["id ="],
        ), 1)
      )

    check res.id == 1
    check res.name == "Joe-1"
    check res.age == 0
    check res.ident == "Nim"