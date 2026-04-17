default: check

format:
    find scripts tests -name '*.gd' -not -path 'addons/*' | xargs gdformat

lint:
    find scripts tests -name '*.gd' -not -path 'addons/*' | xargs gdlint

test:
    godot --headless -s addons/gut/gut_cmdln.gd

check: format lint test

hooks-install:
    lefthook install
