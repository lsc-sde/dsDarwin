# Iteration 4 design: HERON analysis doc

Issue: #12. Date: 2026-11-16. Result: [docs/heron-analysis.md](../../docs/heron-analysis.md).

## Intent

One place that says what HERON calls, which of its results dsDarwin must reproduce, what our fedn-ds-sandbox already
wraps, and what dsDarwin still has to decide (writeSchema, disclosure control, ...). Analysis only, no run steps.

## Decisions

- **Target is tiered** (user). Tier 1: snapshot, person, observation period, clinical records, trend, characteristics.
  Tier 2: IMD and the 7 rebuilt observation periods. The run log is not a target.
- **fedn-ds-sandbox is our code**: adapt freely (user).
- **One doc** (user, approach A). Rejected: B, a committed CSV of target estimates (add it with the first comparison
  test); C, a function-coverage CSV (a second copy of the table to keep in sync).
- Reference values come from the Delphi all-dates run: HERON's 2012+ range is empty on Delphi (my call).
- "Match" = same result keys, values within tolerance, both sides suppressed with the same threshold (my call).
- The run notes (`docs/heron-native-run.md`) are dropped; their facts are the doc's baseline paragraph (my call).
