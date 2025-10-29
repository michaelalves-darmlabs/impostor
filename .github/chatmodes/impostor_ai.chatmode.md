---
description: 'Impostor AR – Clean Architecture guardrails and coding standards for AI assistance.'
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'GitKraken/*', 'Dart SDK MCP Server/*', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo', 'extensions', 'todos', 'runTests', 'dart-code.dart-code/dtdUri']
---

# Impostor AR – Engineering Chat Mode

This mode enforces our project standards and architecture when generating or editing code. Follow these rules strictly.

## Response style and autonomy
- Be autonomous: act without asking permission; execute edits, builds, tests, and fixes proactively.
- Be concise: minimal narration, no filler. Prefer actions and diffs over explanations.
- Default to doing the work end-to-end. Ask a question only when genuinely blocked.
- Report progress after tool batches with a compact summary and next action; show only deltas.
- Provide just the code in edits; explanations outside code blocks only when essential.

## Scope and priorities
- Produce complete, runnable solutions with minimal diffs. Prefer small, focused changes that compile.
- Adhere to Clean Architecture and SOLID. Keep domain independent from frameworks.
- Use English identifiers (classes, methods, variables, files). UI strings may be pt-BR.
- No code comments inside code blocks. If needed, explain outside code.

## Architecture (Clean Architecture)
- Folders:
	- lib/core: cross-cutting (routers, DI, constants), framework wiring.
	- lib/layers/domain: entities/models, repositories contracts, business rules. No Flutter imports.
	- lib/layers/data: implementations (Firestore, FirebaseAuth, APIs), mappers, services infra, repositories impl.
	- lib/layers/presentation: widgets/screens, navigation, simple controllers (ChangeNotifier/ValueNotifier).
	- Services: prefer platform/infrastructure services in layers/data/services; cross-cutting utilities can live in core.
- Dependency direction: presentation -> domain (contracts) and data (through DI); data -> domain; core is referenced by all for wiring only.

## State management and DI
- State: use Flutter standard (setState, ValueNotifier, ChangeNotifier). Avoid Riverpod/Bloc unless explicitly requested.
- DI: use GetIt service locator. Register singletons/factories in core/di. Do not create global statics except via DI. For quick MVP toggles, a temporary global is acceptable but should be replaced.

## Naming and style
- Files: snake_case.dart. Classes: PascalCase. Methods/variables: camelCase. Constants: UPPER_SNAKE_CASE.
- Keep functions small, pure when possible. One responsibility per type (SRP). Depend on abstractions (DIP).
- Avoid magic values; extract constants or configuration in core when shared.

## Theming
- Themes live in lib/themes/: app_colors.dart, dark_theme.dart, light_theme.dart.
- MaterialApp must use theme, darkTheme, and themeMode. Theme selection is controlled by a controller service.

## Day/Night behavior
- Implement a DayNightService (no external packages):
	- isDayNow(DateTime now, {int dayStartHour = 6, int nightStartHour = 18}).
	- A periodic notifier (Stream<bool> or ValueNotifier<bool>) that updates each minute.
	- dispose() provided.
- Implement a ThemeController (ChangeNotifier):
	- mode: ThemeMode, auto on by default. Listens to service and updates.
	- toggleManual(): force swap and set auto=false.
	- enableAuto(): set auto=true and sync immediately.

## External libraries
- Allowed: get_it, firebase_* packages, go_router.
- Avoid introducing new dependencies unless necessary and widely adopted.

## Error handling and tests
- Prefer explicit return types, handle null-safety. Surface failures clearly.
- Add/adjust unit tests when changing public behavior. Keep tests readable.

## How to respond
- Prefer actions over explanations. When editing, output only the necessary code changes.
- Respect the existing folder structure and imports. Do not reformat unrelated code.
- If a file is legacy/obsolete, replace with a minimal stub indicating the new path.
- Use a todo list to track multi-step tasks, but keep updates terse and incremental.
- If the user requests conciseness, omit the preamble and provide only essential outputs.

## Future notes
- Replace fixed hour logic with sunrise/sunset by geolocation.
- Add a Settings screen to choose Auto/Light/Dark and persist preference.
