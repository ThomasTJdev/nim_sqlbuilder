# SQL builder

**This library is tested with a Postgres database (db_postges)**

 SQL builder for ``INSERT``, ``UPDATE``, ``SELECT`` and ``DELETE`` queries.
 The builder will check for NULL values and build a query with them.

 After Nim's update to 0.19.0, the check for NULL values has been removed
 due to the removal of ``nil``. This library's main goal is to allow the 
 user, to insert NULL values into the database again.

 # Documentation

 The documentation can be generated with:
 ```nil
 nim doc sqlbuilder
 ```

 # NULL values

 ## A NULL value

 The global ``var dbNullVal`` represents a NULL value. Use ``dbNullVal``
 in your args, if you need to insert/update to a NULL value.

 ## Insert value or NULL

 The global ``proc dbValOrNull()`` will check, if it's contain a value
 or is empty. If it contains a value, the value will be used in the args,
 otherwise a NULL value (``dbNullVal``) will be used.

 ``dbValOrNull()`` accepts both strings and int.



 # Executing DB commands
 
 The examples below support the various DB commands such as ``exec``,
 ``tryExec``, ``insertID``, ``tryInsertID``, etc.

 # Examples (general)

 All the examples uses a table named: ``myTable`` and they use the WHERE argument on: ``name``.

 ## Insert string & int

 ```nim
    let a = genArgs("em@em.com", 20, "John")
    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
    # ==> string, int
    # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
```

 ## Insert NULL & int

 ```nim
    a = genArgs("", 20, "John")
    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
    # ==> NULL, int
    # ==> UPDATE myTable SET email = NULL, age = ? WHERE name = ?
```

 ## Insert string & NULL

 ```nim
    a = genArgs("aa@aa.aa", dbNullVal, "John")
    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
    # ==> string, NULL
    # ==> UPDATE myTable SET email = ?, age = NULL WHERE name = ?
```

 ## Error: Insert string & NULL

 An empty string, "", will be inserted into the database, which is not allowed
 for a int-field. You therefore need to use the ``dbValOrNull()`` or 
 ``dbNullVal`` for ``integers``.

 ```nim
    a = genArgs("aa@aa.aa", "", "John")
    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
    # ==> string, ERROR
    # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
    # ==> To insert a NULL into a int-field, it is required to use dbValOrNull()
    #     or dbNullVal, it is only possible to pass and empty string.
```

 ## Insert NULL & NULL

 ```nim
    let cc = ""
    a = genArgs(dbValOrNull(cc), dbValOrNull(cc), "John")
    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
    # ==> NULL, NULL
    # ==> UPDATE myTable SET email = NULL, age = NULL WHERE name = ?
```


# Examples (INSERT)

## Insert without NULL

 ```nim
    exec(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
    insertID(db, sqlInsert("myTable", ["email", "age"]), "John", 20)
    # ==> INSERT INTO myTable (email, age) VALUES (?, ?)
```

## Insert with NULL

 ```nim
    let a = genArgs("em@em.com", dbNullVal)
    exec(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
    insertID(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
    # ==> INSERT INTO myTable (email) VALUES (?)
```

# Examples (SELECT)

## Select without NULL

 ```nim
    getValue(db, sqlSelect("myTable", 
      ["email", "age"], [""], ["name ="], "", "", ""), "John")
    # SELECT email, age FROM myTable WHERE name = ?

    getValue(db, sqlSelect("myTable", 
      ["myTable.email", "myTable.age", "company.name"], 
      ["company ON company.email = myTable.email"], 
      ["myTable.name =", "myTable.age ="], "", "", ""), 
      "John", "20")
    # SELECT myTable.email, myTable.age, company.name 
    # FROM myTable 
    # LEFT JOIN company ON company.email = myTable.email 
    # WHERE myTable.name = ? AND myTable.age = ?

    getAllRows(db, sqlSelect("myTable", 
      ["myTable.email", "myTable.age", "company.name"], 
      ["company ON company.email = myTable.email"], 
      ["company.name ="], "20,22,24", "myTable.age", "ORDER BY myTable.email"), 
      "BigBiz")
    # SELECT myTable.email, myTable.age, company.name 
    # FROM myTable LEFT JOIN company ON company.email = myTable.email 
    # WHERE company.name = ? AND myTable.age IN (20,22,24)
    # ORDER BY myTable.email
```

 ## Select with NULL
 
 ```nim
    let a = genArgs(dbNullVal)
    getValue(db, sqlSelect("myTable", 
      ["email", "age"], [""], ["name ="], "", "", "", a.query), a.args)
    # SELECT email, age FROM myTable WHERE name = NULL

    let a = genArgs("John", dbNullVal)
    getValue(db, sqlSelect("myTable", 
      ["myTable.email", "myTable.age", "company.name"], 
      ["company ON company.email = myTable.email"], 
      ["myTable.name =", "myTable.age ="], "", "", "", a.query), a.args)
    # SELECT myTable.email, myTable.age, company.name 
    # FROM myTable 
    # LEFT JOIN company ON company.email = myTable.email 
    # WHERE myTable.name = ? AND myTable.age = NULL

    let a = genArgs(dbNullVal)
    getAllRows(db, sqlSelect("myTable", 
      ["myTable.email", "myTable.age", "company.name"], 
      ["company ON company.email = myTable.email"], 
      ["company.name ="], "20,22,24", "myTable.age", "ORDER BY myTable.email", a.query), 
      a.args)
    # SELECT myTable.email, myTable.age, company.name 
    # FROM myTable LEFT JOIN company ON company.email = myTable.email 
    # WHERE company.name = NULL AND myTable.age IN (20,22,24)
    # ORDER BY myTable.email
```
# Credit
Inspiration for builder: [Nim Forum](https://github.com/nim-lang/nimforum)