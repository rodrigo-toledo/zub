# Architecture: Zub

## Project Structure

```
zub/
├── build.zig
├── build.zig.zon
├── README.md
├── subliminal_zig_implementation_plan.md
├── subliminal_zig_port_analysis.md
├── src/
│   ├── main.zig              # CLI entry point (fully implemented)
│   ├── root.zig              # Library root, re-exports public API
│   ├── language.zig          # Language code handling
│   ├── video.zig             # Video metadata structures and parsing
│   ├── hash.zig              # Hashing algorithms
│   ├── subtitle.zig          # Subtitle structures
│   ├── score.zig             # Scoring engine (implemented; Phase 3)
│   ├── cli.zig               # CLI argument parsing
│   ├── core.zig              # Core orchestration
│   ├── language.test.zig
│   ├── video.test.zig
│   ├── hash.test.zig
│   ├── subtitle.test.zig
│   ├── score.test.zig
│   ├── cli.test.zig
│   ├── core.test.zig
│   ├── providers/
│   │   ├── provider.zig      # Provider interface
│   │   ├── podnapisi.zig     # Podnapisi provider (placeholder)
│   │   ├── napiprojekt.zig   # NapiProjekt provider (fully implemented)
│   │   ├── bsplayer.zig      # BSPlayer provider (fully implemented)
│   │   ├── mock.zig          # Mock provider for testing
│   │   ├── napiprojekt.test.zig
│   │   ├── bsplayer.test.zig
│   │   └── podnapisi.test.zig
│   └── utils/
│       ├── http.zig          # HTTP client wrapper (curl subprocess placeholder)
│       └── http.test.zig
└── .kilocode/
    └── rules/
        └── memory-bank/
```

Notes:
- Tests are colocated as *.test.zig under src/.
- [src/core.zig](src/core.zig) is present and implemented (integration layer).
- CLI entry exists at [src/main.zig](src/main.zig) and is fully implemented.
- Scoring engine is implemented in [src/score.zig](src/score.zig); behavior is driven by tests in [src/score.test.zig](src/score.test.zig).

## Phase Status

- Phases 1 and 2: Completed with passing tests for core data structures and initial provider system.
- Phase 3: Completed via TDD — scoring engine, CLI parsing, and core orchestration implemented with tests.
- Phase 4: Completed — added providers (NapiProjekt, BSPlayer), XML helpers if needed, and integration tests.

## Core Workflow

1.  Video Scanning: Detect video files and extract metadata from filenames.
2.  Video Refinement: Enrich metadata using external sources (optional).
3.  Subtitle Search: Query multiple providers for available subtitles.
4.  Scoring & Matching: Score subtitles based on metadata matches.
5.  Download: Fetch best matching subtitles.
6.  Save: Write subtitles with proper encoding and naming.

## Scoring Engine

- Design: Provider-agnostic matching logic with explicit episode vs movie paths, using a video type discriminator in [VideoMetadata](src/video.zig) (see [VideoMetadata.video_type](src/video.zig:17) and [detectVideoType()](src/video.zig:106)).
- Implemented functions:
  - [score.computeScore()](src/score.zig:23)
  - [score.selectBestSubtitle()](src/score.zig:107)
- Episode weights: HASH=971, SERIES=486, SEASON=54, EPISODE=54, YEAR=162.
- Movie weights: HASH=323, TITLE=162, YEAR=54.
- Selection: prefer hash match, then higher aggregate score; enforce configurable minimum score threshold.
- Behavior is defined and validated by tests in [src/score.test.zig](src/score.test.zig).

## CLI

- Parser: [cli.parseArgs()](src/cli.zig:21)
  - Defaults: min_score=0, dry_run=false
  - Flags: -l/--lang (repeatable), --min-score <u32>, --dry-run
  - Collects non-flag arguments as paths
  - Unknown flags yield error.InvalidArgument (validated by [src/cli.test.zig](src/cli.test.zig))
- Memory management: [Config.deinit()](src/cli.zig:12) frees allocated language and path slices.

## Core

- Orchestration: [core.selectBest()](src/core.zig:7) delegates subtitle selection to [score.selectBestSubtitle()](src/score.zig:107), applies the min-score threshold, and returns a copy of the winning subtitle (see tests in [src/core.test.zig](src/core.test.zig)).

## Executable

- [src/main.zig](src/main.zig) is fully implemented with complete CLI workflow integration. It handles:
  - Command line argument parsing
  - Video file processing
  - Provider initialization and search
  - Subtitle scoring and selection
  - Download and save operations (or dry-run simulation)

## Provider System

- Implemented: 
  - Podnapisi provider [src/providers/podnapisi.zig](src/providers/podnapisi.zig) with placeholder tests [src/providers/podnapisi.test.zig](src/providers/podnapisi.test.zig).
  - NapiProjekt provider [src/providers/napiprojekt.zig](src/providers/napiprojekt.zig) with full search and download functionality.
  - BSPlayer provider [src/providers/bsplayer.zig](src/providers/bsplayer.zig) with SOAP-based API integration.
  - Mock provider [src/providers/mock.zig](src/providers/mock.zig) for testing purposes.
- Interface: [src/providers/provider.zig](src/providers/provider.zig).
- Integration with scoring occurs through shared structures and matching logic.
- Registry/Orchestration: Providers are initialized and used directly in [src/main.zig](src/main.zig).

## HTTP Layer

- Current: Placeholder wrapper that will use a curl subprocess (via std.ChildProcess) in [src/utils/http.zig](src/utils/http.zig).
- Tests: Placeholder tests in [src/utils/http.test.zig](src/utils/http.test.zig).
- Future: Consider migrating to native Zig HTTP once stable and requirements are met.

## Build and Tests

- Aggregated tests wired in [build.zig](build.zig). The custom test step runs standalone test executables for language, video, hash, subtitle, score, CLI, core, provider, comprehensive, and integration modules.
- Public API surface is re-exported via [src/root.zig](src/root.zig), enabling imports like `const zub = @import("zub");` in tests.
- New test suites added:
  - [src/comprehensive.test.zig](src/comprehensive.test.zig) - Multi-provider scenarios and edge cases
  - [src/integration.test.zig](src/integration.test.zig) - End-to-end workflows from CLI to subtitle download
