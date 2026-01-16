# Implementation Plan: Enhance Localization Support and User Onboarding

## Phase 1: Localization Enhancement

- [ ] **Task: Conductor - User Manual Verification 'Phase 1: Localization Enhancement' (Protocol in workflow.md)**
- [ ] Task: Audit existing translations and identify missing strings.
    - [ ] Sub-task: Review `assets/translations/en.json`, `fr.json`, and `ar.json`.
    - [ ] Sub-task: Create a list of all untranslated strings in the UI.
- [ ] Task: Add missing translations for all identified strings.
    - [ ] Sub-task: Update `en.json`, `fr.json`, and `ar.json` with the new translations.
- [ ] Task: Implement language-specific formatting for dates, times, and numbers.
    - [ ] Sub-task: Write tests to verify correct formatting for each locale.
    - [ ] Sub-task: Use the `intl` package to apply locale-aware formatting.
- [ ] Task: Ensure proper Right-to-Left (RTL) support.
    - [ ] Sub-task: Write tests to verify layout mirroring and text alignment for Arabic.
    - [ ] Sub-task: Test the application thoroughly in Arabic to identify and fix any layout issues.

## Phase 2: User Onboarding

- [ ] **Task: Conductor - User Manual Verification 'Phase 2: User Onboarding' (Protocol in workflow.md)**
- [ ] Task: Design and implement the role-based onboarding flow.
    - [ ] Sub-task: Write tests for the onboarding logic.
    - [ ] Sub-task: Create separate onboarding screens for "User" and "Clinic" roles.
- [ ] Task: Implement a guided tour for new users.
    - [ ] Sub-task: Write tests for the guided tour component.
    - [ ] Sub-task: Create a reusable guided tour widget.
- [ ] Task: Add profile completion prompts.
    - [ ] Sub-task: Write tests for the profile completion prompt component.
    - [ ] Sub-task: Implement a dismissible banner or dialog to encourage profile completion.
