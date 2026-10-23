# Specification

The design documents for dsDarwin. The code must follow them.

**Spec-first rule:** write or update the spec *before* implementing. Keep code and spec in sync.

## What goes where

| Folder | Contents | Naming |
|---|---|---|
| [adr/](adr/) | Architecture decision records: choices that could have gone another way, and why we chose as we did. Copy [adr/template.md](adr/template.md). | `adr/NNNN-short-slug.md` (next free four-digit number) |
| [constraints/](constraints/) | Standing rules every change must follow. Changing one needs team agreement. | `constraints/short-slug.md` |
| [iteration-plans/](iteration-plans/) | What each iteration delivers, written before the code. | `iteration-plans/iteration-N-short-slug.md` |

## ADR status

| Status | Meaning |
|---|---|
| Proposed | Under discussion, not yet binding |
| Accepted | Binding; implementation must follow |
| Superseded | Replaced by a later ADR (link it) |
| Deprecated | No longer applicable |

Don't rewrite an accepted ADR. Write a new one that supersedes it.
