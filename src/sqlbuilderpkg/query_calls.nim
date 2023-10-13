# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

##
## These are procs to catch DB errors and return a default value to move on.
## This should only be used if:
##  - It is not critical data
##  - You can live with a default value in case of an error
##  - You have no other way to catch the error
##  - You are to lazy to write the try-except procs yourself
##

import
  std/logging,
  std/typetraits

when NimMajor >= 2:
  import
    db_connector/db_common
else:
  import
    std/db_postgres



proc getValueTry*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): string =
  try:
    result = getValue(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




proc getAllRowsTry*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): seq[Row] =
  try:
    result = getAllRows(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




proc getRowTry*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): Row =
  try:
    result = getRow(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




iterator fastRowsTry*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): Row =
  try:
    for i in fastRows(db, query, args):
      yield i
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




proc tryExecTry*(db: DbConn, query: SqlQuery; args: varargs[string, `$`]): bool =
  try:
    result = tryExec(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




proc execTry*(db: DbConn, query: SqlQuery; args: varargs[string, `$`]) =
  try:
    exec(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())




proc execAffectedRowsTry*(db: DbConn, query: SqlQuery; args: varargs[string, `$`]): int64 =
  try:
    result = execAffectedRows(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())
    return -1



proc tryInsertIDTry*(db: DbConn, query: SqlQuery; args: varargs[string, `$`]): int64 =
  try:
    result = tryInsertID(db, query, args)
  except:
    error(distinctBase(query).subStr(0, 200) & "\n" & getCurrentExceptionMsg())
    return -1