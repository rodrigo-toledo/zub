const std = @import("std");

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
    hash: ?[]const u8 = null,
    video_type: ?VideoType = null,
};

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn parseTwoDigits(c1: u8, c2: u8) u16 {
    const d1: u16 = @as(u16, c1 - '0');
    const d2: u16 = @as(u16, c2 - '0');
    return d1 * 10 + d2;
}

fn findSeasonEpisode(s: []const u8) ?struct { season: u16, episode: u16 } {
    var i: usize = 0;
    while (i + 5 < s.len) : (i += 1) {
        const c = s[i];
        if ((c == 'S' or c == 's') and isDigit(s[i + 1]) and isDigit(s[i + 2])) {
            const e = s[i + 3];
            if ((e == 'E' or e == 'e') and isDigit(s[i + 4]) and isDigit(s[i + 5])) {
                const season = parseTwoDigits(s[i + 1], s[i + 2]);
                const episode = parseTwoDigits(s[i + 4], s[i + 5]);
                return .{ .season = season, .episode = episode };
            }
        }
    }
    return null;
}

fn findFirstDot(s: []const u8) ?usize {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] == '.') return i;
    }
    return null;
}

fn findLastDot(s: []const u8) ?usize {
    var i: usize = s.len;
    while (i > 0) {
        i -= 1;
        if (s[i] == '.') return i;
    }
    return null;
}

fn findLastDash(s: []const u8) ?usize {
    var i: usize = s.len;
    while (i > 0) {
        i -= 1;
        if (s[i] == '-') return i;
    }
    return null;
}

fn findYear(s: []const u8) ?u16 {
    var i: usize = 0;
    while (i + 3 < s.len) : (i += 1) {
        const c0 = s[i];
        const c1 = s[i + 1];
        const c2 = s[i + 2];
        const c3 = s[i + 3];
        if (isDigit(c0) and isDigit(c1) and isDigit(c2) and isDigit(c3)) {
            const y: u16 = @as(u16, c0 - '0') * 1000 + @as(u16, c1 - '0') * 100 + @as(u16, c2 - '0') * 10 + @as(u16, c3 - '0');
            if (y >= 1900 and y <= 2100) return y;
        }
    }
    return null;
}

fn findResolution(s: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] == 'p') {
            // walk back over up to 4 digits
            var j: usize = i;
            var digits: usize = 0;
            while (j > 0 and digits < 4 and isDigit(s[j - 1])) {
                j -= 1;
                digits += 1;
            }
            if (digits >= 3 and digits <= 4) {
                return s[j .. i + 1];
            }
        }
    }
    return null;
}

pub fn detectVideoType(filename: []const u8) VideoType {
    if (findSeasonEpisode(filename) != null) return .Episode;
    return .Movie;
}

pub fn parseFilename(allocator: std.mem.Allocator, filename: []const u8) !VideoMetadata {
    _ = allocator; // not needed for these tests; slices reference filename
    var meta: VideoMetadata = .{};

    // Determine video type
    meta.video_type = detectVideoType(filename);

    // Determine series/title from first token
    if (findFirstDot(filename)) |dot| {
        const first = filename[0..dot];
        if (findSeasonEpisode(filename)) |_| {
            meta.series = first;
        } else {
            meta.title = first;
        }
    } else {
        // No dot; treat whole name as title
        meta.title = filename;
    }

    // Season/Episode
    if (findSeasonEpisode(filename)) |se| {
        meta.season = se.season;
        meta.episode = se.episode;
    }

    // Year (likely for movies)
    if (findYear(filename)) |y| {
        meta.year = y;
    }

    // Resolution like 720p, 1080p, 2160p
    if (findResolution(filename)) |res| {
        meta.resolution = res;
    }

    // Release group: last token segment part after last '-' before extension
    const last_dot = findLastDot(filename) orelse filename.len;
    const base = filename[0..last_dot];
    if (findLastDash(base)) |dash| {
        if (dash + 1 < base.len) {
            meta.release_group = base[dash + 1 .. base.len];
        }
    }

    return meta;
}
