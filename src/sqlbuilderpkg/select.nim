# Copyright 2020 - Thomas T. Jarløv

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/macros,
  std/strutils

import
  ./utils_private

from ./utils import SQLJoinType, ArgsContainer


##
## Constant generator utilities
##
proc sqlSelectConstSelect(select: varargs[string]): string =
  result = "SELECT "
  for i, d in select:
    if i > 0: result.add(", ")
    result.add($d)


proc sqlSelectConstJoin(
    joinargs: varargs[tuple[table: string, tableAs: string, on: seq[string]]],
    jointype: NimNode
  ): string =
  var lef = ""

  if joinargs.len == 0:
    return

  for d in joinargs:
    if d.repr.len == 0 and joinargs.len() == 2:
      continue

    lef.add(" " & $jointype & " JOIN ")
    lef.add($d.table & " ")

    if d.tableAs != "" and d.tableAs != d.table:
      lef.add("AS " & $d.tableAs & " ")

    lef.add("ON (")

    for i, join in d.on:
      if i > 0:
        lef.add(" AND ")
      lef.add($join)

    lef.add(")")

  return lef


proc sqlSelectConstWhere(where: varargs[string], usePrepared: NimNode): string =

  var
    wes = ""
    prepareCount = 0

  for i, d in where:
    let v = $d

    if v.len() > 0 and i == 0:
      wes.add(" WHERE ")

    if i > 0:
      wes.add(" AND ")

    if v.len() > 0:

      # => ... = NULL
      if v[(v.high - 3)..v.high] == "NULL":
        wes.add(v)

      # => ? = ANY(...)
      elif v.len() > 5 and v[0..4] == "= ANY":
        if boolVal(usePrepared):
          prepareCount += 1
          wes.add("$" & $prepareCount & " " & v)
        else:
          wes.add("? " & v)

      # => ... IN (?)
      elif v[(v.high - 2)..v.high] == " IN":
        if boolVal(usePrepared):
          prepareCount += 1
          wes.add(v & " ($" & $prepareCount & ")")
        else:
          wes.add(v & " (?)")

      # => ? IN (...)
      elif v.len() > 2 and v[0..1] == "IN":
        if boolVal(usePrepared):
          prepareCount += 1
          wes.add("$" & $prepareCount & " " & v)
        else:
          wes.add("? " & v)

      # => ... = ?
      else:
        if boolVal(usePrepared):
          prepareCount += 1
          wes.add(v & " $" & $prepareCount)
        else:
          wes.add(v & " ?")

  return wes


proc sqlSelectConstWhereIn(
    wes, acc: string,
    whereInField: NimNode, whereInValue: NimNode
  ): string =
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

  return acc


proc sqlSelectConstSoft(
    wes, acc: string,
    tablesInQuery: seq[tuple[table: string, tableAs: string]],
    tablesWithDeleteMarker: varargs[string],
    useDeleteMarker: NimNode,
    deleteMarker: NimNode
  ): (string, string) =
  if $useDeleteMarker == "true" and tablesWithDeleteMarker.len() > 0:
    var wesTo, accTo: string

    for t in tablesInQuery:
      if t.table notin tablesWithDeleteMarker:
        continue

      let toUse = if t.tableAs != "": t.tableAs else: t.table

      if wes == "" and acc == "":
        wesTo.add(" WHERE " & toUse & $deleteMarker)

      elif acc != "":
        accTo.add(" AND " & toUse & $deleteMarker)

      else:
        wesTo.add(" AND " & toUse & $deleteMarker)

    return (wesTo, accTo)



##
## Constant generator
##
macro sqlSelectConst*(
    # BASE
    table: string,
    select: static varargs[string],
    where: static varargs[string],

    # Join
    joinargs: static varargs[tuple[table: string, tableAs: string, on: seq[string]]] = [],
    jointype: SQLJoinType = SQLJoinType.LEFT,

    # WHERE-IN
    whereInField: string = "",
    whereInValue: varargs[string] = [],

    # Custom SQL, e.g. ORDER BY
    customSQL: string = "",

    # Table alias
    tableAs: string = "",

    # Prepare statement
    usePrepared: bool = false,

    # Soft delete
    useDeleteMarker: bool = true,
    # If we are using `static` then we can assign const-variables to it. It not,
    # we must use direct varargs.
    tablesWithDeleteMarker: varargs[string] = [],
    deleteMarker = ".is_deleted IS NULL",
  ): SqlQuery =
  ## SQL builder for SELECT queries



  var deleteMarkersFields: seq[string]
  if tablesWithDeleteMarker.len() > 0:
    for t in tablesWithDeleteMarker:
      if t.repr.len == 0:
        continue
      if $t notin deleteMarkersFields:
        deleteMarkersFields.add($t)

  when declared(tablesWithDeleteMarkerInit):
    for t in tablesWithDeleteMarkerInit:
      if t.repr.len == 0:
        continue
      if t notin deleteMarkersFields:
        deleteMarkersFields.add(t)


  #
  # Create seq of tables
  #
  var tablesInQuery: seq[tuple[table: string, tableAs: string]]

  # Base table
  if $tableAs != "" and $table != $tableAs:
    tablesInQuery.add(($table, $tableAs))
  else:
    tablesInQuery.add(($table, ""))

  # Join table
  var joinTablesUsed: seq[string]
  if joinargs.len != 0:
    for i, d in joinargs:
      if d.repr.len == 0:
        continue

      if $d.table in joinTablesUsed:
        continue
      joinTablesUsed.add($d.table)

      if $d.tableAs != "" and $d.tableAs != $d.table:
        tablesInQuery.add(($d.table, $d.tableAs))
      else:
        tablesInQuery.add(($d.table, ""))


  #
  # Base - from table
  #
  let tableName =
    if ($tableAs).len() > 0 and $table != $tableAs:
      $table & " AS " & $tableAs
    else:
      $table


  #
  # Select
  if select.len() == 0:
    raise newException(
      Exception,
      "Bad SQL format. Please check your SQL statement. " &
      "This is most likely caused by a missing SELECT clause. " &
      "Bug: `select.len() == 0` in \n" & $select
    )
  var res = sqlSelectConstSelect(select)


  #
  # Joins
  #
  var lef = ""
  if joinargs.len != 0:
    lef = sqlSelectConstJoin(joinargs, jointype)


  #
  # Where - normal
  #
  var wes = sqlSelectConstWhere(where, usePrepared)



  #
  # Where - n IN (x,c,v)
  #
  var acc = ""
  acc.add sqlSelectConstWhereIn(wes, acc, whereInField, whereInValue)


  #
  # Soft delete
  #
  var (toWes, toAcc) = sqlSelectConstSoft(
      wes, acc,
      tablesInQuery,
      deleteMarkersFields,
      useDeleteMarker, deleteMarker
    )
  wes.add(toWes)
  acc.add(toAcc)

  #
  # Combine the pretty SQL
  #
  let finalSQL =  res & " FROM " & tableName & lef & wes & acc & " " & $customSQL


  #
  # Error checking
  #

  var illegal = hasIllegalFormats($finalSQL)
  if illegal.len() > 0:
    raise newException(
      Exception,
      "Bad SQL format. Please check your SQL statement. " &
      "This is most likely caused by a missing WHERE clause. " &
      "Bug: `" & illegal & "` in \n" & finalSQL
    )

  if $table != $tableAs and lef.len() > 0:
    var hit: bool
    for s in select:
      if "." notin s:
        echo "WARNING (SQL MACRO): Missing table alias in select statement: " & $s
        hit = true
    if hit:
      echo "WARNING (SQL MACRO): " & finalSQL



  result = parseStmt("sql(\"" & finalSQL & "\")")





proc sqlSelect*(
    # BASE
    table: string,
    select: varargs[string],
    where: varargs[string],

    # Join
    joinargs: varargs[tuple[table: string, tableAs: string, on: seq[string]]] = [],
    jointype: SQLJoinType = LEFT,
    joinoverride: string = "",    # Override the join statement by inserting without check

    # WHERE-IN
    whereInField: string = "",
    whereInValue: varargs[string] = [],       # Could be unsafe. Is not checked.
    whereInValueString: seq[string] = @[],
    whereInValueInt: seq[int] = @[],

    # Custom SQL, e.g. ORDER BY
    customSQL: string = "",

    # Null checks
    checkedArgs: ArgsContainer.query = @[],

    # Table alias
    tableAs: string = table,

    # Prepare statement
    usePrepared: bool = false,

    # Soft delete
    useDeleteMarker: bool = true,
    tablesWithDeleteMarker: varargs[string] = [], #(when declared(tablesWithDeleteMarkerInit): tablesWithDeleteMarkerInit else: []), #@[],
    deleteMarker = ".is_deleted IS NULL",
  ): SqlQuery =
  ## SQL builder for SELECT queries


  var deleteMarkersFields: seq[string]
  for t in tablesWithDeleteMarker:
    if t == "":
      continue
    if t notin deleteMarkersFields:
      deleteMarkersFields.add(t)

  when declared(tablesWithDeleteMarkerInit):
    for t in tablesWithDeleteMarkerInit:
      if t == "":
        continue
      if t notin deleteMarkersFields:
        deleteMarkersFields.add(t)

  #
  # Create seq of tables
  #
  var tablesInQuery: seq[tuple[table: string, tableAs: string]]


  # Base table
  if $tableAs != "" and $table != $tableAs:
    tablesInQuery.add(($table, $tableAs))
  else:
    tablesInQuery.add(($table, ""))


  # Join table
  if joinargs.len() > 0:
    for d in joinargs:
      if d.table == "":
        continue
      if d.tableAs != "" and d.tableAs != d.table:
        tablesInQuery.add((d.table, d.tableAs))
      else:
        tablesInQuery.add((d.table, ""))


  #
  # Base - from table
  #
  let tableName =
    if tableAs != "" and table != tableAs:
      table & " AS " & tableAs
    else:
      table


  #
  # Select
  #
  var res = "SELECT "
  for i, d in select:
    if i > 0: res.add(", ")
    res.add(d)


  #
  # Joins
  #
  var lef = ""
  if joinargs.len() > 0:
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

      lef.add(")")

  if joinoverride.len() > 0:
    lef.add(" " & joinoverride)


  #
  # Where - normal
  #
  var
    wes = ""
    prepareCount = 0
  for i, d in where:
    if d != "" and i == 0:
      wes.add(" WHERE ")

    if i > 0:
      wes.add(" AND ")

    if d != "":
      # => ... = NULL
      if checkedArgs.len() > 0 and checkedArgs[i].isNull:
        wes.add(d & " NULL")

      # => ... = NULL
      elif d[(d.high - 3)..d.high] == "NULL":
        wes.add(d)

      # => ? = ANY(...)
      elif d.len() > 5 and d[0..4] == "= ANY":
        if usePrepared:
          prepareCount += 1
          wes.add("$" & $prepareCount & " " & d)
        else:
          wes.add("? " & d)

      # => ... IN (?)
      elif d[(d.high - 2)..d.high] == " IN":
        if usePrepared:
          prepareCount += 1
          wes.add(d & " ($" & $prepareCount & ")")
        else:
          wes.add(d & " (?)")

      # => ? IN (...)
      elif d.len() > 2 and d[0..1] == "IN":
        if usePrepared:
          prepareCount += 1
          wes.add("$" & $prepareCount & " " & d)
        else:
          wes.add("? " & d)

      # => ... = ?
      else:
        if usePrepared:
          prepareCount += 1
          wes.add(d & " $" & $prepareCount)
        else:
          wes.add(d & " ?")


  #
  # Where IN
  #
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

        inVal.add("'" & dbQuotePrivate(a) & "'")

    else:
      for a in whereInValueInt:
        if inVal != "":
          inVal.add(",")
        inVal.add($a)

    if inVal.len() == 0:
      if whereInValue.len() > 0:
        acc.add("0")
      elif whereInValueString.len() > 0:
        acc.add("''")
      elif whereInValueInt.len() > 0:
        acc.add("0")
    else:
      acc.add(inVal)

    acc.add(")")



  #
  # Soft delete
  #
  if useDeleteMarker and deleteMarkersFields.len() > 0:
    for t in tablesInQuery:
      if t.table notin deleteMarkersFields:
        continue

      let toUse = if t.tableAs != "": t.tableAs else: t.table

      if wes == "" and acc == "":
        wes.add(" WHERE " & toUse & $deleteMarker)

      elif acc != "":
        acc.add(" AND " & toUse & $deleteMarker)

      else:
        wes.add(" AND " & toUse & $deleteMarker)




  when defined(dev):

    let sqlString = res & " FROM " & tableName & lef & wes & acc & " " & customSQL

    let illegal = hasIllegalFormats(sqlString)
    if illegal.len() > 0:
      raise newException(
        Exception,
        "Bad SQL format. Please check your SQL statement. " &
        "This is most likely caused by a missing WHERE clause. " &
        "Bug: `" & illegal & "` in \n" & sqlString
      )


    # Check for missing table alias
    if (
      (tableAs != "" and table != tableAs) or
      (joinargs.len() > 0)
    ):
      var hit: bool
      for s in select:
        if "." notin s:
          echo "WARNING (SQL SELECT): Missing table alias in select statement: " & $s
          hit = true
      if hit:
        echo "WARNING (SQL SELECT): " & sqlString

  result = sql(res & " FROM " & tableName & lef & wes & acc & " " & customSQL)





#
# Legacy
#
proc sqlSelect*(
    table: string,
    data: varargs[string],
    left: varargs[string],
    whereC: varargs[string],
    access: string, accessC: string,
    user: string,
    args: ArgsContainer.query = @[],
    useDeleteMarker: bool = true,
    tablesWithDeleteMarker: varargs[string] = [],
    deleteMarker = ".is_deleted IS NULL",
  ): SqlQuery {.deprecated.} =
  ##
  ## Legacy converter
  ##


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
    useDeleteMarker = useDeleteMarker,
    tablesWithDeleteMarker = tablesWithDeleteMarker,
    deleteMarker = deleteMarker
  )



macro sqlSelectMacro*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string): SqlQuery {.deprecated.} =
  ## SQL builder for SELECT queries
  ## Does NOT check for NULL values
  ##
  ## Legacy converter
  ##

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

