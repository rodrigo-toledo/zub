
# Subliminal Zig Port - Incremental Implementation Plan

## Overview

This document provides a detailed, step-by-step implementation plan for porting Subliminal from Python to Zig. The plan is designed to deliver a working MVP quickly while maintaining extensibility for future enhancements.

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

## Phase 1: Foundation (Week 1)

### Day 1-2: Project Setup & Basic Structures

**File: `build.zig`**
```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("subliminal", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const test_step = b.step("test", "Run unit tests");
    const tests = b.addTest("src/main.zig");
    tests.setTarget(target);
    tests.setBuildMode(mode);
    test_step.dependOn(&tests.step);
}
```

**File: `src/language.zig`**
```zig
const std = @import("std");

pub const Language = struct {
    alpha2: [2]u8,
    alpha3: [3]u8,
    country: ?[2]u8 = null,
    name: []const u8,

    pub fn fromCode(code: []const u8) !Language {
        // Basic ISO 639-1/2 mappings
        if (std.mem.eql(u8, code, "en")) {
            return Language{
                .alpha2 = "en".*,
                .alpha3 = "eng".*,
                .name = "English",
            };
        } else if (std.mem.eql(u8, code, "es")) {
            return Language{
                .alpha2 = "es".*,
                .alpha3 = "spa".*,
                .name = "Spanish",
            };
        }
        // Add more languages
        return error.UnknownLanguage;
    }

    pub fn toString(self: Language) []const u8 {
        return &self.alpha2;
    }
};
```

**File: `src/video.zig`**
```zig
const std = @import("std");
const Language = @import("language.zig").Language;

pub const VideoType = enum {
    Movie,
    Episode,
};

pub const VideoMetadata = struct {
    title: ?[]const u8 = null,
    series: ?[]const u8 = null,
    season: ?u16 = null,
    episode: ?u16 = null,
    year: ?u16 = null,
    release_group: ?[]const u8 = null,
    resolution: ?[]const u8 = null,
    video_codec: ?[]const u8 = null,
    audio_codec: ?[]const u8 = null,
};

pub const Video = struct {
    path: []const u8,
    name: []const u8,
    size: u64,
    video_type: VideoType,
    metadata: VideoMetadata,
    hash: ?[]const u8 = null,
    existing_subtitles: std.ArrayList(Language),

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !Video {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        
        const stat = try file.stat();
        const name = std.fs.path.basename(path);
        
        return Video{
            .path = path,
            .name = name,
            .size = stat.size,
            .video_type = detectVideoType(name),
            .metadata = try parseFilename(allocator, name),
            .existing_subtitles = std.ArrayList(Language).init(allocator),
        };
    }

    fn detectVideoType(filename: []const u8) VideoType {
        // Simple detection based on S##E## pattern
        if (std.mem.indexOf(u8, filename, "S") != null and
            std.mem.indexOf(u8, filename, "E") != null) {
            return .Episode;
        }
        return .Movie;
    }

    fn parseFilename(allocator: std.mem.Allocator, filename: []const u8) !VideoMetadata {
        _ = allocator;
        // Basic regex patterns for common formats
        var metadata = VideoMetadata{};
        
        // Extract year (4 digits in parentheses or standalone)
        // Extract resolution (720p, 1080p, etc.)
        // Extract release group (text after - at end)
        // TODO: Implement actual parsing
        
        return metadata;
    }
};
```

### Day 3-4: Hashing Implementation

**File: `src/hash.zig`**
```zig
const std = @import("std");

pub const HashType = enum {
    OpenSubtitles,
    BSPlayer,
    NapiProjekt,
};

/// OpenSubtitles hash algorithm
/// Hash = filesize + 64bit sum of first and last 64KB
pub fn computeOpenSubtitlesHash(path: []const u8) ![16]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    const file_size = try file.getEndPos();
    if (file_size < 65536 * 2) {
        return error.FileTooSmall;
    }
    
    var hash: u64 = file_size;
    var buffer: [8]u8 = undefined;
    
    // Process first 64KB
    try file.seekTo(0);
    var bytes_read: usize = 0;
    while (bytes_read < 65536) : (bytes_read += 8) {
        _ = try file.read(&buffer);
        hash +%= std.mem.readIntLittle(u64, &buffer);
    }
    
    // Process last 64KB
    try file.seekTo(file_size - 65536);
    bytes_read = 0;
    while (bytes_read < 65536) : (bytes_read += 8) {
        _ = try file.read(&buffer);
        hash +%= std.mem.readIntLittle(u64, &buffer);
    }
    
    var result: [16]u8 = undefined;
    _ = try std.fmt.bufPrint(&result, "{x:0>16}", .{hash});
    return result;
}

/// NapiProjekt hash - MD5 of first 10MB
pub fn computeNapiProjektHash(path: []const u8, allocator: std.mem.Allocator) ![32]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    const read_size = std.math.min(try file.getEndPos(), 10 * 1024 * 1024);
    const buffer = try allocator.alloc(u8, read_size);
    defer allocator.free(buffer);
    
    _ = try file.read(buffer);
    
    var hash: [16]u8 = undefined;
    std.crypto.hash.Md5.hash(buffer, &hash, .{});
    
    var result: [32]u8 = undefined;
    _ = try std.fmt.bufPrint(&result, "{}", .{std.fmt.fmtSliceHexLower(&hash)});
    return result;
}
```

### Day 5: Subtitle Structure

**File: `src/subtitle.zig`**
```zig
const std = @import("std");
const Language = @import("language.zig").Language;
const Video = @import("video.zig").Video;

pub const SubtitleFormat = enum {
    SRT,
    ASS,
    SSA,
    SUB,
    VTT,
};

pub const Subtitle = struct {
    id: []const u8,
    provider_name: []const u8,
    language: Language,
    hearing_impaired: bool = false,
    format: SubtitleFormat = .SRT,
    score: u32 = 0,
    content: ?[]const u8 = null,
    download_url: ?[]const u8 = null,
    
    // Metadata for scoring
    release_group: ?[]const u8 = null,
    fps: ?f32 = null,
    year: ?u16 = null,
    season: ?u16 = null,
    episode: ?u16 = null,
    title: ?[]const u8 = null,

    pub fn getMatches(self: *const Subtitle, video: *const Video) std.ArrayList([]const u8) {
        var matches = std.ArrayList([]const u8).init(std.heap.page_allocator);
        
        // Check hash match
        if (video.hash != null and self.hash != null) {
            if (std.mem.eql(u8, video.hash.?, self.hash.?)) {
                matches.append("hash") catch {};
            }
        }
        
        // Check metadata matches
        if (self.release_group != null and video.metadata.release_group != null) {
            if (std.mem.eql(u8, self.release_group.?, video.metadata.release_group.?)) {
                matches.append("release_group") catch {};
            }
        }
        
        // Add more match checks
        
        return matches;
    }
};
```

## Phase 2: Provider System (Week 2)

### Day 6-7: Provider Interface & HTTP Client

**File: `src/providers/provider.zig`**
```zig
const std = @import("std");
const Video = @import("../video.zig").Video;
const Subtitle = @import("../subtitle.zig").Subtitle;
const Language = @import("../language.zig").Language;

pub const ProviderError = error{
    AuthenticationFailed,
    NetworkError,
    ParseError,
    RateLimited,
    ServerError,
};

pub const Provider = struct {
    name: []const u8,
    allocator: std.mem.Allocator,
    
    // Virtual table for provider methods
    vtable: *const VTable,
    
    pub const VTable = struct {
        init: fn (self: *Provider) ProviderError!void,
        deinit: fn (self: *Provider) void,
        search: fn (self: *Provider, video: *const Video, languages: []const Language) ProviderError![]Subtitle,
        download: fn (self: *Provider, subtitle: *Subtitle) ProviderError!void,
    };
    
    pub fn init(self: *Provider) !void {
        return self.vtable.init(self);
    }
    
    pub fn search(self: *Provider, video: *const Video, languages: []const Language) ![]Subtitle {
        return self.vtable.search(self, video, languages);
    }
    
    pub fn download(self: *Provider, subtitle: *Subtitle) !void {
        return self.vtable.download(self, subtitle);
    }
};
```

**File: `src/utils/http.zig`**
```zig
const std = @import("std");

pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) HttpClient {
        return .{ .allocator = allocator };
    }
    
    pub fn get(self: *HttpClient, url: []const u8) ![]u8 {
        // Simple HTTP GET implementation
        // For MVP, use std.ChildProcess to call curl
        const result = try std.ChildProcess.exec(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "curl", "-s", url },
        });
        
        if (result.term.Exited != 0) {
            return error.HttpError;
        }
        
        return result.stdout;
    }
    
    pub fn post(self: *HttpClient, url: []const u8, data: []const u8) ![]u8 {
        const result = try std.ChildProcess.exec(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ 
                "curl", "-s", "-X", "POST", 
                "-H", "Content-Type: application/json",
                "-d", data, url 
            },
        });
        
        if (result.term.Exited != 0) {
            return error.HttpError;
        }
        
        return result.stdout;
    }
};
```

### Day 8-9: First Provider - Podnapisi

**File: `src/providers/podnapisi.zig`**
```zig
const std = @import("std");
const Provider = @import("provider.zig").Provider;
const Video = @import("../video.zig").Video;
const Subtitle = @import("../subtitle.zig").Subtitle;
const Language = @import("../language.zig").Language;
const HttpClient = @import("../utils/http.zig").HttpClient;

pub const PodnapisiProvider = struct {
    base: Provider,
    http_client: HttpClient,
    
    const SERVER_URL = "https://www.podnapisi.net/subtitles";
    
    const vtable = Provider.VTable{
        .init = init,
        .deinit = deinit,
        .search = search,
        .download = download,
    };
    
    pub fn create(allocator: std.mem.Allocator) !*PodnapisiProvider {
        var self = try allocator.create(PodnapisiProvider);
        self.* = .{
            .base = .{
                .name = "podnapisi",
                .allocator = allocator,
                .vtable = &vtable,
            },
            .http_client = HttpClient.init(allocator),
        };
        return self;
    }
    
    fn init(base: *Provider) !void {
        _ = base;
        // No initialization needed
    }
    
    fn deinit(base: *Provider) void {
        _ = base;
        // Cleanup
    }
    
    fn search(base: *Provider, video: *const Video, languages: []const Language) ![]Subtitle {
        const self = @fieldParentPtr(PodnapisiProvider, "base", base);
        
        var subtitles = std.ArrayList(Subtitle).init(self.base.allocator);
        
        for (languages) |lang| {
            const query = try buildQuery(self.base.allocator, video, lang);
            defer self.base.allocator.free(query);
            
            const url = try std.fmt.allocPrint(
                self.base.allocator,
                "{s}/search/advanced?{s}",
                .{ SERVER_URL, query }
            );
            defer self.base.allocator.free(url);
            
            const response = try self.http_client.get(url);
            defer self.base.allocator.free(response);
            
            // Parse JSON response
            const parsed = try std.json.parse(
                PodnapisiResponse,
                &std.json.TokenStream.init(response),
                .{ .allocator = self.base.allocator }
            );
            defer std.json.parseFree(PodnapisiResponse, parsed, .{ .allocator = self.base.allocator });
            
            // Convert to Subtitle structs
            for (parsed.data) |item| {
                try subtitles.append(Subtitle{
                    .id = item.id,
                    .provider_name = "podnapisi",
                    .language = lang,
                    .hearing_impaired = item.hearing_impaired,
                    .download_url = item.url,
                    .release_group = item.releases,
                    .title = item.movie.title,
                    .year = item.movie.year,
                });
            }
        }
        
        return subtitles.toOwnedSlice();
    }
    
    fn download(base: *Provider, subtitle: *Subtitle) !void {
        const self = @fieldParentPtr(PodnapisiProvider, "base", base);
        
        if (subtitle.download_url) |url| {
            const download_url = try std.fmt.allocPrint(
                self.base.allocator,
                "{s}/{s}/download?container=srt",
                .{ SERVER_URL, subtitle.id }
            );
            defer self.base.allocator.free(download_url);
            
            const content = try self.http_client.get(download_url);
            subtitle.content = content;
        }
    }
    
    fn buildQuery(allocator: std.mem.Allocator, video: *const Video, language: Language) ![]u8 {
        // Build URL query parameters
        var params = std.ArrayList(u8).init(allocator);
        
        // Add keywords
        if (video.metadata.title) |title| {
            try params.appendSlice("keywords=");
            try params.appendSlice(title);
        }
        
        // Add language
        try params.appendSlice("&language=");
        try params.appendSlice(language.toString());
        
        // Add year if available
        if (video.metadata.year) |year| {
            try std.fmt.format(params.writer(), "&year={d}", .{year});
        }
        
        return params.toOwnedSlice();
    }
    
    const PodnapisiResponse = struct {
        data: []struct {
            id: []const u8,
            url: []const u8,
            hearing_impaired: bool,
            releases: []const u8,
            movie: struct {
                title: []const u8,
                year: u16,
            },
        },
    };
};
```

## Phase 3: Scoring & CLI (Week 3)

### Day 10-11: Scoring Engine

**File: `src/score.zig`**
```zig
const std = @import("std");
const Video = @import("video.zig").Video;
const Subtitle = @import("subtitle.zig").Subtitle;

pub const Scores = struct {
    // Episode scores
    const episode = .{
        .hash = 971,
        .series = 486,
        .year = 162,
        .country = 162,
        .season = 54,
        .episode = 54,
        .release_group = 18,
        .fps = 9,
        .source = 4,
        .audio_codec = 2,
        .resolution = 1,
        .video_codec = 1,
    };
    
    // Movie scores
    const movie = .{
        .hash = 323,
        .title = 162,
        .year = 54,
        .country = 54,
        .release_group = 18,
        .fps = 9,
        .source = 4,
        .audio_codec = 2,
        .resolution = 1,
        .video_codec = 1,
    };
};

pub fn computeScore(subtitle: *const Subtitle, video: *const Video) u32 {
    var score: u32 = 0;
    const matches = subtitle.getMatches(video);
    defer matches.deinit();
    
    // Get appropriate score table
    const scores = switch (video.video_type) {
        .Episode => Scores.episode,
        .Movie => Scores.movie,
    };
    
    // Special case: hash match overrides everything
    for (matches.items) |match| {
        if (std.mem.eql(u8, match, "hash")) {
            return scores.hash;
        }
    }
    
    // Calculate score from matches
    for (matches.items) |match| {
        if (std.mem.eql(u8, match, "release_group")) {
            score += scores.release_group;
        } else if (std.mem.eql(u8, match, "year")) {
            score += scores.year;
        }
        // Add more match types
    }
    
    return score;
}

pub fn selectBestSubtitle(subtitles: []Subtitle, video: *const Video, min_score: u32) ?*Subtitle {
    var best: ?*Subtitle = null;
    var best_score: u32 = min_score;
    
    for (subtitles) |*subtitle| {
        const score = computeScore(subtitle, video);
        subtitle.score = score;
        
        if (score > best_score) {
            best = subtitle;
            best_score = score;
        }
    }
    
    return best;
}
```

### Day 12-14: CLI Implementation

**File: `src/main.zig`**
```zig
const std = @import("std");
const Video = @import("video.zig").Video;
const Language = @import("language.zig").Language;
const core = @import("core.zig");

const Args = struct {
    path: []const u8,
    languages: []Language,
    providers: [][]const u8,
    min_score: u32 = 0,
    force: bool = false,
    single: bool = false,
    directory: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Parse arguments
    const args = try parseArgs(allocator);
    defer args.deinit();
    
    // Print version and info
    std.debug.print("Subliminal-zig v0.1.0\n", .{});
    
    // Scan video
    std.debug.print("Scanning video: {s}\n", .{args.path});
    const video = try Video.init(allocator, args.path);
    defer video.deinit();
    
    // Compute hash
    std.debug.print("Computing hash...\n", .{});
    video.hash = try computeHash(allocator, args.path);
    
    // Search subtitles
    std.debug.print("Searching subtitles...\n", .{});
    const subtitles = try core.searchSubtitles(
        allocator,
        &video,
        args.languages,
        args.providers
    );
    defer allocator.free(subtitles);
    
    if (subtitles.len == 0) {
        std.debug.print("No subtitles found.\n", .{});
        return;
    }
    
    std.debug.print("Found {d} subtitles\n", .{subtitles.len});
    
    // Select best subtitle
    const best = core.selectBestSubtitle(subtitles, &video, args.min_score);
    if (best == null) {
        std.debug.print("No subtitle meets minimum score requirement.\n", .{});
        return;
    }
    
    std.debug.print("Best subtitle score: {d}\n", .{best.?.score});
    
    // Download subtitle
    std.debug.print("Downloading subtitle...\n", .{});
    try core.downloadSubtitle(allocator, best.?);
    
    // Save subtitle
    const save_path = try buildSubtitlePath(
        allocator,
        &video,
        best.?,
        args.directory,
        args.single
    );
    defer allocator.free(save_path);
    
    std.debug.print("Saving to: {s}\n", .{save_path});
    try saveSubtitle(best.?, save_path);
    
    std.debug.print("Done!\n", .{});
}

fn parseArgs(allocator: std.mem.Allocator) !Args {
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);
    
    if (argv.len < 3) {
        printUsage();
        std.process.exit(1);
    }
    
    var args = Args{
        .path = argv[1],
        .languages = undefined,
        .providers = &[_][]const u8{"podnapisi"},
    };
    
    // Parse language codes
    var languages = std.ArrayList(Language).init(allocator);
    const lang_str = argv[2];
    var it = std.mem.tokenize(u8, lang_str, ",");
    while (it.next()) |code| {
        const lang = try Language.fromCode(code);
        try languages.append(lang);
    }
    args.languages = try languages.toOwnedSlice();
    
    // Parse optional arguments
    var i: usize = 3;
    while (i < argv.len) : (i += 1) {
        if (std.mem.eql(u8, argv[i], "--force")) {
            args.force = true;
        } else if (std.mem.eql(u8, argv[i], "--single")) {
            args.single = true;
        } else if (std.mem.eql(u8, argv[i], "--min-score") and i + 1 < argv.len) {
            args.min_score = try std.fmt.parseInt(u32, argv[i + 1], 10);
            i += 1;
        }
    }
    
    return args;
}

fn printUsage() void {
    std.debug.print(
        \\Usage: subliminal <video_file> <languages> [options]
        \\
        \\Arguments:
        \\  video_file    Path to the video file
        \\  languages     Comma-separated language codes (e.g., en,es)
        \\
        \\Options:
        \\  --force       Force download even if subtitle exists
        \\  --single      Save subtitle without language suffix
        \\  --min-score N Minimum score required for download
        \\  --providers P Comma-separated provider names
        \\
    , .{});
}

fn saveSubtitle(subtitle: *const Subtitle, path: []const u8) !void {
    if (subtitle.content) |content| {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writeAll(content);
    }
}

fn buildSubtitlePath(
    allocator: std.mem.Allocator,
    video: *const Video,
    subtitle: *const Subtitle,
    directory: ?[]const u8,
    single: bool,
) ![]u8 {
    const dir = directory orelse std.fs.path.dirname(video.path) orelse ".";
    const basename = std.fs.path.basename(video.name);
    
    // Remove extension from basename
    const name = if (std.mem.lastIndexOf(u8, basename, ".")) |pos|
        basename[0..pos]
    else
        basename;
    
    if (single) {
        return try std.fmt.allocPrint(allocator, "{s}/{s}.srt", .{ dir, name });
    } else {
        return try std.fmt.allocPrint(
            allocator,
            "{s}/{s}.{s}.srt",
            .{ dir, name, subtitle.language.toString() }
        );
    }
}
```

## Phase 4: Additional Providers (Week 4)

### Day 15-16: NapiProjekt Provider

```zig
// Implementation for NapiProjekt (hash-based, simple)
```

### Day 17-18: BSPlayer Provider

```zig
// Implementation for BSPlayer (XML-based)
```

### Day 19-20: Testing & Refinement

```zig
// Unit tests and integration tests
```

## Testing Strategy

### Unit Tests

**File: `tests/hash_test.zig`**
```zig
test "OpenSubtitles hash calculation" {
    const hash = try computeOpenSubtitlesHash("test_video.mp4");
    try std.testing.expectEqualStrings(&hash, "expected_hash_value");
}
```

### Integration Tests

```zig
test "Full subtitle download workflow" {
    // Test complete flow from video scan to subtitle save
}
```

## Build Commands

```bash
# Build debug version
zig build

# Build release version
zig build -Drelease-safe

# Run tests
zig build test

# Cross-compile for different platforms
zig build -Dtarget=x86_64-windows
zig build -Dtarget=x86_64-linux
zig build -Dtarget=aarch64-macos
```

## Milestones

### MVP (End of Week 2)
- [x] Basic video detection
- [x] OpenSubtitles hash
- [x] Podnapisi provider
- [x] Simple CLI
- [x] SRT format support

### Beta (End of Week 3)
- [ ] 3 working providers
- [ ] Scoring algorithm
- [ ] Configuration file support
- [ ] Better filename parsing

### Release (End of Week 4)
- [ ] 5+ providers
- [ ] Robust error handling
- [ ] Cross-platform builds
- [ ] Documentation

## Key Decisions

1. **HTTP Client**: Start with curl subprocess, later implement native HTTP
2. **XML Parsing**: Use simple regex initially, consider C library binding later
3. **Configuration**: TOML format for simplicity
4. **Provider Priority**: Focus on JSON/simple APIs first
5. **Error Handling**: Use Zig's error unions throughout

## Performance Goals

- Binary size: < 5MB
- Memory usage: < 50MB
- Startup time: < 100ms
- Search time: < 5s for all providers
- Zero runtime dependencies (statically linked)

## Future Enhancements

1. **Advanced Parsing**: Port key guessit patterns
3. **Encoding Detection**: ICU library integration
4. **Archive Support**: RAR/ZIP file scanning
5. **Subtitle Format Conversion**: Multiple format support
6. **Web Scraping Providers**: Addic7ed, TVsubtitles implementation

## Configuration System

### TOML Configuration Format

**File: `config.toml`**
```toml
[general]
# Default languages for subtitle search
languages = ["en", "es", "fr"]

# Minimum score for subtitle download (0-100)
min_score = 0

# Save subtitle without language suffix
single = false

# Force download even if subtitle exists
force = false

[providers]
# List of enabled providers
enabled = ["podnapisi", "opensubtitles", "napiprojekt"]

# Provider-specific settings
[providers.opensubtitles]
username = "your_username"
password = "your_password"
vip = false

[providers.opensubtitlescom]
username = "your_username"
password = "your_password"
apikey = ""

[output]
# Directory for saving subtitles
directory = ""

# Force subtitle encoding
encoding = "utf-8"

# Force subtitle format
format = "srt"

# Add language type suffix (.hi, .foreign)
language_type_suffix = false

[cache]
# Enable caching of provider responses
enabled = true

# Cache directory
directory = "~/.cache/subliminal-zig"

# Cache expiration in hours
expiration = 720
```

## Error Handling Guidelines

```zig
pub const SubtitleError = error{
    // File system errors
    VideoNotFound,
    PermissionDenied,
    FileSystemError,
    
    // Network errors
    NetworkTimeout,
    NetworkError,
    ServerError,
    
    // Provider errors
    AuthenticationFailed,
    RateLimited,
    ProviderError,
    NoSubtitlesFound,
    
    // Processing errors
    HashingError,
    ParseError,
    EncodingError,
    InvalidFormat,
};

fn handleError(err: SubtitleError) void {
    switch (err) {
        .VideoNotFound => std.debug.print("Error: Video file not found\n", .{}),
        .AuthenticationFailed => std.debug.print("Error: Authentication failed\n", .{}),
        .NetworkTimeout => std.debug.print("Error: Network timeout\n", .{}),
        else => std.debug.print("Error: {}\n", .{err}),
    }
}
```

## Platform-Specific Considerations

### Windows
- File path handling with backslashes
- Windows-1252 encoding support
- Handle locked files gracefully

### macOS
- Handle .DS_Store files
- Support for extended attributes
- Sandbox considerations for App Store

### Linux
- Handle different file systems (ext4, btrfs, etc.)
- Respect XDG base directories
- Package manager integration considerations

## Optimization Opportunities

1. **Parallel Provider Queries**: Query multiple providers concurrently
2. **Connection Pooling**: Reuse HTTP connections
3. **Memory Pool**: Pre-allocate memory for subtitle structures
4. **Hash Caching**: Cache computed hashes
5. **Lazy Loading**: Load provider modules on demand

## Documentation Requirements

### User Documentation
- Installation guide
- Quick start tutorial
- Provider configuration guide
- Troubleshooting section

### Developer Documentation
- API reference
- Provider implementation guide
- Contributing guidelines
- Architecture overview

## Release Checklist

### Pre-release
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Cross-platform builds tested

### Release
- [ ] Tag version in git
- [ ] Build binaries for all platforms
- [ ] Create GitHub release
- [ ] Update package managers
- [ ] Announce on forums/social media

### Post-release
- [ ] Monitor issue tracker
- [ ] Gather user feedback
- [ ] Plan next iteration

## Success Metrics

### Technical Metrics
- **Binary size**: < 5MB achieved
- **Memory usage**: < 50MB for typical operation
- **Startup time**: < 100ms cold start
- **Search time**: < 5s for 3 providers
- **Test coverage**: > 80%

### User Metrics
- **Download success rate**: > 90%
- **Subtitle match accuracy**: > 85%
- **Cross-platform compatibility**: 100%
- **User satisfaction**: > 4.5/5 stars

## Risk Mitigation

### Technical Risks
1. **Provider API changes**: Implement version detection and fallbacks
2. **Network failures**: Implement retry logic with exponential backoff
3. **File corruption**: Validate downloads before saving
4. **Memory leaks**: Use Zig's allocator tracking in debug builds

### Legal Risks
1. **API Terms of Service**: Respect rate limits and usage terms
2. **Copyright concerns**: Only download subtitles for owned content
3. **User data**: No telemetry or data collection

## Conclusion

This implementation plan provides a clear roadmap for porting Subliminal to Zig. The incremental approach ensures quick delivery of a working MVP while maintaining flexibility for future enhancements. The focus on simplicity, performance, and cross-platform compatibility aligns perfectly with Zig's strengths.

### Key Takeaways
1. Start with simple providers and basic functionality
2. Prioritize hash-based matching for accuracy
3. Keep dependencies minimal for single-binary distribution
4. Use Zig's compile-time features for optimization
5. Maintain clean separation between providers

### Next Steps
1. Set up development environment
2. Create project structure
3. Implement basic video scanning
4. Add first provider (Podnapisi)
5. Build MVP CLI interface

With this plan, a functional subtitle downloader can be delivered in 2-3 weeks, with a production-ready version achievable in 4-5 weeks.
2. **More Providers**: OpenSubtitles.com REST API
