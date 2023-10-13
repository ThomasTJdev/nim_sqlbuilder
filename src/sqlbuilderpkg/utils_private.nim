# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk



proc dbQuotePrivate*(s: string): string =
  ## DB quotes the string.
  result = "'"
  for c in items(s):
    case c
    of '\'': add(result, "''")
    of '\0': add(result, "\\0")
    else: add(result, c)
  add(result, '\'')