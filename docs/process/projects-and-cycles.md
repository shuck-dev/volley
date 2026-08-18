# Projects and cycles

The two Linear nouns that organise work in Volley, and how they relate.

## Project

A Linear project. Linear-shaped: name, summary, description, status, milestones, issues. Holds the regular work tickets (features, bugs, spikes, studies).

Projects are **linear in scope**: the work inside a project completes inside the project. If a ticket in this project depends on a ticket in another project to finish, the project boundary is wrong.

When the boundary is leaking, resolve by:

- Moving the dependency ticket into this project (it belongs here).
- Moving this project's ticket into the depending project (it belongs there).
- Merging the two projects (their scopes overlap enough that the boundary is artificial).

Don't carry a cross-project dependency as a known thing. Treat it as a structural smell.

Shared infrastructure (utilities, the engine, generic helpers) is fine across projects. Cross-project tickets unblocking each other is the smell.

## Cycle

A Linear cycle. Time-bounded (Tuesday to Monday). Holds whatever work is targeted to land in that span.

A cycle is goal-oriented: its description names what the cycle wants to complete. Cycle status updates report against that goal.

## How they relate

- A **cycle** holds tickets from multiple projects.
- Each **project** holds the tickets about one thing; its scope completes inside the project.
- Findings from a ticket file as new tickets in the same project. A finding that escalates to a different project's scope signals a missed boundary.
