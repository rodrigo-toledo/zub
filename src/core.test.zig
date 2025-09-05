const std = @import("std");
const zub = @import("root.zig");
const core = zub.core;
const VideoMetadata = zub.VideoMetadata;
const Subtitle = zub.Subtitle;
const Language = zub.Language;

test "Core selects best subtitle by delegating to scoring engine" {
    const allocator = std.testing.allocator;

    // Create a video metadata representing an episode
    const video = VideoMetadata{
        .title = "Example Show",
        .season = 1,
        .episode = 1,
        .year = 2020,
        .hash = "example_hash",
    };

    // Create two subtitle candidates
    const subtitles = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "test",
            .language = Language.en,
            .series = "Example Show",
            .season = 1,
            .episode = 1,
            .year = 2020,
            .hash = null,
            .title = "Example Show S01E01",
        },
        Subtitle{
            .id = "2",
            .provider_name = "test",
            .language = Language.en,
            .series = "Example Show",
            .season = 1,
            .episode = 1,
            .year = null,
            .hash = "example_hash",
            .title = "Example Show S01E01 Different",
        },
    };

    // Call core.selectBest with a min_score
    const min_score: u32 = 100;
    const result = try core.selectBest(allocator, video, &subtitles, min_score);

    // Should return the subtitle with ID "2" (hash match)
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("2", result.?.id);
}

test "Core returns null when no subtitle meets minimum score" {
    const allocator = std.testing.allocator;

    // Create a video metadata
    const video = VideoMetadata{
        .title = "Another Show",
        .season = 2,
        .episode = 5,
        .year = 2021,
        .hash = "another_hash",
    };

    // Create subtitle candidates that won't meet the minimum score
    const subtitles = [_]Subtitle{
        Subtitle{
            .id = "3",
            .provider_name = "test",
            .language = Language.en,
            .series = "Different Show",
            .season = 1,
            .episode = 1,
            .year = null,
            .hash = null,
            .title = "Unrelated Subtitle",
        },
    };

    // Call core.selectBest with a high min_score
    const min_score: u32 = 9999;
    const result = try core.selectBest(allocator, video, &subtitles, min_score);

    // Should return null since no subtitle meets the minimum score
    try std.testing.expect(result == null);
}
