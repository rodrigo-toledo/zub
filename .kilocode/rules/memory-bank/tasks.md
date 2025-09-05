# Tasks: Zub

## Implement Feature via TDD
Last performed: 2025-09-05

Files typically involved:
- [build.zig](build.zig)
- [src/root.zig](src/root.zig)
- [src/score.test.zig](src/score.test.zig)
- [src/score.zig](src/score.zig)
- Additional module and test files as required

Steps:
0. TDD Policy:
   - Write failing tests that assert final behavior (no placeholder error expectations).
   - Use // TDD-PLACEHOLDER only if absolutely necessary and limit modifiable lines to those tagged.
   - During implementation, do not change tests except lines tagged with // TDD-PLACEHOLDER.
1. Identify the behavior to add or change and write failing tests:
   - Create or update a test file under [src/](src/) following the *.test.zig convention (e.g., [src/score.test.zig](src/score.test.zig)).
   - Target exact functions or APIs, e.g. [score.computeScore()](src/score.zig:23) and [score.selectBestSubtitle()](src/score.zig:107).
2. Run tests to confirm failures:
   - zig build test
3. Implement the minimal code to make tests pass in the corresponding source file(s):
   - For scoring, update [src/score.zig](src/score.zig).
4. Re-run tests and iterate until green:
   - zig build test
5. Refactor while keeping tests green.
6. Wire public API if needed:
   - Re-export new types/functions in [src/root.zig](src/root.zig) for test and consumer imports via `@import("zub")`.
7. Update build wiring if a new standalone test file was added:
   - Add a createModule/test block in [build.zig](build.zig) mirroring the pattern used for [src/score.test.zig](src/score.test.zig).
8. Update documentation:
   - Update memory bank files (context, architecture, tech) to reflect changes.

Important considerations:
- Keep tests colocated with sources as *.test.zig.
- Prefer provider-agnostic logic; encode provider-specific weights in [src/score.zig](src/score.zig) behind clear constants/tables.
- Use clear, deterministic inputs in tests to avoid flakiness.

Do:
- Assert concrete outputs/structures/side-effects.
- Use deterministic fixtures.
- Limit scope.

Don't:
- Assert error.NotImplemented or placeholders.
- Rely on unimplemented behavior.
- Write tests that must be entirely replaced.

Example: Scoring Engine (Phase 3)
- Write expectations in [src/score.test.zig](src/score.test.zig) for:
  - Hash weighting (episodes: expect 971)
  - Series/season/episode/year accumulation (e.g., 486 + 54 + 54 + 162 = 756)
  - Best selection with minimum score
- Implement corresponding logic in [src/score.zig](src/score.zig) focusing on [score.computeScore()](src/score.zig:23) and [score.selectBestSubtitle()](src/score.zig:107).

## Add New Provider via TDD
Last performed: 2025-09-05

Files typically involved:
- [src/providers/provider.zig](src/providers/provider.zig)
- Provider implementation: [src/providers/<name>.zig](src/providers/)
- Provider tests: [src/providers/<name>.test.zig](src/providers/)
- HTTP client: [src/utils/http.zig](src/utils/http.zig) via [HttpClient.get()](src/utils/http.zig:23) and [HttpClient.post()](src/utils/http.zig:32)
- Build wiring: [build.zig](build.zig)

Steps:
0. TDD Policy:
   - Write failing tests that assert final behavior (no placeholder error expectations).
   - Use // TDD-PLACEHOLDER only if absolutely necessary and limit modifiable lines to those tagged.
   - During implementation, do not change tests except lines tagged with // TDD-PLACEHOLDER.
1. Define provider API contract tests:
   - Create failing tests in [src/providers/<name>.test.zig](src/providers/) exercising search and download.
2. Stub the provider:
   - Create [src/providers/<name>.zig](src/providers/) that adheres to interfaces in [src/providers/provider.zig](src/providers/provider.zig).
3. Implement HTTP interactions:
   - Use [HttpClient.get()](src/utils/http.zig:23) / [HttpClient.post()](src/utils/http.zig:32).
   - For early stages, return placeholder errors until real HTTP is implemented.
4. Parse responses and map to subtitle structures:
   - Populate [src/subtitle.zig](src/subtitle.zig) types from provider payloads.
5. Iterate until tests are green:
   - zig build test (ensure provider tests are wired or run individually with zig test path)
6. Integrate with scoring if necessary:
   - Ensure fields required by [score.computeScore()](src/score.zig:23) are filled.
7. Document and wire:
   - Update memory bank (architecture/provider system, tech).
   - Optionally add a test step in [build.zig](build.zig) for the provider's test file mirroring existing patterns.

Important considerations:
- Keep provider-specific logic isolated; avoid leaking details into core modules.
- Consider fixtures or mocks for HTTP to keep tests deterministic.
- Validate error handling paths (network errors, timeouts) consistent with HttpError in [src/utils/http.zig](src/utils/http.zig).

Do:
- Assert concrete outputs/structures/side-effects.
- Use deterministic fixtures.
- Limit scope.

Don't:
- Assert error.NotImplemented or placeholders.
- Rely on unimplemented behavior.
- Write tests that must be entirely replaced.

Example: Podnapisi
- Implementation: [src/providers/podnapisi.zig](src/providers/podnapisi.zig)
- Tests: [src/providers/podnapisi.test.zig](src/providers/podnapisi.test.zig)
- Current tests are placeholders; real tests should validate search and download behaviors.

## Implement CLI/Core via TDD
Last performed: 2025-09-05

Files typically involved:
- [src/cli.zig](src/cli.zig)
- [src/cli.test.zig](src/cli.test.zig)
- [src/core.zig](src/core.zig)
- [src/core.test.zig](src/core.test.zig)
- [src/root.zig](src/root.zig)
- [build.zig](build.zig)

Steps:
0. TDD Policy:
   - Write failing tests that assert final behavior (no placeholder error expectations).
   - Use // TDD-PLACEHOLDER only if absolutely necessary and limit modifiable lines to those tagged.
   - During implementation, do not change tests except lines tagged with // TDD-PLACEHOLDER.
1. Write failing tests:
   - In [src/cli.test.zig](src/cli.test.zig), target [cli.parseArgs()](src/cli.zig:21) for:
     - -l/--lang accumulation, --min-score parsing, --dry-run flag
     - Unknown flag rejection (error.InvalidArgument)
     - Path collection behavior
   - In [src/core.test.zig](src/core.test.zig), target [core.selectBest()](src/core.zig:7) to:
     - Delegate to [score.selectBestSubtitle()](src/score.zig:107)
     - Enforce minimum score threshold and return a copy
2. Implement minimal logic in [src/cli.zig](src/cli.zig) and [src/core.zig](src/core.zig) to satisfy tests.
3. Export via [src/root.zig](src/root.zig) and wire standalone test steps in [build.zig](build.zig).
4. Keep tests deterministic and isolated from I/O; prefer in-memory data structures.
5. After green, refactor and update Memory Bank (context, architecture, tech).

Important considerations:
- Ensure allocator hygiene; free slices via [Config.deinit()](src/cli.zig:12).
- Avoid side effects in tests; do not start processes or perform network I/O.

Do:
- Assert concrete outputs/structures/side-effects.
- Use deterministic fixtures.
- Limit scope.

Don't:
- Assert error.NotImplemented or placeholders.
- Rely on unimplemented behavior.
- Write tests that must be entirely replaced.