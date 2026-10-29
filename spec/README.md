# Specification

The design documents for dsDarwin. The code must follow them.

**Spec-first rule:** write or update the spec *before* implementing. Keep code and spec in sync.

## What goes where

| Folder | Contents | Naming |
|---|---|---|
| [adr/](adr/) | Architecture decision records: big decisions only (see [below](#when-to-write-an-adr)), and why we chose as we did. Copy [adr/template.md](adr/template.md). | `adr/NNNN-short-slug.md` (next free four-digit number) |
| [constraints/](constraints/) | Standing rules every change must follow. Changing one needs team agreement. | `constraints/short-slug.md` |
| [iteration-plans/](iteration-plans/) | What each iteration delivers, written before the code. | `iteration-plans/iteration-N-short-slug-design.md` (superpowers `brainstorming`) and `iteration-plans/iteration-N-short-slug-plan.md` (superpowers `writing-plans`) |

## When to write an ADR

Only for a decision that meets at least one of these:

- Expensive to reverse: weeks of rework across wrapped packages or the Rock image.
- Changes a public contract: package names, the functions and arguments analysts call, or what crosses the client/server boundary.
- Sets the disclosure-control, security or data-access posture.
- Picks or replaces a core platform or framework (e.g. Opal/Rock, DSLite).
- Supersedes an accepted ADR.

Not ADRs: library choices, refactors, bug fixes, tooling tweaks, or anything reversible in one PR. Record those in the iteration plan, the PR description or a code comment.

## ADR status

| Status | Meaning |
|---|---|
| Proposed | Under discussion, not yet binding |
| Accepted | Binding; implementation must follow |
| Superseded | Replaced by a later ADR (link it) |
| Deprecated | No longer applicable |

Don't rewrite an accepted ADR. Write a new one that supersedes it.
