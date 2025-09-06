const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const zub = @import("root.zig");
const VideoMetadata = zub.VideoMetadata;
const Subtitle = zub.Subtitle;
const Language = zub.Language;
const Provider = zub.Provider;
const score = zub.score;
const core = zub.core;
const MockProvider = zub.MockProvider;

// Test finding subtitles using multiple providers simultaneously
test "Finding subtitles using multiple providers simultaneously" {
    const allocator = testing.allocator;

    // Create mock subtitles from different providers
    const subtitles_provider1 = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "provider1",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Friends",
            .season = 1,
            .episode = 1,
            .title = null,
            .year = 1994,
            .release_group = null,
            .fps = null,
            .hash = "abc123def456",
        },
    };

    const subtitles_provider2 = [_]Subtitle{
        Subtitle{
            .id = "2",
            .provider_name = "provider2",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Friends",
            .season = 1,
            .episode = 1,
            .title = null,
            .year = 1994,
            .release_group = null,
            .fps = null,
            .hash = null,
        },
        Subtitle{
            .id = "3",
            .provider_name = "provider2",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Different Show",
            .season = 2,
            .episode = 5,
            .title = null,
            .year = 2020,
            .release_group = null,
            .fps = null,
            .hash = null,
        },
    };

    // Initialize mock providers with subtitles
    const provider1 = MockProvider.initWithSubtitles(allocator, "provider1", &subtitles_provider1);

    const provider2 = MockProvider.initWithSubtitles(allocator, "provider2", &subtitles_provider2);

    // Create a test video metadata
    const video_meta = VideoMetadata{
        .title = null,
        .series = "Friends",
        .season = 1,
        .episode = 1,
        .year = 1994,
        .release_group = null,
        .resolution = null,
        .hash = "abc123def456",
        .video_type = .Episode,
    };

    // Search for subtitles using both providers
    const results1 = try provider1.search(video_meta);
    defer allocator.free(results1);

    const results2 = try provider2.search(video_meta);
    defer allocator.free(results2);

    // Combine results from both providers
    var all_subtitles = try allocator.alloc(Subtitle, results1.len + results2.len);
    defer allocator.free(all_subtitles);

    // Copy subtitles from first provider
    for (results1, 0..) |subtitle, i| {
        all_subtitles[i] = subtitle;
    }

    // Copy subtitles from second provider
    for (results2, 0..) |subtitle, i| {
        all_subtitles[results1.len + i] = subtitle;
    }

    // Verify that we collected subtitles from multiple sources
    try testing.expect(all_subtitles.len == 3);
    try testing.expectEqualStrings("provider1", all_subtitles[0].provider_name);
    try testing.expectEqualStrings("provider2", all_subtitles[1].provider_name);
    try testing.expectEqualStrings("provider2", all_subtitles[2].provider_name);
}

// Test proper scoring and ranking of results from different providers
test "Proper scoring and ranking of results from different providers" {
    const allocator = testing.allocator;

    // Create a test video metadata for a movie
    const video_meta = VideoMetadata{
        .title = "Inception",
        .series = null,
        .season = null,
        .episode = null,
        .year = 2010,
        .release_group = null,
        .resolution = null,
        .hash = "xyz789uvw012",
        .video_type = .Movie,
    };

    // Create mock subtitles with different scores
    const subtitles = [_]Subtitle{
        // Best match - hash match
        Subtitle{
            .id = "1",
            .provider_name = "provider1",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = null,
            .season = null,
            .episode = null,
            .title = "Inception",
            .year = 2010,
            .release_group = null,
            .fps = null,
            .hash = "xyz789uvw012", // Hash match
        },
        // Good match - title and year match
        Subtitle{
            .id = "2",
            .provider_name = "provider2",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = null,
            .season = null,
            .episode = null,
            .title = "Inception",
            .year = 2010,
            .release_group = null,
            .fps = null,
            .hash = "different_hash",
        },
        // Poor match - only title matches
        Subtitle{
            .id = "3",
            .provider_name = "provider3",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = null,
            .season = null,
            .episode = null,
            .title = "Inception",
            .year = 2000, // Wrong year
            .release_group = null,
            .fps = null,
            .hash = "another_hash",
        },
    };

    // Compute scores for each subtitle
    var scored_subtitles = try allocator.alloc(Subtitle, subtitles.len);
    defer allocator.free(scored_subtitles);

    for (subtitles, 0..) |subtitle, i| {
        scored_subtitles[i] = subtitle;
        scored_subtitles[i].score = score.computeScore(&scored_subtitles[i], &video_meta);
    }

    // Verify scoring is working correctly
    // Hash match should have highest score (MOVIE_WEIGHT_HASH = 323)
    try testing.expect(scored_subtitles[0].score > scored_subtitles[1].score);
    try testing.expect(scored_subtitles[1].score > scored_subtitles[2].score);

    // Use core.selectBest to select the best subtitle
    const min_score: u32 = 10;
    const best_subtitle = try core.selectBest(allocator, video_meta, scored_subtitles, min_score);

    // Should select the first subtitle (hash match)
    try testing.expect(best_subtitle != null);
    try testing.expectEqualStrings("1", best_subtitle.?.id);
}

// Test handling missing/incomplete video metadata
test "Handling missing/incomplete video metadata" {
    const allocator = testing.allocator;

    // Create a test video metadata with missing fields
    const video_meta = VideoMetadata{
        .title = null,
        .series = null,
        .season = null,
        .episode = null,
        .year = null,
        .release_group = null,
        .resolution = null,
        .hash = null,
        .video_type = null, // Missing video type
    };

    // Create mock subtitles
    const subtitles = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "provider1",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = null,
            .season = null,
            .episode = null,
            .title = "Some Movie",
            .year = 2020,
            .release_group = null,
            .fps = null,
            .hash = null,
        },
    };

    // Compute scores - should handle missing metadata gracefully
    var scored_subtitle = subtitles[0];
    scored_subtitle.score = score.computeScore(&scored_subtitle, &video_meta);

    // With no matching metadata, score should be 0
    try testing.expect(scored_subtitle.score == 0);

    // Try to select best subtitle with a minimum score
    const min_score: u32 = 100;
    const best_subtitle = try core.selectBest(allocator, video_meta, &subtitles, min_score);

    // Should return null since no subtitle meets minimum score
    try testing.expect(best_subtitle == null);
}

// Test proper application of minimum score thresholds
test "Proper application of minimum score thresholds" {
    const allocator = testing.allocator;

    // Create a test video metadata for an episode
    const video_meta = VideoMetadata{
        .title = null,
        .series = "Breaking Bad",
        .season = 5,
        .episode = 10,
        .year = 2013,
        .release_group = null,
        .resolution = null,
        .hash = "hash123",
        .video_type = .Episode,
    };

    // Create mock subtitles with different scores
    const subtitles = [_]Subtitle{
        // High score subtitle
        Subtitle{
            .id = "1",
            .provider_name = "provider1",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Breaking Bad",
            .season = 5,
            .episode = 10,
            .title = null,
            .year = 2013,
            .release_group = null,
            .fps = null,
            .hash = "hash123",
        },
        // Medium score subtitle
        Subtitle{
            .id = "2",
            .provider_name = "provider2",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Breaking Bad",
            .season = 5,
            .episode = 10,
            .title = null,
            .year = null,
            .release_group = null,
            .fps = null,
            .hash = null,
        },
        // Low score subtitle
        Subtitle{
            .id = "3",
            .provider_name = "provider3",
            .language = Language{ .primary = .{ 'e', 'n' }, .region = null },
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = "Different Show",
            .season = 1,
            .episode = 1,
            .title = null,
            .year = 2000,
            .release_group = null,
            .fps = null,
            .hash = null,
        },
    };

    // Compute scores for each subtitle
    var scored_subtitles = try allocator.alloc(Subtitle, subtitles.len);
    defer allocator.free(scored_subtitles);

    for (subtitles, 0..) |subtitle, i| {
        scored_subtitles[i] = subtitle;
        scored_subtitles[i].score = score.computeScore(&scored_subtitles[i], &video_meta);
    }

    // Test with high minimum score - should only match the first subtitle
    {
        const min_score: u32 = 90; // High threshold
        const best_subtitle = try core.selectBest(allocator, video_meta, scored_subtitles, min_score);

        try testing.expect(best_subtitle != null);
        try testing.expectEqualStrings("1", best_subtitle.?.id); // Should be the hash match
    }

    // Test with low minimum score - should still match the best subtitle
    {
        const min_score: u32 = 50; // Low threshold
        const best_subtitle = try core.selectBest(allocator, video_meta, scored_subtitles, min_score);

        try testing.expect(best_subtitle != null);
        try testing.expectEqualStrings("1", best_subtitle.?.id); // Should still be the hash match
    }

    // Test with very high minimum score - should return null
    {
        const min_score: u32 = 2000; // Very high threshold
        const best_subtitle = try core.selectBest(allocator, video_meta, scored_subtitles, min_score);

        try testing.expect(best_subtitle == null); // No subtitle meets this threshold
    }
}

// Test error handling for network failures or other provider issues
test "Error handling for network failures or other provider issues" {
    const allocator = testing.allocator;

    // Create a mock provider configured to fail
    var failing_provider = MockProvider.initWithError(allocator, "failing_provider", true, true);

    // Create a test video metadata
    const video_meta = VideoMetadata{
        .title = "Test Movie",
        .series = null,
        .season = null,
        .episode = null,
        .year = 2020,
        .release_group = null,
        .resolution = null,
        .hash = "test_hash",
        .video_type = .Movie,
    };

    // Attempt to search with the failing provider
    _ = failing_provider.search(video_meta) catch |err| {
        // Should catch the network error
        try testing.expect(err == Provider.ProviderSearchError.NetworkError);
        return;
    };

    // If we reach here, the search didn't fail as expected
    try testing.expect(false); // Force failure
}

// Test integration between core, providers, scoring, and CLI components
test "Integration between core, providers, scoring, and CLI components" {
    const allocator = testing.allocator;

    // Create test CLI arguments
    const args = [_][]const u8{
        "zub",
        "--lang",
        "en",
        "--min-score",
        "500",
        "--dry-run",
        "/path/to/video.mp4",
    };

    // Parse CLI arguments
    var config = zub.cli.parseArgs(allocator, &args) catch |err| {
        // TDD-PLACEHOLDER: In a real implementation, we would handle CLI parsing
        // For now, we expect it to work
        try testing.expect(false); // Force failure if we reach here
        return err;
    };
    defer config.deinit(allocator);

    // Verify CLI parsing worked correctly
    try testing.expect(config.languages.len == 1);
    try testing.expect(zub.eql(config.languages[0], zub.parse("en") catch unreachable));
    try testing.expect(config.min_score == 500);
    try testing.expect(config.dry_run == true);
    try testing.expect(config.paths.len == 1);
    try testing.expectEqualStrings("/path/to/video.mp4", config.paths[0]);

    // Create mock providers with test subtitles
    const mock_subtitles = [_]Subtitle{
        Subtitle{
            .id = "1",
            .provider_name = "mock_provider",
            .language = zub.parse("en") catch unreachable,
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = null,
            .season = null,
            .episode = null,
            .title = "Test Movie",
            .year = 2020,
            .release_group = null,
            .fps = null,
            .hash = "test_hash",
        },
    };

    const provider = MockProvider.initWithSubtitles(allocator, "mock_provider", &mock_subtitles);

    // Create a test video metadata
    const video_meta = VideoMetadata{
        .title = "Test Movie",
        .series = null,
        .season = null,
        .episode = null,
        .year = 2020,
        .release_group = null,
        .resolution = null,
        .hash = "test_hash",
        .video_type = .Movie,
    };

    // Search for subtitles using the provider
    const found_subtitles = try provider.search(video_meta);
    defer allocator.free(found_subtitles);

    // Score the subtitles
    var scored_subtitles = try allocator.alloc(Subtitle, found_subtitles.len);
    defer allocator.free(scored_subtitles);

    for (found_subtitles, 0..) |subtitle, i| {
        scored_subtitles[i] = subtitle;
        scored_subtitles[i].score = score.computeScore(&scored_subtitles[i], &video_meta);
    }

    // Select the best subtitle using core function with CLI config
    const best_subtitle = try core.selectBest(allocator, video_meta, scored_subtitles, config.min_score);

    // Verify that we got a result and it matches our expectations
    try testing.expect(best_subtitle != null);
    try testing.expectEqualStrings("1", best_subtitle.?.id);
    try testing.expectEqualStrings("mock_provider", best_subtitle.?.provider_name);

    // In dry-run mode, we would report what would be downloaded without actually downloading
    // For this test, we'll just verify that we have the information needed for download
    try testing.expect(best_subtitle.?.download_url == null); // No download URL in our mock
}
