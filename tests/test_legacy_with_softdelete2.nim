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

# import
#   src/sqlbuilder

const tablesWithDeleteMarkerInit* = ["tasks", "history", "tasksitems", "persons", "actions", "project"]
include
  src/sqlbuilder_include


proc querycompare(a, b: SqlQuery): bool =
  var
    a1: seq[string]
    b1: seq[string]
  for c in splitWhitespace(string(a)):
    a1.add($c)
  for c in splitWhitespace(string(b)):
    b1.add($c)

  if a1 != b1:
    echo ""
    echo "a1: ", string(a)
    echo "b1: ", string(b).replace("\n", " ").splitWhitespace().join(" ")
    echo ""

  return a1 == b1



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




#[
  test "set left join without AS":

    let test = sqlSelect("tasks",
      [
                "DISTINCT actions.virtual_id",       #0
                "actions.color",
                "status_project.name",
                "swimlanes_project.name",
                "actions.name",
                "phases_project.name",
                "categories_project.name",
                "actions.tags",
                "actions.date_start",
                "actions.date_end",
                "actions.disp1",            #10
                "actions.status",
                "actions.modified",
                "actions.description",
                "actions.assigned_to",
                "actions.dependenciesb",
                "status_project.closed",
                "(SELECT coalesce(string_agg(history.user_id::text, ','), '') FROM history WHERE history.item_id = actions.virtual_id AND history.project_id = actions.project_id AND (history.choice = 'Comment' OR history.choice = 'Picture' OR history.choice = 'File') AND history.is_deleted IS NULL) AS history",
                "(SELECT COUNT(files_tasks.id) FROM files_tasks WHERE files_tasks.project_id = actions.project_id AND files_tasks.task_id = actions.virtual_id AND (files_tasks.filetype IS NULL OR files_tasks.filetype != 1)) AS files",
                "actions.floorplanJson",
                "actions.canBeClosed",      #20
                "personModified.uuid",
                "actions.qa_type",
                "personAssigned.uuid",
                "personModified.name",
                "cA.name",
                "cA.logo",
                "actions.assigned_to_company",
                "actions.cx_review_document",
                "actions.cx_review_page",
                "actions.cx_bod",             #30
                "actions.project_id",         #31
                "actions.rand",               #32
                "personAuthor.uuid",          #33
                "personAuthor.name",               #34
                "personAssigned.hasPicture",         #35
                "personModified.hasPicture",         #36
                "qap.virtual_id",             #37
                "qap.name",                   #38
                "actions.cost",                #39
                "personAuthor.hasPicture",     #40
                "actions.creation",             #41
                "floorplan.filename",           #42
                "personAuthor.company",        #43
                "(SELECT files_tasks.filename_hash FROM files_tasks WHERE files_tasks.project_id = actions.project_id AND files_tasks.task_id = actions.virtual_id AND (files_tasks.filetype IS NULL OR files_tasks.filetype != 1)  ORDER BY files_tasks.id DESC LIMIT 1) AS filesPhoto",
                "(SELECT files_tasks.filename_hash FROM files_tasks WHERE files_tasks.project_id = actions.project_id AND files_tasks.task_id = actions.virtual_id AND files_tasks.filetype = 1 ORDER BY files_tasks.id DESC LIMIT 1) AS filesFloorplan",
                "(SELECT SUBSTRING(history.text, 0, 100)  FROM history WHERE history.project_id = actions.project_id AND history.item_id  = actions.virtual_id AND history.choice = 'Comment' AND history.is_deleted IS NULL ORDER BY history.id DESC LIMIT 1) AS lastComment",
                "actions.location",            #47
                "actions.customfields",        #48
                "actions.testvalue",           #49
                "actions.added_closed",        #50
                #"personAuthor.uuid",          #
      ],
      [
        "categories_project ON actions.category = categories_project.id",
        "person as personAuthor ON actions.author_id = personAuthor.id",
        "person as personModified ON actions.modifiedBy = personModified.id",
        "person as personAssigned ON actions.assigned_to_userid = personAssigned.id",
        "status_project ON actions.status = status_project.status AND actions.project_id = status_project.project_id AND actions.swimlane = status_project.swimlane_id",
        "swimlanes_project on actions.swimlane = swimlanes_project.id",
        "phases_project ON actions.phase = phases_project.id",
        "project ON actions.project_id = project.id",
        "company AS cA ON cA.id = actions.assigned_to_companyid",
        "qa_paradigm AS qap ON qap.project_id = actions.project_id AND qap.id = actions.qa_id",
        "files AS floorplan ON floorplan.project_id = actions.project_id AND floorplan.filename_hash = actions.floorplanhash" # This forces us to use DISTINCT on actions.id
      ], ["actions.project_id ="], "", "", "ORDER BY status_project.closed ASC, actions.modified DESC  LIMIT 500 OFFSET 0")

    check querycompare(test, sql("""
        SELECT
          t.id,
          t.name,
          project.id
        FROM
          tasks
        LEFT JOIN persons ON
          (persons.id = t.persons_id)
        WHERE
              t.id = ?
          AND project.id in (2,4,6,7)
          AND tasks.is_deleted IS NULL
          AND persons.is_deleted IS NULL
        ORDER BY
          t.name
      """))


]#