---
name: planning-and-task-breakdown
description: Breaks a Linear project into ordered parent issues (vertical slices), then breaks one slice at a time into sub-issues with blocking relations. Use when you have a Linear project describing work and need to decompose it into implementable, dependency-ordered Linear issues. Use when a slice feels too large to start, or when parallel work is possible.
---

# Planning and Task Breakdown

## Overview

Decompose a Linear **project** into small, verifiable Linear **issues**:
first into vertical-slice parent issues, then each slice into sub-issues —
wired together with blocking relations that encode dependency order. The input
is a Linear project; the output is Linear issues, not a markdown document.

The work splits into two modes, run in **separate sessions** so neither blows
its context budget. This skill routes to the right mode by reading status, then
loads only that mode's instructions:

- **Break the project into vertical slices** → reference/project.md
- **Decompose one slice into sub-issues** → reference/issues.md

The status script tells you which mode you're in without pulling issue bodies
into context. One run does one unit of work — create the slices, or decompose
one slice — then stops. The user drives the next session.

## When to Use

- You have a Linear project and need to break it into implementable issues.
- A slice feels too large or vague to start.
- Work needs to be parallelized; dependency order should be explicit.

**When NOT to use:** a single issue with obvious scope, or a project already
fully decomposed and correctly ordered.

## Principles that hold across both modes

These are the rules both reference files assume — read them as the spine.

- **You read everything yourself.** The project description, every artifact it
  links to, the relevant code. Do not delegate reading to a subagent and do not
  work from a summary. The reading is the highest-leverage part of this; full,
  first-hand information is the point. (This is why one run does one unit — so
  the context holds real detail, not a thin survey of the whole tree.)
- **Vertical slices, not horizontal layers.** A slice is one complete, testable
  path — schema + API + UI for a single capability — not "all the schema" then
  "all the API." Each slice delivers working functionality on its own.
- **Dependency order lives in blocking relations.** Parent/sub-issue is grouping;
  ordering is blockers. `blockedBy`/`blocks` are append-only — correct mistakes
  with the remove fields, never a re-save. No cycles, ever.
- **One level of nesting.** Project → parent (slice) → sub-issue. No deeper.
- **The skill owns status transitions, and confirms them.** Before moving a
  project or parent to a new status, ask the user with AskUserQuestion. The
  statuses are what route the next session, so they must be deliberate.
- **You plan; you do not build.** Decomposition ends at status Todo. A
  builder / brainstormer / verifier takes it from there.

## Routing

Run the status script to get project + parent statuses as compact JSON, without
reading issue bodies into context. It uses the Linear API directly (needs
`LINEAR_API_KEY` in the environment):

```bash
bash scripts/status.sh project <project-id-or-slug>   # project + its parent issues
bash scripts/status.sh issue   <issue-identifier>     # one issue + its blockers
```

Then route:

**If the user handed you an issue directly** (a link or identifier), ignore
project status: re-evaluate that issue and decompose it further regardless of its
status. Read **reference/issues.md** and treat that issue as the target.

**Otherwise, branch on project status:**

| Project status | Mode | Read |
|---|---|---|
| **Backlog** | Create vertical slices as parent issues (resuming any partly-created set); flip project → Planning | reference/project.md |
| **Planning** | Decompose the next slice (or finish a half-done one); when none remain, flip project → In Progress | reference/issues.md |
| **anything else** | Decomposition assumed complete — stop | — |

**Within Planning, branch on the target parent's status:**

| Parent status | Meaning | Action |
|---|---|---|
| **Backlog** | Not decomposed | Decompose into sub-issues (reference/issues.md) |
| **Refining** | Already decomposed, but the slice changed | Reconcile against the issue's evolution (reference/issues.md) |
| **Todo / In Progress / Done / other** | Already handled | Skip — pick the next parent |

Load **only** the reference file for the mode you routed into. Don't read both.

## Task Sizing Guidelines

Applies when breaking a slice into sub-issues (reference/issues.md).

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **XS** | 1 | Single function or config change | Add a validation rule |
| **S** | 1-2 | One component or endpoint | Add a new API endpoint |
| **M** | 3-5 | One feature slice | User registration flow |
| **L** | 5-8 | Multi-component feature | Search with filtering + pagination |
| **XL** | 8+ | **Too large — break it down further** | — |

An agent performs best on S and M sub-issues. If a unit is L or larger, split it.

**Break a sub-issue down further when:**
- It would take more than one focused session (~2+ hours of agent work).
- You can't state acceptance criteria in 3 or fewer bullets.
- It touches two or more independent subsystems.
- The title wants an "and" (a sign it's two issues).

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you get a tangled mess and rework. Planning is the task. |
| "I'll let a subagent read it and summarize" | Reading is the leverage. Summaries drop the detail the breakdown depends on. |
| "The slices are obvious" | Write them down anyway — explicit slices surface hidden dependencies. |
| "I'll set the blockers later" | Later never comes, and the build loop can't order work without them. |
| "Parent/sub-issue is enough structure" | That's grouping, not ordering. Order lives in blocking relations. |
| "I'll do all the slices in one session" | Context can't hold the whole tree at fidelity. One unit per run. |

## Red Flags

- Reading the project through a subagent summary instead of first-hand.
- Decomposing more than one slice in a single session.
- Horizontal slices ("all the schema") instead of vertical ones.
- Dependency order left unencoded — no blocking relations.
- Blocking relations that form a cycle.
- Nesting deeper than parent → sub-issue.
- Flipping a project or parent status without asking the user first.

## Verification

Before a run hands off, confirm (the active reference file has the mode-specific
list):

- [ ] Everything was read first-hand, not summarized.
- [ ] Issues live in the correct Linear project.
- [ ] Dependency order is encoded as blocking relations, no cycles.
- [ ] Nesting is one level deep.
- [ ] The relevant status transition was confirmed with the user.
