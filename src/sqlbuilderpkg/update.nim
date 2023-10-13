# Copyright 2020 - Thomas T. Jarløv

when NimMajor >= 2:
  import
    db_connector/db_common
else:
  import
    std/db_common

import
  std/macros,
  std/strutils

import
  ./utils


proc updateSetFormat(v: string): string =
  let
    field = v.strip()
    fieldSplit = field.split("=")

  #
  # Does the data have a `=` sign?
  #
  if fieldSplit.len() == 2:
    #
    # If the data is only having equal but no value, insert a `?` sign
    #
    if fieldSplit[1] == "":
      return (field & " ?")
    #
    # Otherwise just add the data as is, eg. `field = value`
    #
    else:
      return (field)

  #
  # Otherwise revert to default
  #
  else:
    return (field & " = ?")



proc updateSet(data: varargs[string]): string =
  for i, d in data:
    if i > 0:
      result.add(", ")

    result.add(updateSetFormat(d))

  return result


proc updateWhereFormat(v: string): string =
  let
    field = v.strip()

  var fieldSplit: seq[string]
  if field.contains(" "):
    if field.contains("="):
      fieldSplit = field.split("=")
    elif field.contains("IS NOT"):
      fieldSplit = field.split("IS NOT")
    elif field.contains("IS"):
      fieldSplit = field.split("IS")
    elif field.contains("NOT IN"):
      fieldSplit = field.split("NOT IN")
    elif field.contains("IN"):
      fieldSplit = field.split("IN")
    elif field.contains("!="):
      fieldSplit = field.split("!=")
    elif field.contains("<="):
      fieldSplit = field.split("<=")
    elif field.contains(">="):
      fieldSplit = field.split(">=")
    elif field.contains("<"):
      fieldSplit = field.split("<")
    elif field.contains(">"):
      fieldSplit = field.split(">")
  else:
    fieldSplit = field.split("=")

  #
  # Does the data have a `=` sign?
  #
  if fieldSplit.len() == 2:
    #
    # If the data is only having equal but no value, insert a `?` sign
    #
    if fieldSplit[1] == "":
      return (field & " ?")
    #
    # Otherwise just add the data as is, eg. `field = value`
    #
    else:
      return (field)

  #
  # Otherwise revert to default
  #
  else:
    return (field & " = ?")


proc updateWhere(where: varargs[string]): string =
  var wes = " WHERE "
  for i, v in where:
    if i > 0:
      wes.add(" AND ")

    wes.add(updateWhereFormat(v))

  return wes


proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Checks for NULL values

  var fields = "UPDATE " & table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    if args[i].isNull:
      fields.add(d & " = NULL")
    elif d.len() > 5 and d[(d.high-3)..d.high] == "NULL":
      fields.add(d)
    elif d[d.high-1..d.high] == "=":
      fields.add(d & " ?")
    else:
      fields.add(d & " = ?")

  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    if d[d.high..d.high] == "=":
      wes.add(d & " ?")
    else:
      wes.add(d & " = ?")

  when defined(testSqlquery):
    echo fields & wes

  when defined(test):
    testout = fields & wes

  result = sql(fields & wes)


proc sqlUpdate*(
    table: string,
    data: varargs[string],
    where: varargs[string]
  ): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Does NOT check for NULL values

  var fields = "UPDATE " & table & " SET "

  fields.add(updateSet(data))

  fields.add(updateWhere(where))


  when defined(testSqlquery):
    echo fields

  when defined(test):
    testout = fields

  result = sql(fields)




proc updateSet(data: NimNode): string =
  for i, v in data:
    # Convert NimNode to string
    let d = $v

    if i > 0:
      result.add(", ")

    result.add(updateSetFormat(d))

  return result


proc updateWhere(where: NimNode): string =
  var wes = " WHERE "
  for i, v in where:
    # Convert NimNode to string
    let d = $v

    if i > 0:
      wes.add(" AND ")

    wes.add(updateWhereFormat(d))

  return wes


macro sqlUpdateMacro*(table: string, data: varargs[string], where: varargs[string]): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Does NOT check for NULL values

  var fields = "UPDATE " & $table & " SET "

  fields.add(updateSet(data))

  fields.add(updateWhere(where))

  when defined(testSqlquery):
    echo fields

  result = parseStmt("sql(\"" & fields & "\")")