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





suite "IS TRUE and IS FALSE":

  test "Simple IS TRUE":

    let test = sqlSelect(
      table   = "person",
      tableAs = "p",
      select  = [
        "p.name",
      ],
      where = [
        "p.is_active IS TRUE"
      ]
    )

    check querycompare(test, sql("SELECT p.name FROM person AS p WHERE p.is_active IS TRUE"))


  test "Simple IS NOT TRUE":

      let test = sqlSelect(
        table   = "person",
        tableAs = "p",
        select  = [
          "p.name",
        ],
        where = [
          "p.is_active IS NOT TRUE"
        ]
      )

      check querycompare(test, sql("SELECT p.name FROM person AS p WHERE p.is_active IS NOT TRUE"))


  test "Simple IS FALSE":

    let test = sqlSelect(
      table   = "person",
      tableAs = "p",
      select  = [
        "p.name",
      ],
      where = [
        "p.is_active IS FALSE"
      ]
    )

    check querycompare(test, sql("SELECT p.name FROM person AS p WHERE p.is_active IS FALSE"))


  test "Simple IS NOT FALSE":

      let test = sqlSelect(
        table   = "person",
        tableAs = "p",
        select  = [
          "p.name",
        ],
        where = [
          "p.is_active IS NOT FALSE"
        ]
      )

      check querycompare(test, sql("SELECT p.name FROM person AS p WHERE p.is_active IS NOT FALSE"))


  test "Mixed IS TRUE and IS FALSE":

      let test = sqlSelect(
        table   = "person",
        tableAs = "p",
        select  = [
          "p.name",
        ],
        where = [
          "p.is_active IS TRUE",
          "p.is_active IS FALSE"
        ]
      )

      check querycompare(test, sql("SELECT p.name FROM person AS p WHERE p.is_active IS TRUE AND p.is_active IS FALSE"))