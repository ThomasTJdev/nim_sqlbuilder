# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

when NimMajor >= 2:
  import db_connector/db_common
else:
  import std/db_common

import
  std/strutils,
  std/unittest

import
  src/sqlbuilderpkg/utils_private


const tablesWithDeleteMarkerInit* = ["tasks", "history", "tasksitems"]
include
  src/sqlbuilder_include


#
# Differs by using less fields in `tablesWithDeleteMarkerInit`
#
suite "legacy - sqlSelect(converter) - with new functionality to avoid regression":


  test "set tablesWithDeleteMarker":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "existing is_deleted in where":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "AND tasks.is_deleted IS NULL ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL AND tasks.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "existing delete in where with alias":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id"], ["t.id ="], "2,4,6,7", "p.id", "AND t.is_deleted IS NULL ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "existing delete in left join (double)":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id", "persons ON persons.id = tasks.person_id AND persons.is_deleted IS NULL"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        LEFT JOIN persons ON
          (persons.id = tasks.person_id AND persons.is_deleted IS NULL)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "add delete marker in left join":

    let test = sqlSelect("tasks AS t", ["t.id", "t.name", "p.id"], ["project AS p ON p.id = t.project_id", "persons ON persons.id = tasks.person_id"], ["t.id ="], "2,4,6,7", "p.id", "ORDER BY t.name")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          p.id
        FROM
          tasks AS t
        LEFT JOIN project AS p ON
          (p.id = t.project_id)
        LEFT JOIN persons ON
          (persons.id = tasks.person_id)
        WHERE
              t.id = ?
          AND p.id in (2,4,6,7)
          AND t.is_deleted IS NULL
        ORDER BY
          t.name
      """))


  test "complex query":

    var test: SqlQuery

    test = sqlSelect("tasksitems AS tasks",
        [
          "tasks.id",
          "tasks.name",
          "tasks.status",
          "tasks.created",
          "his.id",
          "his.name",
          "his.status",
          "his.created",
          "projects.id",
          "projects.name",
          "person.id",
          "person.name",
          "person.email"
        ],
        [
          "history AS his ON his.id = tasks.hid AND his.status = 1",
          "projects ON projects.id = tasks.project_id AND projects.status = 1",
          "person ON person.id = tasks.person_id"
        ],
        [
          "projects.id =",
          "tasks.status >"
        ],
        "1,2,3",
        "tasks.id",
        "ORDER BY tasks.created DESC"
      )

    check querycompare(test, (sql("""
        SELECT
          tasks.id,
          tasks.name,
          tasks.status,
          tasks.created,
          his.id,
          his.name,
          his.status,
          his.created,
          projects.id,
          projects.name,
          person.id,
          person.name,
          person.email
        FROM
          tasksitems AS tasks
        LEFT JOIN history AS his ON
          (his.id = tasks.hid AND his.status = 1)
        LEFT JOIN projects ON
          (projects.id = tasks.project_id AND projects.status = 1)
        LEFT JOIN person ON
          (person.id = tasks.person_id)
        WHERE
              projects.id = ?
          AND tasks.status > ?
          AND tasks.id in (1,2,3)
          AND tasks.is_deleted IS NULL
          AND his.is_deleted IS NULL
        ORDER BY
          tasks.created DESC
      """)))
