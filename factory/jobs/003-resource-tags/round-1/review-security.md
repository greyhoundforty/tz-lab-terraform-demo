VERDICT: CHANGES

## Findings

1. Do not put `resource_group_id`, CRNs, or API-related identifiers into tag values — they leak account shape into every console view and export.
2. Keep tag values to the agreed non-sensitive keys (`lab`, `prefix`).

## Required for PASS

- Confirm tags only use `lab` and `prefix` (no CRN / group id)
- Document in a one-line comment that tags must stay non-sensitive
