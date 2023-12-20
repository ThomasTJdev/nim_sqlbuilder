# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import
    db_connector/db_sqlite
else:
  import
    std/db_sqlite


const dbName = "tests/db_general.db"

proc openDB*(): DbConn =
  return open(dbName, "", "", "")

proc createDB*() =
  let db = openDB()

  db.exec(sql"DROP TABLE IF EXISTS my_table")
  db.exec(sql"""CREATE TABLE my_table (
                id   INTEGER PRIMARY KEY,
                name VARCHAR(50) NOT NULL,
                age  INTEGER,
                ident TEXT,
                is_nimmer BOOLEAN
              )""")


  db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)", "Jack")

  for i in 1..5:
    db.exec(sql("INSERT INTO my_table (id, name, age, ident, is_nimmer) VALUES (?, ?, ?, ?, ?)"), $i, "Joe-" & $i, $i, "Nim", (if i <= 2: "true" else: "false"))

  for i in 6..10:
    db.exec(sql("INSERT INTO my_table (id, name, age, ident) VALUES (?, ?, ?, ?)"), $i, "Cathrine-" & $i, $i, "Lag")

  db.close()


