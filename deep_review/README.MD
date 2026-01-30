# Deep Review Plan

## Purpose

Precise, line-by-line review plan for a Flutter app. Split into focused areas (Firebase, UI, state management, networking, performance, security, cost, architecture, linting). Each area has a dedicated MD file with:

* concrete review checklist
* template for reporting issues (file + line + fix)
* automated checks to run
* priority action items

## Folder structure

```
deep_review/
├─ README.md
├─ 01_firebase.md
├─ 02_ui.md
├─ 03_state_management.md
├─ 04_networking.md
├─ 05_performance.md
├─ 06_security.md
├─ 07_cost_optimization.md
├─ 08_architecture.md
├─ 09_code_style_and_linting.md
```

## How to use

1. Run automated baseline checks (see each file).
2. Assign reviewers to modules; reviewers must perform a line-by-line pass using the checklist in each area.
3. Record every finding using the reporting template in each file.
4. Triage: mark issues High/Medium/Low and tag by impact: Performance | Security | Cost | Correctness | Maintainability.
5. Produce a follow-up patch set addressing High then Medium issues.

## Final priorities (do this order)

1. High severity Security & Firebase issues (data exposure, open rules, runaway reads).
2. Critical Performance hotspots (main-thread work, memory leaks).
3. Reliability (timeouts, retry/backoff).
4. analyze but ignore test issues.
5. Cost optimization changes that reduce cloud usage.
6. UI/accessibility and style/lint housekeeping.