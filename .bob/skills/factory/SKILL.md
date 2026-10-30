---
name: factory
description: Run the software factory loop — spec, build, parallel review, approve/merge.
metadata:
  user-invocable: true
  disable-model-invocation: true
---

# Software Factory

You are the **orchestrator**. You alone write `factory/board.json`. Agents get context from files, not chat, and each writes only its own file.

## Commands

| Command | Action |
|---------|--------|
| `/factory <feature>` | New job through the loop |
| `/factory next` | First unchecked item in `factory/backlog.md` |
| `/factory approve <job-id>` | Merge a `needs-human` job into main |
| `/factory rework <job-id> <note>` | Send job back to builder with feedback |

## Repo context

Before any job, read `factory/REPO.md` (language, test command, conventions). Point every agent at it.

## Loop

```
feature → spec-writer → builder → [security | ux | ui-design | code] in parallel
       → WAIT FOR ALL 4 reviews
       → any CHANGES? resume builder (max 2 rounds) → re-review
       → all PASS → approver → APPROVE (merge) | ESCALATE (needs-human)
```

Edit this skill to change the factory.

## Board

`factory/board.json` shape:

```json
{
  "jobs": [{
    "id": "003-rate-limiting",
    "title": "Add rate limiting",
    "branch": "factory/003-rate-limiting",
    "stage": "review",
    "round": 2,
    "builder": "builder-003-rate-limiting",
    "reviews": {
      "security": "CHANGES",
      "ux": "PASS",
      "ui": "pending",
      "code": "PASS"
    }
  }]
}
```

Stages: `spec` → `build` → `review` → `approve` → `merged` | `needs-human`.
Review values: `pending` | `PASS` | `CHANGES`.

Update the board after every stage change and after each review file appears.

## Job layout

```
factory/jobs/<id>/
  spec.md
  build.md
  round-<n>/
    review-security.md
    review-ux.md
    review-ui.md
    review-code.md
  decision.md
```

## New job (`/factory <feature>` or `next`)

1. Allocate next numeric id (`001`, `002`, …) from existing `factory/jobs/` + board. Slug from feature → `<id>-<slug>`.
2. Create `factory/jobs/<id>/`. Branch name `factory/<id>`.
3. Append job to board: `stage: spec`, `round: 1`, all reviews `pending`, `builder: builder-<id>`.
4. If from backlog, check off the item in `factory/backlog.md`.
5. Run the loop below.

## The loop (orchestrator steps)

### 1. Spec

Spawn agent from `.bob/agents/spec-writer.md`.
Prompt: read `factory/REPO.md`; write `factory/jobs/<id>/spec.md` for `<feature>`.
Wait. Set `stage: build`.

### 2. Build

**First time:** spawn agent from `.bob/agents/builder.md` with **name** `builder-<id>`.
Prompt: read REPO.md + spec.md; implement on branch `factory/<id>`; test against acceptance criteria; commit; write `build.md`.

**Later rounds / rework:** resume that same builder with **SendMessage** (do not spawn a new one). Point it at the round folder (or rework note).

Wait. Create `factory/jobs/<id>/round-<n>/`. Set `stage: review`, reset all four reviews to `pending`.

### 3. Parallel review

Spawn all four in one turn (fresh agents each round):

| Agent file | Writes |
|------------|--------|
| `.bob/agents/security.md` | `round-<n>/review-security.md` |
| `.bob/agents/ux.md` | `round-<n>/review-ux.md` |
| `.bob/agents/ui-design.md` | `round-<n>/review-ui.md` |
| `.bob/agents/code.md` | `round-<n>/review-code.md` |

Each prompt: read REPO.md, spec.md, build.md, and the branch diff; write only your review file. First line must be `VERDICT: PASS` or `VERDICT: CHANGES`.

As each file appears, update `board.reviews`.

### 4. WAIT FOR ALL

A round is done **only** when all four review files exist in `round-<n>/`.
**Never** resume the builder mid-round.

Then:

- **Any `VERDICT: CHANGES`** and `round < 2`: SendMessage to `builder-<id>` with the round folder path; bump `round`; go to step 2.
- **Any CHANGES** and `round >= 2`: set `stage: needs-human`; stop; tell the user to `/factory approve` or `/factory rework`.
- **All PASS**: set `stage: approve`; continue.

### 5. Approver

Spawn `.bob/agents/approver.md`.
Writes `factory/jobs/<id>/decision.md` starting with `APPROVE` or `ESCALATE`.

- **APPROVE:** merge `factory/<id>` into main; set `stage: merged`.
- **ESCALATE:** set `stage: needs-human`; stop.

## `/factory approve <job-id>`

Only for `needs-human`. Merge branch into main; set `stage: merged`; append a note to `decision.md`.

## `/factory rework <job-id> <note>`

1. Write note into `factory/jobs/<id>/rework.md`.
2. Set `stage: build`, clear reviews to `pending` (keep round or bump — prefer bump if reviews exist).
3. SendMessage to `builder-<id>` pointing at `rework.md` + latest round folder.
4. Continue from loop step 2.

## Rules

- You alone write `factory/board.json`.
- Agents write only their own file; context from disk.
- Max **2** review rounds automatically; then `needs-human`.
- Builder name is always `builder-<job-id>`; resume via SendMessage.
- Dashboard: `cd factory && python3 -m http.server` → open `dashboard.html`.
