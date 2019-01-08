*This readme is generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*


# SQL builder

SQL builder for ``INSERT``, ``UPDATE``, ``SELECT`` and ``DELETE`` queries.
The builder will check for NULL values and build a query with them.

After Nim's update to 0.19.0, the check for NULL values has been removed
due to the removal of ``nil``. This library's main goal is to allow the
user, to insert NULL values into the database again.

This packages uses Nim's standard packages, e.g. db_postgres,
proc to escape qoutes.


# NULL values


## A NULL value

The global ``var dbNullVal`` represents a NULL value. Use ``dbNullVal``
in your args, if you need to insert/update to a NULL value.

## Insert value or NULL

The global ``proc dbValOrNull()`` will check, if it's contain a value
or is empty. If it contains a value, the value will be used in the args,
otherwise a NULL value (``dbNullVal``) will be used.

``dbValOrNull()`` accepts both strings and int.


## Executing DB commands

The examples below support the various DB commands such as ``exec``,
``tryExec``, ``insertID``, ``tryInsertID``, etc.


# Examples (NULL values)


All the examples uses a table named: ``myTable`` and they use the WHERE argument on: ``name``.

## Update string & int

### Version 1
*Required if NULL values could be expected*
```nim
 let a = genArgs("em@em.com", 20, "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> string, int
 # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
```



### Version 2
```nim
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"]), "em@em.com", 20, "John")
 # ==> string, int
 # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
```


## Update NULL & int

```nim
 let a = genArgs("", 20, "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> NULL, int
 # ==> UPDATE myTable SET email = NULL, age = ? WHERE name = ?
```


## Update string & NULL

```nim
 a = genArgs("aa@aa.aa", dbNullVal, "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> string, NULL
 # ==> UPDATE myTable SET email = ?, age = NULL WHERE name = ?
```


## Error: Update string & NULL

An empty string, "", will be inserted into the database as NULL.
Empty string cannot be used for an INTEGER column. You therefore
need to use the ``dbValOrNull()`` or ``dbNullVal`` for ``int-values``.

```nim
 a = genArgs("aa@aa.aa", "", "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> string, ERROR
 # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
 # ==> To insert a NULL into a int-field, it is required to use dbValOrNull()
 #     or dbNullVal, it is only possible to pass and empty string.
```


## Update NULL & NULL

```nim
 let cc = ""
 a = genArgs(dbValOrNull(cc), dbValOrNull(cc), "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> NULL, NULL
 # ==> UPDATE myTable SET email = NULL, age = NULL WHERE name = ?
```



## Update unknow value - maybe NULL

```nim
 a = genArgs(dbValOrNull(stringVar), dbValOrNull(intVar), "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> NULL, NULL -or- STRING, INT
```



# Examples (INSERT)

## Insert without NULL

```nim
 exec(db, sqlInsert("myTable", ["email", "age"]), "em@em.com" , 20)
 # OR
 insertID(db, sqlInsert("myTable", ["email", "age"]), "em@em.com", 20)
 # ==> INSERT INTO myTable (email, age) VALUES (?, ?)
```


## Insert with NULL

```nim
 let a = genArgs("em@em.com", dbNullVal)
 exec(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
 # OR
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
# Imports
import strutils, db_postgres

# Types
## Procs
### proc argType*
```nim
proc argType*(v: ArgObj): ArgObj =
```
Checks if a ``ArgObj`` is NULL and return
``dbNullVal``. If it's not NULL, the passed
``ArgObj`` is returned.
### proc argType*
```nim
proc argType*(v: string | int): ArgObj =
```
Transforms a string or int to a ``ArgObj``
### proc dbValOrNull*
```nim
proc dbValOrNull*(v: string | int): ArgObj =
```
Return NULL obj if len() == 0, else return value obj
### proc sqlInsert*
```nim
proc sqlInsert*(table: string, data: varargs[string], args: ArgsContainer.query): SqlQuery =
```
SQL builder for INSERT queries
Checks for NULL values
### proc sqlInsert*
```nim
proc sqlInsert*(table: string, data: varargs[string]): SqlQuery =
```
SQL builder for INSERT queries
Does NOT check for NULL values
### proc sqlUpdate*
```nim
proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string], args: ArgsContainer.query): SqlQuery =
```
SQL builder for UPDATE queries
Checks for NULL values
### proc sqlUpdate*
```nim
proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string]): SqlQuery =
```
SQL builder for UPDATE queries
Does NOT check for NULL values
### proc sqlDelete*
```nim
proc sqlDelete*(table: string, where: varargs[string]): SqlQuery =
```
SQL builder for DELETE queries
Does NOT check for NULL values
### proc sqlDelete*
```nim
proc sqlDelete*(table: string, where: varargs[string], args: ArgsContainer.query): SqlQuery =
```
SQL builder for DELETE queries
Checks for NULL values
### proc sqlSelect*
```nim
proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string): SqlQuery =
```
SQL builder for SELECT queries
Does NOT check for NULL values
### proc sqlSelect*
```nim
proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string, args: ArgsContainer.query): SqlQuery =
```
SQL builder for SELECT queries
Checks for NULL values
## Templates
### template genArgs*[T]
```nim
template genArgs*[T](arguments: varargs[T, argType]): ArgsContainer =
```
Create argument container for query and passed args
## Other
### ArgObj*
```nim
ArgObj* = object
```
Argument object
### ArgsContainer
```nim
ArgsContainer = object
```
Argument container used for queries and args
### var dbNullVal*
```nim
var dbNullVal*: ArgObj
```
Global NULL value
