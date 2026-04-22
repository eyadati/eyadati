# Flutter Development Rules & Standards

## Mandatory Quality Gates — Run After EVERY Code Change

1. **Static Analysis**
   - Run `flutter analyze --fatal-infos` and fix ALL issues before proceeding
   - Run `dart format --set-exit-if-changed .` 
   - Ensure zero lint warnings (treat infos as warnings)

2. **Testing**
   - Run `flutter test` — all tests must pass
   - If no tests exist for modified code, write them before marking complete
   - Target: &gt;70% coverage on business logic, 100% on critical paths

3. **Code Cleanup**
   - Remove or convert all `print()` statements to proper logging (logger, talker)
   - Delete unused imports, variables, and dead code
   - Ensure no hardcoded values (colors, strings, API keys) in UI code

---

## Architecture Rules — Strict Enforcement

### State Management
- Use Provider — never setState for business logic
- Keep providers in separate files, organized by feature
- Use code generation — never hand-write boilerplate

### Dependency Injection
- Use get_it + injectable — never instantiate services/repositories in widgets
- Register all dependencies in `injection.dart`
- Constructor injection only — no service locators in business logic

### Layer Separation (Clean Architecture)
lib/
├── core/                    # Shared utilities, constants, theme
├── features/
│   └── feature_name/
│       ├── data/           # Repositories impl, API clients, DB
│       ├── domain/         # Entities, use cases, repository interfaces
│       └── presentation/   # Widgets, states, providers
- Data layer: Handles API calls, caching, local storage
- Domain layer: Pure Dart, no Flutter dependencies, contains business rules
- Presentation layer: Dumb widgets, only display state from providers

### Data Classes
- Use freezed for ALL models, states, and events
- Immutable only — no mutable variables in state classes
- Proper serialization with json_serializable
- Handle null safety explicitly — no implicit casts

---

## Code Quality Standards

### Performance
- Use `const` constructors everywhere possible
- No heavy work in build() methods — cache calculations
- Properly dispose streams, controllers, listeners
- Use RepaintBoundary for complex static widgets
- Image caching and proper sizing (CachedNetworkImage)

### Widget Design
- Max 5 levels of nesting — extract to private widgets if deeper
- Max 50 lines per function, 300 lines per file
- Separate business logic from UI — widgets should only display
- Support responsive layouts — no hardcoded pixel values
- Implement proper loading, error, and empty states

### UI/UX Consistency
- Follow Material 3 design guidelines
- Dark/light theme support via Theme.of(context)
- Accessibility: semantic labels, contrast ratios, font scaling
- Error handling: user-friendly messages, retry mechanisms

---

## Security & Best Practices

- **Secrets**: Use `--dart-define` or envied — never commit API keys
- **Input validation**: Validate all forms and API responses
- **Storage**: Use flutter_secure_storage for tokens/sensitive data
- **Network**: Add timeouts, retry logic, and proper error mapping
- **Dependencies**: Pin versions, verify null-safety, minimize bloat

---

## Testing Requirements

- Unit tests for use cases and repositories (mockito/mocktail)
- Widget tests for critical user flows
- Golden tests for UI components (optional but recommended)
- Mock external dependencies — never call real APIs in tests
- Test edge cases: empty states, errors, loading, timeouts

---

## Self-Healing Patterns — Apply Automatically

When you detect:
- **Deprecated APIs** → Migrate to current stable alternatives immediately
- **Long functions** (>50 lines) → Extract private methods or classes
- **Duplicate code** (>2 times) → Create reusable widgets/functions
- **Deep nesting** (>5 levels) → Extract widgets or use CustomPainter
- **Tight coupling** → Introduce abstractions and interfaces

---

## Documentation Standards

- Dart doc comments for all public APIs (///)
- Update README.md when adding features or changing setup
- CHANGELOG.md entry for breaking changes
- Inline comments only for complex business logic (not obvious code)

---

## Project Context Awareness

Before implementing:
1. Check `pubspec.yaml` for existing packages — use compatible ones
2. Review `analysis_options.yaml` — follow project-specific lints
3. Match existing patterns in `lib/` — don't introduce inconsistencies
4. Check `.gitignore` — ensure generated files (*.g.dart, *.freezed.dart) are handled

---

## Command Reference (Run These)

```bash
# After every change
flutter analyze --fatal-infos
dart format --set-exit-if-changed .
flutter test --coverage

# Before commit
flutter pub run build_runner build --delete-conflicting-outputs