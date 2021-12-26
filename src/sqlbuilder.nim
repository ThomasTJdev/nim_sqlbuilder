# Copyright 2019 - Thomas T. Jarløv
##
## SQL builder
## ----------
##
## SQL builder for ``INSERT``, ``UPDATE``, ``SELECT`` and ``DELETE`` queries.
## The builder will check for NULL values and build a query with them.
##
## After Nim's update to 0.19.0, the check for NULL values has been removed
## due to the removal of ``nil``. This library's main goal is to allow the
## user, to insert NULL values into the database again.
##
## This packages uses Nim's standard packages, e.g. db_postgres,
## proc to escape qoutes.
##
##
## Macro generated queries
## --------
##
## The library supports generating the queries with a macro, which improves the
## performance due to query being generated on compile time. The macro generated
## queries **do not** accept the `genArgs()` - so there's currently not NULL-
## support.
##
##
## NULL values
## -------
##
##
## A NULL value
## ============
##
## The global ``var dbNullVal`` represents a NULL value. Use ``dbNullVal``
## in your args, if you need to insert/update to a NULL value.
##
## Insert value or NULL
## ============
##
## The global ``proc dbValOrNull()`` will check, if it's contain a value
## or is empty. If it contains a value, the value will be used in the args,
## otherwise a NULL value (``dbNullVal``) will be used.
##
## ``dbValOrNull()`` accepts both strings and int.
##
##
## Executing DB commands
## ============
##
## The examples below support the various DB commands such as ``exec``,
## ``tryExec``, ``insertID``, ``tryInsertID``, etc.
##
##
## Examples (NULL values)
## -------
##
##
## All the examples uses a table named: ``myTable`` and they use the WHERE argument on: ``name``.
##
## Update string & int
## =====================
##
## ### Version 1
## *Required if NULL values could be expected*
## .. code-block:: Nim
##    let a = genArgs("em@em.com", 20, "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> string, int
##    # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
##
##
## ### Version 2
## .. code-block:: Nim
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"]), "em@em.com", 20, "John")
##    # ==> string, int
##    # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
##
## Update NULL & int
## =====================
##
## .. code-block:: Nim
##    let a = genArgs("", 20, "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> NULL, int
##    # ==> UPDATE myTable SET email = NULL, age = ? WHERE name = ?
##
## Update string & NULL
## =====================
##
## .. code-block:: Nim
##    a = genArgs("aa@aa.aa", dbNullVal, "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> string, NULL
##    # ==> UPDATE myTable SET email = ?, age = NULL WHERE name = ?
##
## Error: Update string & NULL
## =====================
##
## An empty string, "", will be inserted into the database as NULL.
## Empty string cannot be used for an INTEGER column. You therefore
## need to use the ``dbValOrNull()`` or ``dbNullVal`` for ``int-values``.
##
## .. code-block:: Nim
##    a = genArgs("aa@aa.aa", "", "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> string, ERROR
##    # ==> UPDATE myTable SET email = ?, age = ? WHERE name = ?
##    # ==> To insert a NULL into a int-field, it is required to use dbValOrNull()
##    #     or dbNullVal, it is only possible to pass and empty string.
##
## Update NULL & NULL
## =====================
##
## .. code-block:: Nim
##    let cc = ""
##    a = genArgs(dbValOrNull(cc), dbValOrNull(cc), "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> NULL, NULL
##    # ==> UPDATE myTable SET email = NULL, age = NULL WHERE name = ?
##
##
## Update unknow value - maybe NULL
## =====================
##
## .. code-block:: Nim
##    a = genArgs(dbValOrNull(stringVar), dbValOrNull(intVar), "John")
##    exec(db, sqlUpdate("myTable", ["email", "age"], ["name"], a.query), a.args)
##    # ==> NULL, NULL -or- STRING, INT
##
##
## Examples (INSERT)
## -------
##
## Insert without NULL
## =====================
##
## .. code-block:: Nim
##    exec(db, sqlInsert("myTable", ["email", "age"]), "em@em.com" , 20)
##    # OR
##    insertID(db, sqlInsert("myTable", ["email", "age"]), "em@em.com", 20)
##    # ==> INSERT INTO myTable (email, age) VALUES (?, ?)
##
## Insert with NULL
## =====================
##
## .. code-block:: Nim
##    let a = genArgs("em@em.com", dbNullVal)
##    exec(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
##    # OR
##    insertID(db, sqlInsert("myTable", ["email", "age"], a.query), a.args)
##    # ==> INSERT INTO myTable (email) VALUES (?)
##
## Examples (SELECT)
## -------
##
## Select without NULL
## =====================
##
## .. code-block:: Nim
##    getValue(db, sqlSelect("myTable",
##      ["email", "age"], [""], ["name ="], "", "", ""), "John")
##    # SELECT email, age FROM myTable WHERE name = ?
##
##    getValue(db, sqlSelect("myTable",
##      ["myTable.email", "myTable.age", "company.name"],
##      ["company ON company.email = myTable.email"],
##      ["myTable.name =", "myTable.age ="], "", "", ""),
##      "John", "20")
##    # SELECT myTable.email, myTable.age, company.name
##    # FROM myTable
##    # LEFT JOIN company ON company.email = myTable.email
##    # WHERE myTable.name = ? AND myTable.age = ?
##
##    getAllRows(db, sqlSelect("myTable",
##      ["myTable.email", "myTable.age", "company.name"],
##      ["company ON company.email = myTable.email"],
##      ["company.name ="], "20,22,24", "myTable.age", "ORDER BY myTable.email"),
##      "BigBiz")
##    # SELECT myTable.email, myTable.age, company.name
##    # FROM myTable LEFT JOIN company ON company.email = myTable.email
##    # WHERE company.name = ? AND myTable.age IN (20,22,24)
##    # ORDER BY myTable.email
##
## Select with NULL
## =====================
##
## .. code-block:: Nim
##    let a = genArgs(dbNullVal)
##    getValue(db, sqlSelect("myTable",
##      ["email", "age"], [""], ["name ="], "", "", "", a.query), a.args)
##    # SELECT email, age FROM myTable WHERE name = NULL
##
##    let a = genArgs("John", dbNullVal)
##    getValue(db, sqlSelect("myTable",
##      ["myTable.email", "myTable.age", "company.name"],
##      ["company ON company.email = myTable.email"],
##      ["myTable.name =", "myTable.age ="], "", "", "", a.query), a.args)
##    # SELECT myTable.email, myTable.age, company.name
##    # FROM myTable
##    # LEFT JOIN company ON company.email = myTable.email
##    # WHERE myTable.name = ? AND myTable.age = NULL
##
##    let a = genArgs(dbNullVal)
##    getAllRows(db, sqlSelect("myTable",
##      ["myTable.email", "myTable.age", "company.name"],
##      ["company ON company.email = myTable.email"],
##      ["company.name ="], "20,22,24", "myTable.age", "ORDER BY myTable.email", a.query),
##      a.args)
##    # SELECT myTable.email, myTable.age, company.name
##    # FROM myTable LEFT JOIN company ON company.email = myTable.email
##    # WHERE company.name = NULL AND myTable.age IN (20,22,24)
##    # ORDER BY myTable.email
##
## # Credit
## Inspiration for builder: [Nim Forum](https://github.com/nim-lang/nimforum)

import
  std/db_common,
  std/macros,
  std/strutils

type
  ArgObj* = object ## Argument object
    val: string
    isNull: bool

  ArgsContainer* = object ## Argument container used for queries and args
    query*: seq[ArgObj]
    args*: seq[string]

  ArgsFormat = object
    use: bool
    column: string
    value: ArgObj


when defined(test):
  var testout*: string


const dbNullVal* = ArgObj(isNull: true) ## Global NULL value


proc argType*(v: ArgObj): ArgObj =
  ## Checks if a ``ArgObj`` is NULL and return
  ## ``dbNullVal``. If it's not NULL, the passed
  ## ``ArgObj`` is returned.
  if v.isNull:
    return dbNullVal
  else:
    return v


proc argType*(v: string | int): ArgObj =
  ## Transforms a string or int to a ``ArgObj``
  var arg: ArgObj
  arg.isNull = false
  arg.val = $v
  return arg


proc argTypeSetNull*(v: ArgObj): ArgObj =
  if v.isNull:
    return dbNullVal
  elif v.val.len() == 0:
    return dbNullVal
  else:
    return v


proc argTypeSetNull*(v: string | int): ArgObj =
  var arg: ArgObj
  if len($v) == 0:
    return dbNullVal
  else:
    arg.isNull = false
    arg.val = $v
    return arg


proc dbValOrNull*(v: string | int): ArgObj =
  ## Return NULL obj if len() == 0, else return value obj
  if len($v) == 0:
    return dbNullVal
  var arg: ArgObj
  arg.val = $v
  arg.isNull = false
  return arg


proc argFormat*(v: tuple): ArgsFormat =
  ## Formats the tuple, so int, float, bool, etc. can be used directly.
  result.use = v[0]
  result.column = v[1]
  result.value = argType(v[2])


template genArgs*[T](arguments: varargs[T, argType]): ArgsContainer =
  ## Create argument container for query and passed args. This allows for
  ## using NULL in queries.
  var argsContainer: ArgsContainer
  argsContainer.query = @[]
  argsContainer.args = @[]
  for arg in arguments:
    let argObject = argType(arg)
    if argObject.isNull:
      argsContainer.query.add(argObject)
    else:
      argsContainer.query.add(argObject)
      argsContainer.args.add(argObject.val)
  argsContainer


template genArgsSetNull*[T](arguments: varargs[T, argType]): ArgsContainer =
  ## Create argument container for query and passed args
  var argsContainer: ArgsContainer
  argsContainer.query = @[]
  argsContainer.args = @[]
  for arg in arguments:
    let argObject = argTypeSetNull(arg)
    if argObject.isNull:
      argsContainer.query.add(argObject)
    else:
      argsContainer.query.add(argObject)
      argsContainer.args.add(argObject.val)
  argsContainer


template genArgsColumns*[T](arguments: varargs[T, argFormat]): tuple[select: seq[string], args: ArgsContainer] =
  ## Create argument container for query and passed args and selecting which
  ## columns to update. It's and expansion of `genArgs()`, since you can
  ## decide which columns, there should be included.
  ##
  ##
  ## Lets say, that you are importing data from a spreadsheet with static
  ## columns, and you need to update your DB with the new values.
  ##
  ## If the spreadsheet contains an empty field, you can update your DB with the
  ## NULL value. But sometimes the spreadsheet only contains 5 out of the 10
  ## static columns. Now you don't know the values of the last 5 columns,
  ## which will result in updating the DB with NULL values.
  ##
  ## This template allows you to use the same query, but dynamic selecting only the
  ## columns which shall be updated. When importing your spreadsheet, check
  ## if the column exists (bool), and pass that as the `use: bool` param. If
  ## the column does not exists, it will be skipped in the query.
  var
    select: seq[string]
    argsContainer: ArgsContainer
  argsContainer.query = @[]
  argsContainer.args = @[]
  for arg in arguments:
    let argObject = argType(arg.value)
    if not arg.use:
      continue
    if arg.column != "":
      select.add(arg.column)
    if argObject.isNull:
      argsContainer.query.add(argObject)
    else:
      argsContainer.query.add(argObject)
      argsContainer.args.add(argObject.val)
  (select, argsContainer)


include sqlbuilderpkg/insert
include sqlbuilderpkg/update
include sqlbuilderpkg/delete
include sqlbuilderpkg/select


when isMainModule:
  from times import epochTime
  let a = epochTime()
  for i in countup(0,100000):
    let a = sqlSelectMacro("myTable", ["id", "name", "j"], [""], ["email =", "name ="], "", "", "")

  let b = epochTime()

  let c = epochTime()
  for i in countup(0,100000):
    let a = sqlSelect("myTable", ["id", "name", "j"], [""], ["email =", "name ="], "", "", "")

  let d = epochTime()

  echo "Select:"
  echo "Macro:  " & $(b-a)
  echo "Normal: " & $(d-c)
  echo "Diff:   " & $((d-c) - (b-a))

  echo "\n\n"


  let im1 = epochTime()
  for i in countup(0,100000):
    let a = sqlInsertMacro("myTable", ["id", "name", "j"])

  let im2 = epochTime()

  let ip1 = epochTime()
  for i in countup(0,100000):
    let a = sqlInsert("myTable", ["id", "name", "j"])

  let ip2 = epochTime()

  echo "Update:"
  echo "Macro:  " & $(im2-im1)
  echo "Normal: " & $(ip2-ip1)
  echo "Diff:   " & $((ip2-ip1) - (im2-im1))

  echo "\n\n"


  let um1 = epochTime()
  for i in countup(0,100000):
    let a = sqlUpdateMacro("myTable", ["id", "name", "j"], ["id", "session"])

  let um2 = epochTime()

  let up1 = epochTime()
  for i in countup(0,100000):
    let a = sqlUpdate("myTable", ["id", "name", "j"], ["id", "session"])

  let up2 = epochTime()

  echo "Update:"
  echo "Macro:  " & $(um2-um1)
  echo "Normal: " & $(up2-up1)
  echo "Diff:   " & $((up2-up1) - (um2-um1))

  echo "\n\n"


  let dm1 = epochTime()
  for i in countup(0,100000):
    let a = sqlDeleteMacro("myTable", ["id", "name", "j"])

  let dm2 = epochTime()

  let dp1 = epochTime()
  for i in countup(0,100000):
    let a = sqlDelete("myTable", ["id", "name", "j"])

  let dp2 = epochTime()

  echo "Delete:"
  echo "Macro:  " & $(dm2-dm1)
  echo "Normal: " & $(dp2-dp1)
  echo "Diff:   " & $((dp2-dp1) - (dm2-dm1))