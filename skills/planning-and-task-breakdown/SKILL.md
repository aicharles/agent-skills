---
name: planning-and-task-breakdown
description: Breaks a Linear project into ordered Linear issues and sub-issues with blocking relations. Use when you have a Linear project describing work and need to decompose it into implementable, dependency-ordered issues. Use when a piece of work feels too large to start, when you need to map scope into Linear, or when parallel work is possible.
---

# Planning and Task Breakdown

## Overview

Decompose a Linear project into small, verifiable issues with explicit acceptance criteria, organized as parent issues and sub-issues, wired together with blocking relations that encode the dependency order. Good task breakdown is the difference between an agent that completes work reliably and one that produces a tangled mess. Every issue should be small enough to implement, test, and verify in a single focused session.

The **input** is a Linear project (its description, milestones, and any existing issues). The **output** is a set of Linear issues — not a markdown document. You read the project from Linear and write the breakdown back into Linear.

## When to Use

- You have a Linear project and need to break it into implementable issues
- A piece of work feels too large or vague to start
- Work needs to be parallelized across multiple agents or sessions
- The implementation order isn't obvious and you want it encoded as blockers

**When NOT to use:** Single-issue changes with obvious scope, or when the project already contains well-defined, correctly-ordered issues.

## Tools

This skill writes to Linear via the Linear MCP. The ones you need:

- `mcp__plugin_linear_linear__list_projects` / `get_project` — find and read the source project (pass `includeMilestones: true`, `includeResources: true`).
- `mcp__plugin_linear_linear__list_issues` — read issues already in the project so you don't duplicate them (`project: <id>`).
- `mcp__plugin_linear_linear__get_issue` — read one issue in full, with `includeRelations: true` to see existing blockers.
- `mcp__plugin_linear_linear__save_issue` — create each issue. Key fields:
  - `team` (required on create) and `project` — put every issue in the source project.
  - `parentId` — set this to make an issue a **sub-issue** of a parent.
  - `blockedBy` / `blocks` — wire dependency order. **Both are append-only** (existing relations are never removed), so add them in a second pass once issue identifiers exist; use `removeBlockedBy` / `removeBlocks` to correct mistakes.
  - `description` — Markdown, with literal newlines (do not escape). This is where acceptance criteria and verification go.
  - `estimate`, `priority`, `labels`, `milestone` — optional, set when the project uses them.

## The Planning Process

### Step 1: Read the project (read-only)

Before creating anything, operate in read-only mode:

- Read the project description, milestones, and resources with `get_project`.
- List existing issues in the project with `list_issues` — you are augmenting, not duplicating.
- Read relevant codebase sections; identify existing patterns and conventions.
- Map dependencies between components.
- Note risks and unknowns.

**Do NOT create issues during this step.** You are mapping the work first.

### Step 2: Identify the Dependency Graph

Map what depends on what. This graph becomes your blocking relations:

```
Database schema
    │
    ├── API models/types
    │       │
    │       ├── API endpoints
    │       │       │
    │       │       └── Frontend API client
    │       │               │
    │       │               └── UI components
    │       │
    │       └── Validation logic
    │
    └── Seed data / migrations
```

Implementation order follows the graph bottom-up: foundations first. Each edge "X depends on Y" becomes "Y **blocks** X" in Linear.

### Step 3: Slice Vertically

Instead of building all the database, then all the API, then all the UI — build one complete feature path at a time:

**Bad (horizontal slicing):**
```
Issue 1: Build entire database schema
Issue 2: Build all API endpoints
Issue 3: Build all UI components
Issue 4: Connect everything
```

**Good (vertical slicing):**
```
Issue 1: User can create an account (schema + API + UI for registration)
Issue 2: User can log in (auth schema + API + UI for login)
Issue 3: User can create a task (task schema + API + UI for creation)
Issue 4: User can view task list (query + API + UI for list view)
```

Each vertical slice delivers working, testable functionality.

### Step 4: Choose the parent / sub-issue structure

Decide what is a parent issue and what is a sub-issue before you write anything:

- **Parent issue** — a feature slice or milestone-sized chunk (an epic). It groups work; it is usually not implemented directly.
- **Sub-issue** — a single implementable unit under a parent (S or M sized, see sizing below). This is what an agent actually picks up.

A good default: one parent per vertical slice (Step 3), with each slice's schema/API/UI steps as sub-issues. Don't nest deeper than one level — sub-issues of sub-issues get unwieldy. If a project is small, skip parents and create flat issues.

### Step 5: Write the issues (first pass — create)

Create each issue with `save_issue`, in dependency order (foundations first) so identifiers exist before you wire blockers. For every issue set `team`, `project`, `title`, and a `description` in this shape:

```markdown
**Description:** One paragraph explaining what this issue accomplishes.

**Acceptance criteria:**
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

**Verification:**
- [ ] Tests pass: `npm test -- --grep "feature-name"`
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: [description of what to verify]

**Files likely touched:**
- `src/path/to/file.ts`
- `tests/path/to/test.ts`

**Estimated scope:** [Small: 1-2 files | Medium: 3-5 files | Large: 5+ files]
```

Set `parentId` on each sub-issue to attach it to its parent (create the parent first so you have its identifier). Set `estimate` / `priority` / `milestone` / `labels` when the project uses them.

Record each created issue's identifier (e.g. `ENG-123`) as you go — you need them for the next step. Dependencies are **not** set yet.

### Step 6: Wire blocking relations (second pass)

Now that every issue has an identifier, walk the dependency graph from Step 2 and add the blockers. For each "Y blocks X" edge, call `save_issue` on the blocking issue:

```
save_issue(id: "ENG-100", blocks: ["ENG-105"])
```

or equivalently set `blockedBy` on the blocked issue. Pick one direction and be consistent. Remember both fields are **append-only** — to fix a wrong link use `removeBlocks` / `removeBlockedBy`, not a re-save.

A parent/sub-issue relationship is **not** a blocking relationship — set blockers on the sub-issues that actually depend on each other, not on the parents.

### Step 7: Order, checkpoint, and review

- Confirm every issue's blockers are satisfiable (no cycles, foundations unblocked).
- Front-load high-risk issues so failures surface early.
- Add explicit checkpoint issues (or milestones) after every 2-3 implementation issues, blocked by the issues they check:

```markdown
**Checkpoint: Foundation**
- [ ] All tests pass
- [ ] Application builds without errors
- [ ] Core user flow works end-to-end
- [ ] Review with human before proceeding
```

- Have the human review the resulting issue tree in Linear before implementation begins.

## Task Sizing Guidelines

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **XS** | 1 | Single function or config change | Add a validation rule |
| **S** | 1-2 | One component or endpoint | Add a new API endpoint |
| **M** | 3-5 | One feature slice | User registration flow |
| **L** | 5-8 | Multi-component feature | Search with filtering and pagination |
| **XL** | 8+ | **Too large — break it down further** | — |

An agent performs best on S and M sub-issues. If a unit is L or larger, split it into more sub-issues under the same parent.

**When to break an issue down further:**
- It would take more than one focused session (roughly 2+ hours of agent work)
- You cannot describe the acceptance criteria in 3 or fewer bullet points
- It touches two or more independent subsystems (e.g., auth and billing)
- You find yourself writing "and" in the title (a sign it is two issues)

## Parallelization Opportunities

When multiple agents or sessions are available:

- **Safe to parallelize:** Issues with no blocking relation between them — independent feature slices, tests for already-implemented features, documentation. The blocker graph makes this explicit: any two issues neither of which (transitively) blocks the other can run at once.
- **Must be sequential:** Database migrations, shared state changes, dependency chains — encoded as blockers.
- **Needs coordination:** Issues that share an API contract — make the contract-defining issue block all of them, then they parallelize.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you end up with a tangled mess and rework. 10 minutes of planning saves hours. |
| "The issues are obvious" | Write them down anyway. Explicit issues surface hidden dependencies and forgotten edge cases. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |
| "I'll set the blockers later" | Later never comes, and the build loop can't order work without them. Wire them in the second pass, now. |
| "Parent issues are enough structure" | Parent/sub-issue is grouping, not ordering. Dependency order lives in blocking relations. |

## Red Flags

- Creating issues before reading the existing project issues (duplicates)
- Issues that say "implement the feature" without acceptance criteria
- No verification steps in issue descriptions
- All issues are XL-sized
- No checkpoints between phases
- Parent/sub-issue nesting deeper than one level
- Dependency order left unencoded — no blocking relations set
- Blocking relations that form a cycle

## Verification

Before handing the issue tree off for implementation, confirm:

- [ ] Every issue lives in the correct Linear project
- [ ] Every issue has acceptance criteria in its description
- [ ] Every issue has a verification step
- [ ] Sub-issues are attached to the right parent (one level deep)
- [ ] Dependency order is encoded as blocking relations, with no cycles
- [ ] No issue touches more than ~5 files
- [ ] Checkpoint issues or milestones exist between major phases
- [ ] The human has reviewed and approved the issue tree in Linear
