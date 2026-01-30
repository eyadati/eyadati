# Review Checklist: Code Style and Linting

## Purpose

Enforce consistent style, catch anti-patterns early.

## Findings

| File | Issue | Severity | Suggested fix |
|---|---|---|---|
| Entire `lib/` | Formatting inconsistencies (tabs vs spaces, line lengths). | Resolved | Ran `dart format .`. |
| Multiple files | Persistent `use_build_context_synchronously` warnings. | Resolved | Added `mounted` and `context.mounted` guards. |
| `lib/utils/seed_data.dart` | Unused variables and missing imports after refactor. | Resolved | Cleaned up and verified with `flutter analyze`. |

## Verified
* [x] No lint errors remaining in the `lib/` directory.
* [x] Null-safety compliance across the project.
* [x] Consistent snake_case for filenames.