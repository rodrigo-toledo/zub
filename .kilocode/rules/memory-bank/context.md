# Context: Zub

- Current Focus: Project Completion - All core functionality implemented and tested

- Recent Changes:
  - Phase 3 completed via TDD:
    - Scoring engine implemented: [score.computeScore()](src/score.zig:23) and [score.selectBestSubtitle()](src/score.zig:107) with provider-agnostic logic, tie-breaks (prefer hash match, then higher aggregate score), and a min-score threshold.
    - Episode weights: HASH=971, SERIES=486, SEASON=54, EPISODE=54, YEAR=162.
    - Movie weights: HASH=323, TITLE=162, YEAR=54.
    - [src/video.zig](src/video.zig) updated to include a video_type discriminator used by scoring.
  - CLI Argument Parsing:
    - [cli.parseArgs()](src/cli.zig:21) in [src/cli.zig](src/cli.zig); Config defaults: min_score=0, dry_run=false; supports -l/--lang accumulation, --min-score, --dry-run; collects remaining args as paths; rejects unknown flags; tests in [src/cli.test.zig](src/cli.test.zig).
  - Core Orchestration:
    - [core.selectBest()](src/core.zig:7) in [src/core.zig](src/core.zig) delegates to [score.selectBestSubtitle()](src/score.zig:107) with min-score threshold; tests in [src/core.test.zig](src/core.test.zig).
  - Wiring:
    - [src/root.zig](src/root.zig) exports cli and core modules; [build.zig](build.zig) includes cli/core/score tests; all tests green via zig build test.
  - Phase 4 completed:
    - Implemented NapiProjekt provider [src/providers/napiprojekt.zig](src/providers/napiprojekt.zig) with full search and download functionality
    - Implemented BSPlayer provider [src/providers/bsplayer.zig](src/providers/bsplayer.zig) with SOAP-based API integration
    - Added comprehensive testing with [src/comprehensive.test.zig](src/comprehensive.test.zig) covering multi-provider scenarios
    - Added integration testing with [src/integration.test.zig](src/integration.test.zig) covering end-to-end workflows
    - Completed main.zig implementation with full CLI workflow integration
    - Updated build.zig to include new providers and test suites

- New/updated files:
  - [src/score.zig](src/score.zig), [src/score.test.zig](src/score.test.zig)
  - [src/cli.zig](src/cli.zig), [src/cli.test.zig](src/cli.test.zig)
  - [src/core.zig](src/core.zig), [src/core.test.zig](src/core.test.zig)
  - [src/video.zig](src/video.zig) (added video_type)
  - [src/root.zig](src/root.zig), [build.zig](build.zig)
  - [src/providers/napiprojekt.zig](src/providers/napiprojekt.zig), [src/providers/napiprojekt.test.zig](src/providers/napiprojekt.test.zig)
  - [src/providers/bsplayer.zig](src/providers/bsplayer.zig), [src/providers/bsplayer.test.zig](src/providers/bsplayer.test.zig)
  - [src/comprehensive.test.zig](src/comprehensive.test.zig)
  - [src/integration.test.zig](src/integration.test.zig)
  - [src/main.zig](src/main.zig) (fully implemented)

- Next Steps:
  - Project is fully implemented and ready for use
  - All core functionality is complete with comprehensive test coverage
  - Ready for distribution as a single-binary cross-platform command-line tool
