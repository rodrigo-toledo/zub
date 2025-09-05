# Tech Stack: Zub

## Core Language
- Zig

## Build System
- Zig Build System with project build configuration in [build.zig](build.zig)

## Development Practices
- Test-Driven Development (TDD) is mandatory:
  - Write failing tests first for each feature.
  - Implement the minimal code to make tests pass.
  - Refactor while keeping tests green.
  - Update documentation (memory bank) after significant changes.
- TDD Policy:
  - Tests must assert target behavior, not placeholder states.
  - Do NOT assert or depend on errors like error.NotImplemented/error.Unimplemented or similar placeholder behavior.
  - Failing tests must fail due to behavioral mismatches (e.g., wrong return value/fields), not missing implementation.
  - If a placeholder is unavoidable, mark the exact lines with a standard comment token:
    // TDD-PLACEHOLDER: this line may be revised during implementation
    Only lines tagged with this token may be modified later; all other test lines are stable.
  - Stubs may exist in code under test, but tests must never assert stub-specific errors; they must assert the desired behavior that will be implemented.

## Testing
- Test layout and naming:
  - Tests are colocated alongside sources as `*.test.zig` under [src/](src/)
  - Current tests:
    - [src/language.test.zig](src/language.test.zig)
    - [src/video.test.zig](src/video.test.zig)
    - [src/hash.test.zig](src/hash.test.zig)
    - [src/subtitle.test.zig](src/subtitle.test.zig)
    - [src/providers/podnapisi.test.zig](src/providers/podnapisi.test.zig)
    - [src/utils/http.test.zig](src/utils/http.test.zig)
    - [src/score.test.zig](src/score.test.zig)
    - [src/cli.test.zig](src/cli.test.zig)
    - [src/core.test.zig](src/core.test.zig)
- Running the full test suite:
  - Use: zig build test
  - Aggregated test executables and steps are wired in [build.zig](build.zig)
- Public API for tests:
  - Tests import the library via `const zub = @import("zub");`, re-exported in [src/root.zig](src/root.zig)
- TDD Policy applicability:
  - This policy applies uniformly across unit, provider, CLI, core, and integration tests.

## Scoring Module (Phase 3)
- Implemented functions:
  - [score.computeScore()](src/score.zig:23)
  - [score.selectBestSubtitle()](src/score.zig:107)
- Behavior (validated by [src/score.test.zig](src/score.test.zig)):
  - Episode weights: HASH=971, SERIES=486, SEASON=54, EPISODE=54, YEAR=162.
  - Movie weights: HASH=323, TITLE=162, YEAR=54.
  - Tie-break: prefer hash match; otherwise higher aggregate score; enforce minimum score threshold.
- Video type discriminator:
  - [VideoMetadata.video_type](src/video.zig:17) and [detectVideoType()](src/video.zig:106) enable explicit episode vs movie scoring paths.

## CLI
- Parser: [cli.parseArgs()](src/cli.zig:21)
  - Defaults: min_score=0, dry_run=false
  - Flags: -l/--lang (repeatable), --min-score <u32>, --dry-run
  - Collects non-flag arguments as paths
  - Unknown flags yield error.InvalidArgument (validated by [src/cli.test.zig](src/cli.test.zig))
- Memory management: [Config.deinit()](src/cli.zig:12) frees allocated language and path slices.

## Core
- Orchestration: [core.selectBest()](src/core.zig:7) delegates to [score.selectBestSubtitle()](src/score.zig:107), applies min-score, and returns a copy (see [src/core.test.zig](src/core.test.zig)).

## HTTP Layer
- Current implementation:
  - Placeholder wrapper that will use a curl subprocess in [src/utils/http.zig](src/utils/http.zig)
  - The client returns placeholder errors until implemented; see file for details
- Future direction:
  - Consider migrating to native Zig HTTP once stable and requirements are met

## Provider System
- Interface defined in [src/providers/provider.zig](src/providers/provider.zig)
- Implemented provider (placeholder tests): [src/providers/podnapisi.zig](src/providers/podnapisi.zig) with [src/providers/podnapisi.test.zig](src/providers/podnapisi.test.zig)
- Planned providers: NapiProjekt, BSPlayer (to be added via TDD)

## Targets and Constraints
- Cross-platform goal: Windows, macOS, Linux
- Initial development prioritizes Linux for stability prior to expanding cross-platform coverage
- Performance and single-binary distribution are core goals
