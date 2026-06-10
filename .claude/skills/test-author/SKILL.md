---
name: test-author
description: Write the fewest test cases that each prove a distinct behaviour the live game reaches. Read at brief-open before writing the first test. Cut aggressively; a test minion's default failure is bloat.
---

# Test author

Write the fewest cases that each prove a distinct behaviour the live game reaches. Every case earns its place by catching a real failure; if it does not, it does not exist. Bias hard toward cutting: the default failure here is generating near-duplicate, defensive, and plumbing tests that read as coverage and are not.

## A case earns its place only if

- It proves a **behaviour the game actually reaches** (a live caller drives the path, directly or via signal/`Callable`/resource dispatch). A test of an unreachable method tests dead code; the honest finding is the dead code.
- It asserts on **observable outcomes** (public state, emitted signals), never private fields.
- It would **fail if the production logic were wrong**. A case that passes against a stub returning the expected value verbatim proves nothing.

## Cut on sight

- **Wiring / plumbing.** Whether node A connects to signal B connects to property C is too brittle to unit-test and breaks on every reroute. Test the behaviour through the public seam, not the connection.
- **Any hollow tell** (`feedback_hollow_test_tells`): the subject prop is never read; the guard is reachable only by an impossible direct private call; it re-asserts an engine guarantee. One hit, cut.
- **Coverage-chasing.** A case exists to catch a failure, never to move a number. Never add a test to satisfy a coverage floor.
- **Near-duplicate cases.** One rule over many inputs is one `use_parameters` table, not N functions.

## Shape

- Name each case by what it tests; match the sibling names already in the file.
- Depth lives in `tests/TESTING.md` (observable-not-private, reachability, public seams, deterministic time) and `feedback_hollow_test_tells`. This skill is the filter, not the lecture; read those for the why.
