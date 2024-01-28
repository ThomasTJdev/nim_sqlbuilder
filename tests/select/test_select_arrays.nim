# Copyright Thomas T. Jarløv (TTJ)

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilder,
  src/sqlbuilderpkg/utils_private



suite "sqlSelect - array formatting":

  test "setting type int":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @["some_ids = ANY(?::INT[])"],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks WHERE some_ids = ANY(?::INT[])"))


  test "setting type int multiple times":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @[
        "some_ids = ANY(?::INT[])",
        "hash_ids = ANY(?::INT[])",
        "version =",
        "revisions = ANY(?::INT[])"
      ],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks WHERE some_ids = ANY(?::INT[]) AND hash_ids = ANY(?::INT[]) AND version = ? AND revisions = ANY(?::INT[])"))


  test "setting type int + text multiple times":

    let test = sqlSelect(
      table     = "tasks",
      select    = @["id", "name"],
      where     = @[
        "some_ids = ANY(?::TEXT[])",
        "hash_ids = ANY(?::INT[])",
        "version =",
        "revisions = ANY(?::TEXT[])"
      ],
    )
    check querycompare(test, sql("SELECT id, name FROM tasks WHERE some_ids = ANY(?::TEXT[]) AND hash_ids = ANY(?::INT[]) AND version = ? AND revisions = ANY(?::TEXT[])"))


