const std = @import("std");
const video = @import("video.zig");

test "detectVideoType Episode S01E02" {
    try std.testing.expect(video.detectVideoType("Show.S01E02.720p.x264-GRP.mkv") == .Episode);
}

test "detectVideoType Movie" {
    try std.testing.expect(video.detectVideoType("Inception.2010.1080p.BluRay.x264-GRP.mkv") == .Movie);
}

test "parseFilename episode basic fields" {
    const allocator = std.testing.allocator;
    const meta = try video.parseFilename(allocator, "Show.S01E02.720p.x264-GRP.mkv");
    try std.testing.expectEqual(@as(?u16, 1), meta.season);
    try std.testing.expectEqual(@as(?u16, 2), meta.episode);
    try std.testing.expect(meta.year == null);
    try std.testing.expect(meta.series != null);
    try std.testing.expectEqualStrings("Show", meta.series.?);
    try std.testing.expect(meta.title == null);
    try std.testing.expect(meta.release_group != null);
    try std.testing.expectEqualStrings("GRP", meta.release_group.?);
    try std.testing.expect(meta.resolution != null);
    try std.testing.expectEqualStrings("720p", meta.resolution.?);
}

test "parseFilename movie basic fields" {
    const allocator = std.testing.allocator;
    const meta = try video.parseFilename(allocator, "Inception.2010.1080p.BluRay.x264-GRP.mkv");
    try std.testing.expect(meta.season == null);
    try std.testing.expect(meta.episode == null);
    try std.testing.expectEqual(@as(?u16, 2010), meta.year);
    try std.testing.expect(meta.title != null);
    try std.testing.expectEqualStrings("Inception", meta.title.?);
    try std.testing.expect(meta.release_group != null);
    try std.testing.expectEqualStrings("GRP", meta.release_group.?);
    try std.testing.expect(meta.resolution != null);
    try std.testing.expectEqualStrings("1080p", meta.resolution.?);
}
