# Subliminal Python to Zig Port - Comprehensive Analysis

## Executive Summary

Subliminal is a sophisticated subtitle downloading library written in Python that automatically searches, downloads, and matches subtitles for video files. This analysis provides a comprehensive understanding of the codebase to facilitate a minimal, single-binary Zig port.

## 1. Core Architecture Overview

### 1.1 Main Components

```
subliminal/
├── core.py           # Main API functions (scan_videos, list_subtitles, download)
├── video.py          # Video classes (Video, Episode, Movie) and detection
├── subtitle.py       # Subtitle class and encoding handling
├── score.py          # Subtitle scoring and matching algorithm
├── providers/        # Subtitle provider implementations (11 providers)
├── refiners/         # Metadata enrichment plugins
├── extensions.py     # Plugin management via stevedore
└── cli/             # Click-based command-line interface
```

### 1.2 Core Workflow

1. **Video Scanning**: Detect video files and extract metadata from filenames
2. **Video Refinement**: Enrich metadata using external sources (optional)
3. **Subtitle Search**: Query multiple providers for available subtitles
4. **Scoring & Matching**: Score subtitles based on metadata matches
5. **Download**: Fetch best matching subtitles
6. **Save**: Write subtitles with proper encoding and naming

## 2. Video Identification System

### 2.1 Video Extensions (80+ formats)
```python
VIDEO_EXTENSIONS = ('.3g2', '.3gp', '.3gp2', '.asf', '.avi', '.divx', '.flv', 
                   '.m4v', '.mk2', '.mka', '.mkv', '.mov', '.mp4', '.mpeg', 
                   '.mpg', '.ogm', '.ogv', '.ts', '.vob', '.webm', '.wmv', ...)
```

### 2.2 Metadata Extraction
- **Primary Method**: Uses `guessit` library to parse filenames
- **Extracted Data**: 
  - Series name, season, episode
  - Movie title, year
  - Quality, codec, release group
  - Resolution, audio format

### 2.3 Video Classes
```python
class Video:
    name: str           # File path
    format: str        # Container format
    release_group: str # Release group name
    resolution: str    # Video resolution
    video_codec: str   # Video codec
    audio_codec: str   # Audio codec
    subtitle_languages: set[Language]  # Existing subtitles
    
class Episode(Video):
    series: str
    season: int
    episode: int
    title: str         # Episode title
    year: int
    tvdb_id: str      # TVDB identifier
    
class Movie(Video):
    title: str
    year: int
    imdb_id: str      # IMDB identifier
```

## 3. Hashing Mechanisms

### 3.1 OpenSubtitles Hash
```python
def hash_opensubtitles(video_path):
    """
    Hash = file_size + MD5(first_64KB + last_64KB)
    """
    filesize = os.path.getsize(video_path)
    filehash = filesize
    
    # Read first 64KB
    with open(video_path, 'rb') as f:
        for _ in range(65536 // 8):
            filehash += struct.unpack('<Q', f.read(8))[0]
            
    # Read last 64KB
    f.seek(max(0, filesize - 65536))
    for _ in range(65536 // 8):
        filehash += struct.unpack('<Q', f.read(8))[0]
        
    return f'{filehash:016x}'
```

### 3.2 Other Hash Algorithms
- **BSPlayer Hash**: Similar to OpenSubtitles but different calculation
- **NapiProjekt Hash**: MD5 of first 10MB of file

## 4. Subtitle Providers Analysis

### 4.1 Provider Summary

| Provider         | Protocol     | Auth     | Complexity | Features                            |
| ---------------- | ------------ | -------- | ---------- | ----------------------------------- |
| OpenSubtitles    | XML-RPC      | Yes      | Medium     | Hash matching, large database       |
| OpenSubtitlescom | REST API     | Yes      | High       | New API, rate limiting              |
| Addic7ed         | Web scraping | Optional | High       | TV shows focus, complex parsing     |
| Podnapisi        | REST API     | No       | Low        | Simple JSON API                     |
| BSPlayer         | XML/SOAP     | No       | Medium     | Hash-based search                   |
| TVsubtitles      | Web scraping | No       | Medium     | TV shows only                       |
| NapiProjekt      | HTTP GET     | No       | Low        | Polish subtitles, hash-based        |
| Subtitulamos     | Web scraping | No       | Medium     | Spanish subtitles                   |
| Gestdown         | REST API     | No       | Low        | Spanish subtitles, TVDB integration |

### 4.2 Provider Base Class
```python
class Provider:
    languages: Set[Language]           # Supported languages
    video_types: tuple                 # Episode, Movie, or both
    
    def initialize(self)               # Setup connection
    def terminate(self)                # Cleanup
    def query(self, **kwargs)          # Search subtitles
    def list_subtitles(self, video, languages)  # Get subtitles for video
    def download_subtitle(self, subtitle)       # Download content
```

## 5. Scoring System

### 5.1 Score Weights

**Episode Scores**:
```python
{
    'hash': 971,           # Perfect match via file hash
    'series': 486,         # Series name match
    'year': 162,          # Year match
    'country': 162,       # Country match
    'season': 54,         # Season number match
    'episode': 54,        # Episode number match
    'release_group': 18,  # Release group match
    'fps': 9,            # Frame rate match
    'source': 4,         # Source type match
    'audio_codec': 2,    # Audio codec match
    'resolution': 1,     # Resolution match
    'video_codec': 1     # Video codec match
}
```

**Movie Scores**:
```python
{
    'hash': 323,
    'title': 162,
    'year': 54,
    'country': 54,
    'release_group': 18,
    'fps': 9,
    'source': 4,
    'audio_codec': 2,
    'resolution': 1,
    'video_codec': 1
}
```

### 5.2 Scoring Algorithm
1. Get matches between subtitle and video metadata
2. Apply score weights
3. Handle special cases (hash match overrides all)
4. Consider equivalent matches (IMDB ID implies title+year+country)

## 6. Dependencies Analysis

### 6.1 Critical Dependencies (Must Replace/Implement)

| Dependency     | Purpose            | Zig Alternative                        |
| -------------- | ------------------ | -------------------------------------- |
| guessit        | Filename parsing   | Custom regex parser or port algorithms |
| babelfish      | Language codes     | Implement ISO 639 mappings             |
| requests       | HTTP client        | Zig std.http or curl bindings          |
| beautifulsoup4 | HTML parsing       | Custom parser or C library             |
| chardet        | Encoding detection | ICU or custom implementation           |

### 6.2 Optional Dependencies

| Dependency    | Purpose          | Zig Alternative            |
| ------------- | ---------------- | -------------------------- |
| dogpile.cache | Caching          | Simple file/memory cache   |
| stevedore     | Plugin loading   | Static compilation         |
| click         | CLI framework    | Zig std.process.args       |
| pysubs2       | Subtitle formats | Custom parsers for SRT/ASS |
| rarfile       | RAR support      | Exclude or use libarchive  |

## 7. Complexity Assessment

### 7.1 Components by Implementation Difficulty

**Low Complexity**:
- File scanning and filtering
- Hash calculation algorithms
- SRT subtitle format parsing
- Basic HTTP requests
- CLI argument parsing

**Medium Complexity**:
- Video metadata extraction (without guessit)
- Scoring algorithm
- Language code handling
- Configuration file parsing
- Multi-provider management

**High Complexity**:
- Full filename parsing (guessit replacement)
- HTML scraping for some providers
- Character encoding detection
- Subtitle format conversion
- Archive support

### 7.2 Features to Exclude in MVP
1. Archive scanning (RAR/ZIP support)
2. Complex providers (Addic7ed, TVsubtitles web scraping)
3. Refiners (OMDB, TMDB, TVDB integration)
4. Advanced subtitle format conversion
5. Plugin system (compile providers statically)

## 8. Minimal Zig Implementation Plan

### Phase 1: Core Foundation (Week 1-2)
```zig
// Core structures
const Video = struct {
    path: []const u8,
    hash: ?[]const u8,
    metadata: VideoMetadata,
};

const Subtitle = struct {
    language: Language,
    provider: []const u8,
    score: u32,
    content: ?[]const u8,
};

// Basic video detection
fn scanVideo(path: []const u8) !Video
fn computeOpenSubtitlesHash(path: []const u8) ![16]u8
```

### Phase 2: Provider Implementation (Week 2-3)
Start with simplest providers:
1. **NapiProjekt** - Simple HTTP GET, hash-based
2. **BSPlayer** - XML but straightforward
3. **Podnapisi** - Clean JSON API

```zig
const Provider = struct {
    name: []const u8,
    search: fn(video: Video) []Subtitle,
    download: fn(subtitle: *Subtitle) !void,
};
```

### Phase 3: Scoring & Selection (Week 3)
```zig
fn computeScore(subtitle: Subtitle, video: Video) u32
fn selectBestSubtitle(subtitles: []Subtitle, video: Video) ?Subtitle
```

### Phase 4: CLI Interface (Week 4)
```zig
// Simple CLI
fn main() !void {
    const args = try parseArgs();
    const video = try scanVideo(args.path);
    const subtitles = try searchSubtitles(video, args.languages);
    const best = selectBestSubtitle(subtitles, video);
    try downloadAndSave(best, video);
}
```

## 9. Incremental Development Strategy

### Stage 1: MVP (2-3 weeks)
- [ ] Basic video file detection
- [ ] OpenSubtitles hash implementation
- [ ] Simple filename parsing (basic regex)
- [ ] 2-3 simple providers (Podnapisi, NapiProjekt)
- [ ] Basic scoring algorithm
- [ ] CLI with essential options
- [ ] SRT format only

### Stage 2: Enhanced (1-2 weeks)
- [ ] Improved filename parsing
- [ ] Additional providers (BSPlayer, Gestdown)
- [ ] Language detection in existing subtitles
- [ ] Configuration file support
- [ ] Better error handling

### Stage 3: Advanced (Optional)
- [ ] OpenSubtitles.com REST API
- [ ] Character encoding detection
- [ ] Multiple subtitle format support
- [ ] Caching layer
- [ ] Archive scanning

## 10. Key Implementation Challenges

### 10.1 Filename Parsing
**Challenge**: Guessit uses complex regex and heuristics
**Solution**: 
- Start with basic patterns for common formats
- Incrementally add pattern recognition
- Consider porting key guessit regex patterns

### 10.2 Web Scraping Providers
**Challenge**: HTML parsing without BeautifulSoup
**Solution**:
- Initially skip scraping-based providers
- Later: Use regex for specific patterns
- Or: Bind to a C HTML parser library

### 10.3 Character Encoding
**Challenge**: Detecting subtitle encoding without chardet
**Solution**:
- Default to UTF-8
- Implement BOM detection
- Add basic heuristics for common encodings
- Consider ICU library binding for full support

## 11. Recommended Provider Priority

Based on complexity and usefulness:

1. **Podnapisi** - Simple JSON API, no auth
2. **NapiProjekt** - Hash-based, simple protocol
3. **BSPlayer** - Hash matching, XML but manageable
4. **Gestdown** - Clean REST API for Spanish
5. **OpenSubtitles (XML-RPC)** - Popular but needs auth
6. **OpenSubtitlescom** - Modern API but complex auth
7. *(Skip initially)* Addic7ed, TVsubtitles, Subtitulamos - Web scraping

## 12. Data Structures for Zig

```zig
// Language representation
const Language = struct {
    alpha2: [2]u8,    // ISO 639-1
    alpha3: [3]u8,    // ISO 639-2
    country: ?[2]u8,  // ISO 3166-1
    script: ?[4]u8,   // ISO 15924
};

// Video metadata
const VideoMetadata = struct {
    title: ?[]const u8,
    year: ?u16,
    season: ?u16,
    episode: ?u16,
    release_group: ?[]const u8,
    resolution: ?[]const u8,
    source: ?[]const u8,
};

// Provider interface
const ProviderVTable = struct {
    search: fn(*Provider, Video, []Language) []Subtitle,
    download: fn(*Provider, *Subtitle) Error!void,
    init: fn(*Provider) Error!void,
    deinit: fn(*Provider) void,
};
```

## 13. Configuration Format

Suggest using simple TOML or JSON:
```toml
[general]
languages = ["en", "es"]
providers = ["podnapisi", "opensubtitles"]

[opensubtitles]
username = "user"
password = "pass"

[output]
directory = "."
encoding = "utf-8"
single = false
```

## 14. Error Handling Strategy

```zig
const SubtitleError = error{
    VideoNotFound,
    NoSubtitlesFound,
    ProviderError,
    NetworkError,
    HashingError,
    EncodingError,
    FileSystemError,
};
```

## 15. Testing Strategy

1. **Unit Tests**:
   - Hash calculation
   - Filename parsing
   - Score computation
   - Language handling

2. **Integration Tests**:
   - Provider mocking
   - Full workflow with test videos
   - Configuration loading

3. **Test Data**:
   - Sample video filenames for parsing
   - Mock provider responses
   - Various subtitle encodings

## Conclusion

The Zig port should focus on core functionality with a minimal set of reliable providers. The key is to start simple with hash-based providers and basic filename parsing, then incrementally add complexity. The single-binary requirement aligns well with Zig's compilation model, and most Python dependencies can be replaced with simpler Zig implementations or excluded entirely.

### Estimated Timeline
- **MVP**: 2-3 weeks (basic functionality, 2-3 providers)
- **Production-ready**: 4-5 weeks (5-6 providers, robust error handling)
- **Feature-complete**: 6-8 weeks (most providers, full parsing)

### Success Metrics
- Binary size < 5MB
- Memory usage < 50MB for typical operations  
- Startup time < 100ms
- Subtitle search < 5s for all providers
- Cross-platform compatibility (Linux, macOS, Windows)