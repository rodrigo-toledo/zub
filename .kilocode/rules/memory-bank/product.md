# Product: Zub

## Problem

Manually finding and downloading correct subtitles for movies and TV shows is a tedious and often frustrating process. Users have to:

1.  Search various websites.
2.  Filter through many subtitle versions to find one that syncs correctly.
3.  Deal with different file formats and naming conventions.

This process is time-consuming and inefficient.

## Solution

Zub solves this problem by automating the entire process. It is a command-line tool that:

*   Scans video files to identify them.
*   Searches multiple online subtitle providers.
*   Uses a sophisticated scoring algorithm to select the best subtitle match.
*   Downloads and saves the subtitle file with the correct name.

## User Experience Goals

*   **Simplicity**: A user should be able to get subtitles with a single, simple command.
*   **Accuracy**: Zub should consistently find and download the correct, perfectly synchronized subtitle.
*   **Speed**: The process should be fast, taking only a few seconds.
*   **Reliability**: It should work consistently across different platforms (Windows, macOS, Linux) with no external dependencies.

## CLI UX (current)

- Flags:
  - -l/--lang: specify desired subtitle language; repeatable.
  - --min-score <u32>: minimum match score threshold.
  - --dry-run: simulate actions without downloading.

- Example:
  zub --lang en --min-score 500 --dry-run /videos/Show.S01E01.mkv

- Parser implementation: [cli.parseArgs()](src/cli.zig:21)
