# Package

version       = "1.0.0"
author        = "ThomasTJdev"
description   = "SQL builder"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.20.2"
when NimMajor >= 2:
  requires "db_connector >= 0.1.0"
