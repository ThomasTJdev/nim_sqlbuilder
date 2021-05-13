# Copyright 2020 - Thomas T. Jarløv


proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Checks for NULL values

  var fields = "UPDATE " & table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    if args[i].isNull:
      fields.add(d & " = NULL")
    else:
      fields.add(d & " = ?")
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  when defined(testSqlquery):
    echo fields & wes

  when defined(test):
    testout = fields & wes

  result = sql(fields & wes)


proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string]): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Does NOT check for NULL values

  var fields = "UPDATE " & table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    fields.add(d & " = ?")
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  when defined(testSqlquery):
    echo fields & wes

  when defined(test):
    testout = fields & wes

  result = sql(fields & wes)


macro sqlUpdateMacro*(table: string, data: varargs[string], where: varargs[string]): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Does NOT check for NULL values

  var fields = "UPDATE " & $table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    fields.add($d & " = ?")
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add($d & " = ?")

  when defined(testSqlquery):
    echo fields & wes

  result = parseStmt("sql(\"" & fields & wes & "\")")