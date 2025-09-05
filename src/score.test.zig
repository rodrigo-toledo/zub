const std = @import("std");
const test_allocator = std.testing.allocator;
const zub = @import("zub");
const VideoMetadata = zub.VideoMetadata;
const Subtitle = zub.Subtitle;
const Language = zub.Language;

// Import the score module (will fail until implemented)
const score = zub.score;

test "computeScore returns 0 for empty matches" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .video_type = .Episode,
    };

    var subtitle = Subtitle{
        .id = "1",
        .provider_name = "test",
        .language = Language.en,
        .series = "Different.Show",
        .season = 2,
        .episode = 3,
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    try std.testing.expectEqual(@as(u32, 0), computed_score);
}

test "computeScore calculates correct score for episode with hash match" {
    var video_meta = VideoMetadata{
        .hash = "0123456789abcdef",
        .video_type = .Episode,
    };

    var subtitle = Subtitle{
        .id = "2",
        .provider_name = "test",
        .language = Language.en,
        .hash = "0123456789abcdef",
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    // According to the implementation plan, hash score for episodes is 971
    try std.testing.expectEqual(@as(u32, 971), computed_score);
}

test "computeScore calculates correct score for movie with hash match" {
    var video_meta = VideoMetadata{
        .hash = "0123456789abcdef",
        .video_type = .Movie,
    };

    var subtitle = Subtitle{
        .id = "5",
        .provider_name = "test",
        .language = Language.en,
        .hash = "0123456789abcdef",
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    // According to the implementation plan, hash score for movies is 323
    try std.testing.expectEqual(@as(u32, 323), computed_score);
}

test "computeScore calculates correct score for episode with series match" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .video_type = .Episode,
    };

    var subtitle = Subtitle{
        .id = "3",
        .provider_name = "test",
        .language = Language.en,
        .series = "The.Show",
        .season = 2,
        .episode = 3,
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    // According to the implementation plan, series score for episodes is 486
    try std.testing.expectEqual(@as(u32, 486), computed_score);
}

test "computeScore calculates correct score for episode with multiple matches" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .year = 2023,
        .video_type = .Episode,
    };

    var subtitle = Subtitle{
        .id = "4",
        .provider_name = "test",
        .language = Language.en,
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .year = 2023,
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    // Series (486) + Season (54) + Episode (54) + Year (162) = 756
    try std.testing.expectEqual(@as(u32, 756), computed_score);
}

test "computeScore calculates correct score for movie with title match" {
    var video_meta = VideoMetadata{
        .title = "The Movie",
        .video_type = .Movie,
    };

    var subtitle = Subtitle{
        .id = "6",
        .provider_name = "test",
        .language = Language.en,
        .title = "The Movie",
    };

    const computed_score = score.computeScore(&subtitle, &video_meta);
    // According to the implementation plan, title score for movies is 162
    try std.testing.expectEqual(@as(u32, 162), computed_score);
}

test "selectBestSubtitle returns null when no subtitles meet minimum score" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .video_type = .Episode,
    };

    var subtitles = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "test",
            .language = Language.en,
            .series = "Different.Show",
            .season = 1,
            .episode = 2,
        },
        Subtitle{
            .id = "2",
            .provider_name = "test",
            .language = Language.en,
            .series = "Another.Show",
            .season = 1,
            .episode = 2,
        },
    };

    const best = score.selectBestSubtitle(&subtitles, &video_meta, 500);
    try std.testing.expect(best == null);
}

test "selectBestSubtitle returns best matching subtitle" {
    var video_meta = VideoMetadata{
        .series = "The.Show",
        .season = 1,
        .episode = 2,
        .video_type = .Episode,
    };

    var subtitles = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "test",
            .language = Language.en,
            .series = "Different.Show",
            .season = 1,
            .episode = 2,
        },
        Subtitle{
            .id = "2",
            .provider_name = "test",
            .language = Language.en,
            .series = "The.Show",
            .season = 1,
            .episode = 2,
        },
    };

    const best = score.selectBestSubtitle(&subtitles, &video_meta, 0);
    try std.testing.expect(best != null);
    try std.testing.expectEqualStrings("2", best.?.id);
}
