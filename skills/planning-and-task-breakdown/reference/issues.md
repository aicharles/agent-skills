# Mode: decompose one slice into sub-issues

You are in this mode when decomposing a single **parent issue** (a vertical
slice) into implementable sub-issues. One parent per session — decompose it,
then stop. The user drives the next session for the next parent.

You reach this mode three ways:

- **Project status is Planning** → pick the next parent to decompose (step 1).
- **A parent issue is at status Refining** → its scope changed; reconcile (step 5).
- **The user handed you an issue directly** (link/identifier) → re-evaluate and
  decompose it further, *regardless of its status* (step 1, treating that issue
  as the target).

## Steps

### 1. Pick the target parent

If the user named an issue, that's the target. Otherwise, from the status
script's parent list, pick the **next undecomposed parent**: the lowest in
blocking order (all its blockers already decomposed) whose status is **Backlog**
or **Refining**. If none remain, decomposition for the project is complete — tell
the user and move the **project status → In Progress** (after AskUserQuestion
confirmation). Stop.

### 2. Read everything yourself

Read the target parent issue in full, and every artifact it references — and the
project description for context. Read the relevant codebase sections so the
sub-issues match real structure. Do not delegate or summarize this. Full info,
first-hand.

### 3. Decompose into sub-issues

Break the slice into S/M-sized implementable units (see SKILL.md sizing). For
each, create an issue with `parentId` set to the target parent (one level deep —
no sub-issues of sub-issues), in the same project, with a description in the
shape:

```markdown
**Description:** One paragraph: what this sub-issue accomplishes.

**Acceptance criteria:**
- [ ] testable condition
- [ ] testable condition

**Verification:**
- [ ] Tests pass: ...
- [ ] Build succeeds: ...
- [ ] Manual check: ...

**Files likely touched:**
- `src/...`
```

### 4. Wire blocking relations between the sub-issues

Encode the within-slice dependency order as blockers (append-only; no cycles).
The parent/sub-issue link is grouping, not order — set blockers on the
sub-issues that actually depend on each other.

### 5. Reconcile mode (parent was at Refining)

A parent at **Refining** was already decomposed once, but the slice changed.
Don't start clean — read the issue's **evolution** (description history and
comments) to see what changed, then reconcile the existing sub-issues against it:
add new ones, update or close ones the change invalidated, re-wire blockers.
Preserve sub-issues still in flight.

### 6. Flip the parent to Todo

When the slice is fully decomposed (or reconciled), **ask the user to confirm**
(AskUserQuestion), then move the **parent status → Todo** — "decomposed, ready to
build." A builder/brainstormer/verifier picks it up from there; this skill does
not build.

Then stop. One parent per session.

## Done when

- The target slice is broken into S/M sub-issues, each attached to the parent
  (one level deep), each with acceptance + verification criteria.
- Within-slice dependency order is encoded as blockers, no cycles.
- Parent status is Todo (after user confirmation).
