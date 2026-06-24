# Mode: break a project into vertical slices

You are in this mode when the **project status is Backlog**. The job: turn the
project into a set of vertical-slice **parent issues**, ordered by blocking
relations. This is slice-level thinking — you are *not* breaking slices into
sub-issues here (that is the issues.md mode, one slice at a time, in its own
session).

This mode is **resumable**: slices may already be partly created from an earlier
run. Re-derive the full slice list and create only what's missing.

## Steps

### 1. Read everything yourself

Read the project description in full, and every artifact it points to — linked
docs, specs, designs, related issues. Do not delegate this; do not summarize it
through a subagent. The reading is the leverage. Read the relevant codebase
sections too, to ground the slices in real structure.

### 2. Derive the vertical slices

A vertical slice is one complete, testable path through the system — schema +
API + UI for a single capability — not a horizontal layer. (See SKILL.md for the
vertical-vs-horizontal contrast.) List every slice the project needs.

### 3. Diff against what exists

The status script already gave you the parent issues in the project. Match your
derived slices against them by title/intent:

- Slice has no parent issue → create it (step 4).
- Slice already has a parent issue → leave it; it was created in an earlier run.

This is how you resume a half-finished creation pass without duplicating.

### 4. Create the missing parent issues

For each missing slice, create a parent issue in the project with a description
that states what the slice delivers and its acceptance criteria at the slice
level (the detailed sub-issue criteria come later, in issues.md mode). Leave each
new parent at status **Backlog** — that signals "not yet decomposed."

Do not set `parentId` — these are top-level. Do not create sub-issues here.

### 5. Wire blocking relations between slices

Map the dependency order across slices and encode it: for each "slice X depends
on slice Y," set Y **blocks** X (or X **blockedBy** Y — pick one direction, stay
consistent). Both fields are append-only; correct mistakes with the remove
fields, not a re-save. No cycles.

### 6. Flip the project to Planning

Once every slice exists as a parent issue with its blockers wired, the creation
pass is done. **Ask the user to confirm** (AskUserQuestion), then move the
**project status → Planning**. That status is what routes the next session into
issues.md mode.

## Done when

- Every vertical slice exists as a top-level parent issue in the project.
- Slice-to-slice dependency order is encoded as blocking relations, no cycles.
- Each new parent is at status Backlog (awaiting decomposition).
- Project status is Planning (after user confirmation).
