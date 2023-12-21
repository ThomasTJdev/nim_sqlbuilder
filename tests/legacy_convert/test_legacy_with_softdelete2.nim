# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import
    db_connector/db_common
else:
  import
    std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilderpkg/utils_private


const tablesWithDeleteMarkerInit* = ["tasks", "history", "tasksitems", "persons", "actions", "project"]
include
  src/sqlbuilder_include




#
# Differs by using more fields in `tablesWithDeleteMarkerInit`
#
suite "legacy - sqlSelect(converter) - with new functionality to avoid regression - #2":


  test "existing delete in left join (double) - delete marker from left join":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["invoice AS p ON p.id = t.invoice_id", "persons ON persons.id = tasks.person_id AND persons.is_deleted IS NULL"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN invoice AS p ON
          (p.id = t.invoice_id)
        LEFT JOIN persons ON
          (persons.id = tasks.person_id AND persons.is_deleted IS NULL)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
          AND persons.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "add delete marker in left join - delete marker from left join":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["invoice AS p ON p.id = t.invoice_id", "persons ON persons.id = tasks.person_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN invoice AS p ON
          (p.id = t.invoice_id)
        LEFT JOIN persons ON
          (persons.id = tasks.person_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
          AND persons.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "set left join without AS":

    let test = sqlSelect("tasks", ["t.id", "t.name", "invoice.id"], ["persons ON persons.id = t.persons_id"], ["t.id ="], "2,4,6,7", "invoice.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          invoice.id
        FROM
          tasks
        LEFT JOIN persons ON
          (persons.id = t.persons_id)
        WHERE
              t.id = ?
          AND invoice.id in (2,4,6,7)
          AND tasks.is_deleted IS NULL
          AND persons.is_deleted IS NULL
        ORDER BY
          t.name
      """))


