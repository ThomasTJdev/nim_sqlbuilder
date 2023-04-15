*This readme is generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*


# SQL builder

SQL builder for ``INSERT``, ``UPDATE``, ``SELECT`` and ``DELETE`` queries.
The builder will check for NULL values and build a query with them.

After Nim's update to 0.19.0, the check for NULL values was removed
due to the removal of ``nil``.

This library allows the user, to insert NULL values into queries and
ease the creating of queries.



# Importing

## Import all
```nim
import sqlbuilder
```

## Import only the SELECT builder
```nim
import sqlbuilder/select
```

## Import all but with legacy softdelete fix
```nim
# nano sqlfile.nim
# import this file instead of sqlbuilder

import src/sqlbuilderpkg/insert
export insert

import src/sqlbuilderpkg/update
export update

import src/sqlbuilderpkg/delete
export delete

import src/sqlbuilderpkg/utils
export utils

# This enables the softdelete columns for the legacy selector
const tablesWithDeleteMarker = ["tasks", "persons"]
# Notice the include instead of import
include src/sqlbuilderpkg/select
```



# Macro generated queries

The library supports generating some queries with a macro, which improves the
performance due to query being generated on compile time.

The macro generated
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

## Select query builder

The SELECT builder gives access to the following fields:

* BASE
  * table: string,
  * select: varargs[string],
  * where: varargs[string],
* JOIN
  * joinargs: varargs[tuple[table: string, tableAs: string, on: seq[string]]] = [],
  * jointype: SQLJoinType = LEFT,
* WHERE IN
  * whereInField: string = "",
  * whereInValue: seq[string] = @[],
  * whereInValueString: seq[string] = @[],
  * whereInValueInt: seq[int] = @[],
* Custom SQL, e.g. ORDER BY
  * customSQL: string = "",
* Null checks
  * checkedArgs: ArgsContainer.query = @[],
* Table alias
  * tableAs: string = table,
* Soft delete
  * hideIsDeleted: bool = true,
  * tablesWithDeleteMarker: varargs[string] = @[],
  * deleteMarker = ".is_deleted IS NULL",

## Example on builder
```nim
test = sqlSelect(
  table     = "tasks",
  tableAs   = "t",
  select    = @["id", "name"],
  where     = @["id ="],
  joinargs  = @[(table: "projects", tableAs: "", on: @["projects.id = t.project_id", "projects.status = 1"])],
  jointype  = INNER
)
check querycompare(test, sql("SELECT id, name FROM tasks AS t INNER JOIN projects ON (projects.id = t.project_id AND projects.status = 1) WHERE id = ? "))
```

```nim
test = sqlSelect(
  table     = "tasksitems",
  tableAs   = "tasks",
  select    = @[
      "tasks.id",
      "tasks.name",
      "tasks.status",
      "tasks.created",
      "his.id",
      "his.name",
      "his.status",
      "his.created",
      "projects.id",
      "projects.name",
      "person.id",
      "person.name",
      "person.email"
    ],
  where     = @[
      "projects.id =",
      "tasks.status >"
    ],
  joinargs  = @[
      (table: "history", tableAs: "his", on: @["his.id = tasks.hid", "his.status = 1"]),
      (table: "projects", tableAs: "", on: @["projects.id = tasks.project_id", "projects.status = 1"]),
      (table: "person", tableAs: "", on: @["person.id = tasks.person_id"])
    ],
  whereInField = "tasks.id",
  whereInValue = @["1", "2", "3"],
  customSQL = "ORDER BY tasks.created DESC",
  tablesWithDeleteMarker = tableWithDeleteMarker
)
check querycompare(test, (sql("""
    SELECT
      tasks.id,
      tasks.name,
      tasks.status,
      tasks.created,
      his.id,
      his.name,
      his.status,
      his.created,
      projects.id,
      projects.name,
      person.id,
      person.name,
      person.email
    FROM
      tasksitems AS tasks
    LEFT JOIN history AS his ON
      (his.id = tasks.hid AND his.status = 1 AND his.is_deleted IS NULL)
    LEFT JOIN projects ON
      (projects.id = tasks.project_id AND projects.status = 1)
    LEFT JOIN person ON
      (person.id = tasks.person_id)
    WHERE
          projects.id = ?
      AND tasks.status > ?
      AND tasks.id in (1,2,3)
      AND tasks.is_deleted IS NULL
    ORDER BY
      tasks.created DESC
  """)))
```


## Convert legacy

The legacy SELECT builder is deprecated and will be removed in the future. It
is commented out in the source code, and a converter has been added to convert
the legacy query to the new builder.

That means, you don't have to worry, but you should definitely convert your
legacy queries to the new builder.

```nim
# Legacy builder
test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "", "", "")

check querycompare(test, sql("""
    SELECT
      t.id,
      t.name,
      p.id
    FROM
      tasks AS t
    LEFT JOIN project AS p ON
      (p.id = t.project_id)
    WHERE
      t.id = ?
  """))
```



# Examples

See the test files.



# Credit
Inspiration for builder: [Nim Forum](https://github.com/nim-lang/nimforum)
