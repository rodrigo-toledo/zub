const std = @import("std");
const test_allocator = std.testing.allocator;
const zub = @import("zub");
const Subtitle = zub.subtitle.Subtitle;
const VideoMetadata = zub.video.VideoMetadata;
const Language = zub.language.Language;

fn listContains(list: [][]const u8, item: []const u8) bool {
    for (list) |it| {
        if (std.mem.eql(u8, it, item)) return true;
    }
    return false;
}

test "getMatches exact" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .year = 2023,
        .release_group = "GRP",
    };

    var subtitle = Subtitle{
        .id = "1",
        .provider_name = "test",
        .language = Language.en,
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .year = 2023,
        .release_group = "GRP",
    };

    var matches = std.ArrayListUnmanaged([]const u8){};
    defer matches.deinit(test_allocator);

    try subtitle.getMatches(&matches, test_allocator, &video_meta);

    try std.testing.expect(listContains(matches.items, "series"));
    try std.testing.expect(listContains(matches.items, "season"));
    try std.testing.expect(listContains(matches.items, "episode"));
    try std.testing.expect(listContains(matches.items, "year"));
    try std.testing.expect(listContains(matches.items, "release_group"));
}

test "getMatches partial" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
    };

    var subtitle = Subtitle{
        .id = "2",
        .provider_name = "test",
        .language = Language.en,
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .year = 2023,
        .release_group = "GRP",
    };

    var matches = std.ArrayListUnmanaged([]const u8){};
    defer matches.deinit(test_allocator);

    try subtitle.getMatches(&matches, test_allocator, &video_meta);

    try std.testing.expect(listContains(matches.items, "series"));
    try std.testing.expect(listContains(matches.items, "season"));
    try std.testing.expect(listContains(matches.items, "episode"));
    try std.testing.expect(!listContains(matches.items, "year"));
    try std.testing.expect(!listContains(matches.items, "release_group"));
}

test "getMatches with hash" {
    var video_meta = VideoMetadata{
        .hash = "0123456789abcdef",
    };

    var subtitle = Subtitle{
        .id = "3",
        .provider_name = "test",
        .language = Language.en,
        .hash = "0123456789abcdef",
        .series = "The.Show",
        .season = 1,
    };

    var matches = std.ArrayListUnmanaged([]const u8){};
    defer matches.deinit(test_allocator);

    try subtitle.getMatches(&matches, test_allocator, &video_meta);

    try std.testing.expect(listContains(matches.items, "hash"));
    // Other metadata should not match if not present in video
    try std.testing.expect(!listContains(matches.items, "series"));
}
