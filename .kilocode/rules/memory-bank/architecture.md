# Architecture: Zub

## Project Structure

```
subliminal-zig/
├── build.zig
├── src/
│   ├── main.zig              # CLI entry point
│   ├── core.zig              # Core API functions
│   ├── video.zig             # Video detection and metadata
│   ├── subtitle.zig          # Subtitle structures
│   ├── hash.zig              # Hashing algorithms
│   ├── score.zig             # Scoring engine
│   ├── language.zig          # Language code handling
│   ├── encoding.zig          # Character encoding
│   ├── providers/
│   │   ├── provider.zig      # Provider interface
│   │   ├── podnapisi.zig     # Podnapisi provider
│   │   ├── napiprojekt.zig   # NapiProjekt provider
│   │   ├── bsplayer.zig      # BSPlayer provider
│   │   └── opensubtitles.zig # OpenSubtitles provider
│   └── utils/
│       ├── http.zig          # HTTP client wrapper
│       ├── xml.zig           # Basic XML parser
│       └── json.zig          # JSON utilities
├── tests/
│   ├── hash_test.zig
│   ├── video_test.zig
│   └── providers_test.zig
└── README.md
```

## Core Workflow

1.  **Video Scanning**: Detect video files and extract metadata from filenames.
2.  **Video Refinement**: Enrich metadata using external sources (optional).
3.  **Subtitle Search**: Query multiple providers for available subtitles.
4.  **Scoring & Matching**: Score subtitles based on metadata matches.
5.  **Download**: Fetch best matching subtitles.
6.  **Save**: Write subtitles with proper encoding and naming.

## Key Decisions

1.  **HTTP Client**: Start with `curl` subprocess, later implement native HTTP.
2.  **XML Parsing**: Use simple regex initially, consider C library binding later.
3.  **Configuration**: TOML format for simplicity.
4.  **Provider Priority**: Focus on JSON/simple APIs first.
5.  **Error Handling**: Use Zig's error unions throughout.
