## Linear Ticket Writing Guidelines

- **Stories** are Linear **Issues**. **Epics** are Linear **Projects**.
- Each ticket is either a **User Story** or a **System Story**.

### User Story Format

```
As a [role]
I want [capability]
So that [benefit]

**Acceptance Criteria:**
- [ ] ...
```

### System Story Format

```
[ACTION-VERB] [statement of what the system does]
So that [benefit or reason]

**Acceptance Criteria:**
- [ ] ...
```

### Bug Report Format

```
**Summary:** [One-line description of the bug]

**Steps to Reproduce:**
1.
2.
3.

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Environment:**
- Scene: [e.g. res://scenes/GameMain.tscn]
- Conditions: [e.g. "only when upgrade purchased", "after round 2"]

**Acceptance Criteria:**
- [ ] [Specific, testable condition that confirms the bug is fixed]
- [ ] No regression in related systems
```

### Guidelines

- Each clause on its own line. Acceptance criteria: short, testable checklist items.
- **User Story** for player/end-user needs. **System Story** for internal/infrastructure work.
- **Bug Report** for defects, using steps to reproduce and clear expected vs actual.
- **Issue titles ≤50 chars.** Push symptoms, qualifiers, file paths into the body.
- **Project names are Title Case, two words max per level.** "Security Hygiene", not "Security hygiene pass".

### Linear API Access

- API key: `$LINEAR_API_KEY`. Endpoint: `https://api.linear.app/graphql`.
- **All new tickets** → Status: **Vault** (`d41fb73e-32af-40b2-a7e5-5052900ab0fc`). Label: **Feature** (`b19a1a7b-af6b-4897-a52f-eb2e2e07083e`). Do NOT assign to a cycle. Do NOT use Triage; that is for external/incoming tickets only. Josh promotes tickets to Ready and adds them to cycles himself.
- **Never set an assignee.** Leave every ticket unassigned, in any state. Collaborators are joining the project; who picks up a ticket is theirs to decide, not something to impose by API.
