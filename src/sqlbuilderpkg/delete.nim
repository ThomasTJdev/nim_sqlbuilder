# Copyright 2020 - Thomas T. Jarløv

proc sqlDelete*(table: string, where: varargs[string]): SqlQuery =
  ## SQL builder for DELETE queries
  ## Does NOT check for NULL values

  var res = "DELETE FROM " & table
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  when defined(testSqlquery):
    echo res & wes

  result = sql(res & wes)


proc sqlDelete*(table: string, where: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for DELETE queries
  ## Checks for NULL values

  var res = "DELETE FROM " & table
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    if args[i].isNull:
      wes.add(d & " = NULL")
    else:
      wes.add(d & " = ?")

  when defined(testSqlquery):
    echo res & wes

  result = sql(res & wes)


macro sqlDeleteMacro*(table: string, where: varargs[string]): SqlQuery =
  ## SQL builder for SELECT queries
  ## Does NOT check for NULL values

  var res = "DELETE FROM " & $table
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add($d & " = ?")

  when defined(testSqlquery):
    echo res & wes

  result = parseStmt("sql(\"" & res & wes & "\")")
