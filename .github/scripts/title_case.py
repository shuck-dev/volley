#!/usr/bin/env python3
# Title Case a hyphen-separated name with a small-word filter.
# "title-is-this" -> "Title-is-This"; "01-prototype" -> "01-Prototype".
# First and last segments always capped (when the leading char is a lowercase
# letter); middle small words stay lowercase.
import sys

SMALL = {"a","an","the","and","or","but","of","in","on","to","by","at","for",
         "with","is","as","if","vs","from","into"}

parts = sys.argv[1].split("-")
out = []
for i, p in enumerate(parts):
    if not p:
        out.append(p)
        continue
    if i in (0, len(parts) - 1) or p.lower() not in SMALL:
        if p[0].isalpha() and p[0].islower():
            out.append(p[0].upper() + p[1:])
        else:
            out.append(p)
    else:
        out.append(p.lower())
print("-".join(out))
