*This readme is generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*


# SQL builder

SQL builder for ``INSERT``, ``UPDATE``, ``SELECT`` and ``DELETE`` queries.
The builder will check for NULL values and build a query with them.

After Nim's update to 0.19.0, the check for NULL values has been removed
due to the removal of ``nil``.

This library's main goal is to allow the user, to insert NULL values into the
database again, and ease the creating of queries.


# Macro generated queries
 
The library supports generating the queries with a macro, which improves the
performance due to query being generated on compile time. The macro generated
queries **do not** accept the `genArgs()` and `genArgsColumns()` due to not
being available on compile time - so there's currently not NULL-support for
macros.


# NULL values


## A NULL value

The global ``const dbNullVal`` represents a NULL value. Use ``dbNullVal``
in your args, if you need to insert/update to a NULL value.

## Insert value or NULL

The global ``proc dbValOrNull()`` will check, if it contains a value
or is empty. If it contains a value, the value will be used in the args,
otherwise a NULL value (``dbNullVal``) will be used.

``dbValOrNull()`` accepts all types due to `value: auto`.

## Auto NULL-values

There are two generators, which can generate the `NULL` values for you.

* `genArgs` does only set a field to `NULL` if `dbNullVal`/`dbValOrNull()` is passed.
* `genArgsSetNull` sets empty field (`""` / `c.len() == 0`) to `NULL`.

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


### Version 3
```nim
 let a = genArgsSetNull("em@em.com", "", "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> string, NULL
 # ==> UPDATE myTable SET email = ?, age = NULL WHERE name = ?
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


## Error: Update string & NULL into an integer column

An empty string, "", will be inserted into the database as NULL.
Empty string cannot be used for an INTEGER column. You therefore
need to use the ``dbValOrNull()`` or ``dbNullVal`` for ``int-values``.

This is due to, that the library does not know you DB-architecture, so it
is your responsibility to respect the columns.

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
 a = genArgs(dbValOrNull(var1), dbValOrNull(var2), "John")
 exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
 # ==> AUTO or NULL, AUTO or NULL, string
```



# Dynamic selection of columns
Select which columns to include.

Lets say, that you are importing data from a spreadsheet with static
columns, and you need to update your DB with the new values.

If the spreadsheet contains an empty field, you can update your DB with the
NULL value. But sometimes the spreadsheet only contains 5 out of the 10
static columns. Now you don't know the values of the last 5 columns,
which will result in updating the DB with NULL values.

The template `genArgsColumns()` allows you to use the same query, but  selecting
only the columns which shall be updated. When importing your spreadsheet, check
if the column exists (bool), and pass that as the `use: bool` param. If
the column does not exists, it will be skipped in the query.

## Insert & Delete
```nim
 let (s, a) = genArgsColumns((true, "name", "Thomas"), (true, "age", 30), (false, "nim", "never"))
 # We are using the column `name` and `age` and ignoring the column `nim`.

 echo $a.args
 # ==> Args: @["Thomas", "30"]

 let a1 = sqlInsert("my-table", s, a.query) 
 # ==> INSERT INTO my-table (name, age) VALUES (?, ?)
 
 let a2 = sqlDelete("my-table", s, a.query)
 # ==> DELETE FROM my-table WHERE name = ? AND age = ?
```

## Update & Select
```nim
 let (s, a) = genArgsColumns((true, "name", "Thomas"), (true, "age", 30), (false, "nim", ""), (true, "", "154"))
 # We are using the column `name` and `age` and ignoring the column `nim`. We
 # are using the value `154` as our identifier, therefor the column is not 
 # specified

 echo $a.args
 # ==> Args: @["Thomas", "30", "154"]
 
 let a3 = sqlUpdate("my-table", s, ["id"], a.query)
 # ==> UPDATE my-table SET name = ?, age = ? WHERE id = ?
 
 let a4 = sqlSelect("my-table", s, [""], ["id ="], "", "", "", a.query)
 # ==> SELECT name, age FROM my-table WHERE id = ? 
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

Please note that you have to define the equal symbol for the where clause. This
allows you to use `=`, `!=`, `>`, `<`, etc.

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

# Debug
If you need to debug and see the queries, just pass `-d:testSqlquery` to print
the queries.

# Credit
Inspiration for builder: [Nim Forum](https://github.com/nim-lang/nimforum)

# Imports
import strutils, db_common

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

### template genArgsColumns*[T]
```nim
template genArgsColumns*[T](arguments: varargs[T, argFormat]): tuple[select: seq[string], args: ArgsContainer] =
```
Create argument container for query and passed args and selecting which
columns to update. It's and expansion of `genArgs()`, since you can
decide which columns, there should be included.

Lets say, that you are importing data from a spreadsheet with static
columns, and you need to update your DB with the new values.

If the spreadsheet contains an empty field, you can update your DB with the
NULL value. But sometimes the spreadsheet only contains 5 out of the 10
static columns. Now you don't know the values of the last 5 columns,
which will result in updating the DB with NULL values.

This template allows you to use the same query, but dynamic selecting only the
columns which shall be updated. When importing your spreadsheet, check
if the column exists (bool), and pass that as the `use: bool` param. If
the column does not exists, it will be skipped in the query.

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
