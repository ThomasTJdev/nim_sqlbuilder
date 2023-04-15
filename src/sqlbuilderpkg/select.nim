# Copyright 2020 - Thomas T. Jarløv


import
  std/db_common,
  std/macros,
  std/strutils

import
  ./utils



macro sqlSelectConst*(
    # BASE
    table: string,
    select: varargs[string],
    where: varargs[string],
    # Join
    joinargs: static varargs[tuple[table: string, tableAs: string, on: seq[string]]] = [],
    jointype: SQLJoinType = SQLJoinType.LEFT,
    # WHERE-IN
    whereInField: string = "",
    whereInValue: varargs[string] = [],
    # Custom SQL, e.g. ORDER BY
    customSQL: string = "",
    # Table alias
    tableAs: string = "",# = $table,
    # Soft delete
    hideIsDeleted: bool = true,
    tablesWithDeleteMarker: varargs[string] = (when declared(tablesWithDeleteMarker): tablesWithDeleteMarker else: []), #@[],
    deleteMarker = ".is_deleted IS NULL",
    testValue: string = "",
  ): SqlQuery =
  ## SQL builder for SELECT queries


  #
  # Select
  var res = "SELECT "
  for i, d in select:
    if i > 0: res.add(", ")
    res.add($d)


  #
  # Joins
  var lef = ""


  for d in joinargs:
    if d.repr.len == 0 and joinargs.len() == 2:
      break

    lef.add(" " & $jointype & " JOIN ")
    lef.add($d.table & " ")

    if d.tableAs != "" and d.tableAs != d.table:
      lef.add("AS " & $d.tableAs & " ")

    lef.add("ON (")

    for i, join in d.on:
      if i > 0:
        lef.add(" AND ")
      lef.add($join)

    if $hideIsDeleted == "true" and tablesWithDeleteMarker.len() > 0:
      var hit = false
      for t in tablesWithDeleteMarker:
        if $t == $d.table:
          hit = true
          break

      if hit:
        lef.add(" AND " & (if d.tableAs.len() > 0 and $d.tableAs != $d.table: $d.tableAs else: $d.table) & $deleteMarker)

    lef.add(")")


  #
  # Where
  var wes = ""
  for i, d in where:
    let v = $d

    if v.len() > 0 and i == 0:
      wes.add(" WHERE ")

    if i > 0:
      wes.add(" AND ")

    if v.len() > 0:
      wes.add(v & " ?")



  var acc = ""
  if ($whereInField).len() > 0 and (whereInValue).len() > 0:
    if wes.len == 0:
      acc.add(" WHERE " & $whereInField & " in (")
    else:
      acc.add(" AND " & $whereInField & " in (")


    var inVal: string

    for a in whereInValue:
      if inVal != "":
        inVal.add(",")
      inVal.add($a)

    acc.add(if inVal == "": "0" else: inVal)
    acc.add(")")



  #
  # Soft delete
  if $hideIsDeleted == "true" and tablesWithDeleteMarker.len() > 0:
    var hit = false
    for t in tablesWithDeleteMarker:
      if $t == $table:
        hit = true
        break

    if hit:
      let tableNameToUse =
          if ($tableAs).len() > 0 and $tableAs != $table:
            $tableAs
          else:
            $table

      if wes == "" and acc == "":
        wes.add(" WHERE " & $tableNameToUse & $deleteMarker)
      elif acc != "":
        acc.add(" AND " & $tableNameToUse & $deleteMarker)
      else:
        wes.add(" AND " & $tableNameToUse & $deleteMarker)



  #
  # Base
  let tableName =
    if ($tableAs).len() > 0 and $table != $tableAs:
      $table & " AS " & $tableAs
    else:
      $table



  when defined(verboseSqlquery):
    echo "SQL Macro:"
    echo res & " FROM " & tableName & lef & wes & acc & " " & $customSQL


  result = parseStmt("sql(\"" & res & " FROM " & tableName & lef & wes & acc & " " & $customSQL & "\")")




proc sqlSelect*(
    # BASE
    table: string,
    select: varargs[string],
    where: varargs[string],
    # Join
    joinargs: varargs[tuple[table: string, tableAs: string, on: seq[string]]] = [],
    jointype: SQLJoinType = LEFT,
    joinoverride: string = "",
    # WHERE-IN
    whereInField: string = "",
    whereInValue: seq[string] = @[],
    whereInValueString: seq[string] = @[],
    whereInValueInt: seq[int] = @[],
    # Custom SQL, e.g. ORDER BY
    customSQL: string = "",
    # Null checks
    checkedArgs: ArgsContainer.query = @[],
    # Table alias
    tableAs: string = table,
    # Soft delete
    hideIsDeleted: bool = true,
    tablesWithDeleteMarker: varargs[string] = (when declared(tablesWithDeleteMarker): tablesWithDeleteMarker else: []), #@[],
    deleteMarker = ".is_deleted IS NULL",
  ): SqlQuery =
  ## SQL builder for SELECT queries


  #
  # Select
  var res = "SELECT "
  for i, d in select:
    if i > 0: res.add(", ")
    res.add(d)


  #
  # Joins
  var lef = ""
  for i, d in joinargs:
    lef.add(" " & $jointype & " JOIN ")
    lef.add(d.table & " ")

    if d.tableAs != "" and d.tableAs != d.table:
      lef.add("AS " & d.tableAs & " ")

    lef.add("ON (")
    for i, join in d.on:
      if i > 0:
        lef.add(" AND ")
      lef.add(join)

    if hideIsDeleted and tablesWithDeleteMarker.len() > 0 and d.table in tablesWithDeleteMarker:
      lef.add(" AND " & (if d.tableAs != "" and d.tableAs != d.table: d.tableAs else: d.table) & deleteMarker)
    lef.add(")")

  if joinoverride.len() > 0:
    lef.add(" " & joinoverride)

  #
  # Where
  var wes = ""
  for i, d in where:
    if d != "" and i == 0:
      wes.add(" WHERE ")

    if i > 0:
      wes.add(" AND ")

    if d != "":
      if checkedArgs.len() > 0 and checkedArgs[i].isNull:
        wes.add(d & " NULL")
      else:
        wes.add(d & " ?")


  #
  # Where IN
  var acc = ""
  if whereInField != "" and (whereInValue.len() > 0 or whereInValueString.len() > 0 or whereInValueInt.len() > 0):
    if wes.len == 0:
      acc.add(" WHERE " & whereInField & " in (")
    else:
      acc.add(" AND " & whereInField & " in (")

    var inVal: string

    if whereInValue.len() > 0:
      inVal.add(whereInValue.join(","))

    elif whereInValueString.len() > 0:
      for a in whereInValueString:
        if a == "":
          continue

        if inVal != "":
          inVal.add(",")

        inVal.add("'" & a & "'")

    else:
      for a in whereInValueInt:
        if inVal != "":
          inVal.add(",")
        inVal.add($a)

    acc.add(if inVal == "": "0" else: inVal)
    acc.add(")")




  #
  # Soft delete
  if hideIsDeleted and tablesWithDeleteMarker.len() > 0 and table in tablesWithDeleteMarker:
    let tableNameToUse =
        if tableAs.len() > 0 and tableAs != table:
          tableAs
        else:
          table

    if wes == "" and acc == "":
      wes.add(" WHERE " & tableNameToUse & deleteMarker)
    elif acc != "":
      acc.add(" AND " & tableNameToUse & deleteMarker)
    else:
      wes.add(" AND " & tableNameToUse & deleteMarker)


  #
  # Alias
  let tableName =
    if tableAs != "" and table != tableAs:
      table & " AS " & tableAs
    else:
      table


  #
  # Finalize
  when defined(verboseSqlquery):
    echo res & " FROM " & tableName & lef & wes & acc & " " & customSQL


  result = sql(res & " FROM " & tableName & lef & wes & acc & " " & customSQL)







proc sqlSelect*(
    table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string,
    args: ArgsContainer.query = @[],
    hideIsDeleted: bool = true,
    tablesWithDeleteMarker: varargs[string] = (when declared(tablesWithDeleteMarker): tablesWithDeleteMarker else: []), #@[],
    deleteMarker = ".is_deleted IS NULL",
  ): SqlQuery {.deprecated.} =


  var leftcon: seq[tuple[table: string, tableAs: string, on: seq[string]]]
  var joinoverride: string
  for raw in left:
    if raw.len() == 0:
      continue

    if raw.len() >= 7 and raw[0..6].toLowerAscii() == "lateral":
      joinoverride = "LEFT JOIN " & raw
      continue

    let d = raw#.toLowerAscii()

    let
      lsplit1 = if d.contains(" ON "): d.split(" ON ") else: d.split(" on ")
      lsplit2 = if lsplit1[0].contains(" AS "): lsplit1[0].split(" AS ") else: lsplit1[0].split(" as ")
      hasAlias = (lsplit2.len() > 1)

    leftcon.add(
      (
        table: lsplit2[0].strip(),
        tableAs: (if hasAlias: lsplit2[1].strip() else: ""),
        on: @[lsplit1[1].strip()]
      )
    )

  let
    tableSplit = if table.contains(" AS "): table.split(" AS ") else: table.split(" as ") #table.toLowerAscii().split(" as ")
    tableName =
        if tableSplit.len() > 1:
          tableSplit[0]
        else:
          table
    tableAsName =
        if tableSplit.len() > 1:
          tableSplit[1]
        else:
          ""

  return sqlSelect(
    table     = tableName,
    tableAs   = tableAsName,
    select    = data,
    joinargs  = leftcon,
    jointype  = LEFT,
    joinoverride = joinoverride,
    where     = whereC,
    whereInField = accessC,
    whereInValue = @[access],
    customSQL = user,
    checkedArgs = args,
    hideIsDeleted = hideIsDeleted,
    tablesWithDeleteMarker = tablesWithDeleteMarker,
    deleteMarker = deleteMarker
  )


#[
proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string): SqlQuery =
  ## SQL builder for SELECT queries
  ## Does NOT check for NULL values

  var res = "SELECT "
  for i, d in data:
    if i > 0: res.add(", ")
    res.add(d)

  var lef = ""
  for i, d in left:
    if d != "":
      lef.add(" LEFT JOIN ")
      lef.add(d)

  var wes = ""
  for i, d in whereC:
    if d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if d != "":
      wes.add(d & " ?")

  var acc = ""
  if access != "":
    if wes.len == 0:
      acc.add(" WHERE " & accessC & " in ")
      acc.add("(")
    else:
      acc.add(" AND " & accessC & " in (")
    var inVal: string
    for a in split(access, ","):
      if a == "": continue
      if inVal != "":
        inVal.add(",")
      inVal.add(a)
    acc.add(if inVal == "": "0" else: inVal)
    acc.add(")")

  when defined(testSqlquery):
    echo res & " FROM " & table & lef & wes & acc & " " & user

  when defined(test):
    testout = res & " FROM " & table & lef & wes & acc & " " & user

  result = sql(res & " FROM " & table & lef & wes & acc & " " & user)


proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string, args: ArgsContainer.query): SqlQuery =
  ## SQL builder for SELECT queries
  ## Checks for NULL values

  var res = "SELECT "
  for i, d in data:
    if i > 0: res.add(", ")
    res.add(d)

  var lef = ""
  for i, d in left:
    if d != "":
      lef.add(" LEFT JOIN ")
      lef.add(d)

  var wes = ""
  for i, d in whereC:
    if d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if d != "":
      if args[i].isNull:
        wes.add(d & " = NULL")
      else:
        wes.add(d & " ?")

  var acc = ""
  if access != "":
    if wes.len == 0:
      acc.add(" WHERE " & accessC & " in ")
      acc.add("(")
    else:
      acc.add(" AND " & accessC & " in (")

    var inVal: string
    for a in split(access, ","):
      if a == "": continue
      if inVal != "":
        inVal.add(",")
      inVal.add(a)
    acc.add(if inVal == "": "0" else: inVal)
    acc.add(")")

  when defined(testSqlquery):
    echo res & " FROM " & table & lef & wes & acc & " " & user

  when defined(test):
    testout = res & " FROM " & table & lef & wes & acc & " " & user

  result = sql(res & " FROM " & table & lef & wes & acc & " " & user)
]#

macro sqlSelectMacro*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string): SqlQuery {.deprecated.} =
  ## SQL builder for SELECT queries
  ## Does NOT check for NULL values

  var res: string
  for i, d in data:
    if i > 0:
      res.add(", ")
    res.add($d)

  var lef: string
  for i, d in left:
    if $d != "":
      lef.add(" LEFT JOIN " & $d)

  var wes: string
  for i, d in whereC:
    if $d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if $d != "":
      wes.add($d & " ?")

  var acc: string
  if access.len() != 0:
    if wes.len == 0:
      acc.add(" WHERE " & $accessC & " in (")
    else:
      acc.add(" AND " & $accessC & " in (")
    for a in split($access, ","):
      acc.add(a & ",")
    acc = acc[0 .. ^2]
    if acc.len() == 0:
      acc.add("0")
    acc.add(")")

  when defined(testSqlquery):
    echo "SELECT " & res & " FROM " & $table & lef & wes & acc & " " & $user

  result = parseStmt("sql(\"SELECT " & res & " FROM " & $table & lef & wes & acc & " " & $user & "\")")

