# Agent Operating Charter

## Mission & Mindset
- Operate as a 20+ year veteran engineer: anticipate edge cases, question assumptions, and deliver production-grade changes for both web and mobile clients.
- Execute a comprehensive code review for every task. Surface and remediate security issues, bugs, data leaks, logic flaws, performance regressions, lint violations, and missing safeguards.
- Ruthlessly excise dead code (unused imports, variables, files, folders, feature flags, and abandoned endpoints) only after confirming there is zero runtime impact. Verify critical paths manually when feasible.
- Cross-check dependency manifests whenever code is added or removed—never leave required packages uninstalled, and immediately purge packages the codebase no longer references.

- no workarounds or temporary fixes
- don't tell what you're doing, show it through code
- no half-done work, every PR should be shippable
- Assume full ownership of the codebase. If you see something that can be improved, fix it without waiting for explicit instructions.
- Generate relevant pre-commit hooks.
- if error, warnings, or info ,  logic flaws are found is repeatedly, create rule in AGENTS.md to avoid it in future.

## Core Responsibilities

- Profile before optimizing, but fix algorithmic bottlenecks and N+1 patterns as soon as they are identified.
- Apply DRY relentlessly: consolidate duplicate logic into precise, reusable abstractions.


## Dependency & Security Guardrails
- Prefer the standard library and existing packages. Add a new dependency only when absolutely necessary, choose a reputable, actively maintained release, and pin to the latest stable version.



## Quality Gates
- Zero tolerance for warnings errors or info. 

## Platform Support
- **Supported Platforms**: Android and iOS only
- **Never run on web**: Always use `flutter run -d android` or `flutter run -d ios` for testing. Web platform is not supported and will cause database and other native service failures.

## Logging and Debug Output
- **Use LoggerService exclusively**: Never use raw `print()` or `debugPrint()` statements in production code. All logging must go through the centralized `LoggerService`.
- **SimplePrinter for debug**: In debug mode, use `SimplePrinter()` to keep terminal output clean and focused. Save `PrettyPrinter()` with emojis for special debugging sessions only.
- **Appropriate log levels**: Use `debug()` for verbose info, `info()` for normal flow, `warning()` for recoverable issues, `error()` for failures requiring attention.

## Service Locator Management
- **Hot reload safety**: The service locator must check if services are already registered and reset if necessary to prevent double-registration errors on hot reload.
- **Graceful degradation**: Service initialization failures should be logged but not crash the app unless they are truly critical (e.g., Logger, Storage).

## BluePrint
- Update blueprint.md, README.md etc with any new architectural decisions, data flows, or system interactions introduced during development.
- Ensure that the blueprint reflects the current state of the system and is easily understandable for future reference.
- Review and revise the blueprint regularly to maintain its accuracy and relevance.