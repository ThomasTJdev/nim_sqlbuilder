# Copyright 2020 - Thomas T. Jarløv


proc sqlInsert*(table: string, data: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for INSERT queries
  ## Checks for NULL values

  var fields = "INSERT INTO " & table & " ("
  var vals = ""
  for i, d in data:
    if args[i].isNull:
      continue
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(d)
    vals.add('?')

  when defined(testSqlquery):
    echo fields & ") VALUES (" & vals & ")"

  when defined(test):
    testout = fields & ") VALUES (" & vals & ")"

  result = sql(fields & ") VALUES (" & vals & ")")


proc sqlInsert*(table: string, data: varargs[string]): SqlQuery =
  ## SQL builder for INSERT queries
  ## Does NOT check for NULL values

  var fields = "INSERT INTO " & table & " ("
  var vals = ""
  for i, d in data:
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(d)
    vals.add('?')

  when defined(testSqlquery):
    echo fields & ") VALUES (" & vals & ")"

  when defined(test):
    testout = fields & ") VALUES (" & vals & ")"

  result = sql(fields & ") VALUES (" & vals & ")")


macro sqlInsertMacro*(table: string, data: varargs[string]): SqlQuery =
  ## SQL builder for INSERT queries
  ## Does NOT check for NULL values

  var fields = "INSERT INTO " & $table & " ("
  var vals = ""
  for i, d in data:
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add($d)
    vals.add('?')

  when defined(testSqlquery):
    echo fields & ") VALUES (" & vals & ")"

  result = parseStmt("sql(\"" & $fields & ") VALUES (" & $vals & ")\")")
