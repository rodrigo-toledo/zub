const std = @import("std");
const zub = @import("zub");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    // Get the global allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Parse CLI arguments
    var config = zub.cli.parseArgs(allocator, args) catch |err| {
        std.debug.print("Error parsing arguments: {any}\n", .{err});
        return err;
    };
    defer config.deinit(allocator);

    // Process each file path
    for (config.paths) |file_path| {
        try processFile(allocator, config, file_path);
    }
}

fn processFile(allocator: Allocator, config: zub.cli.Config, file_path: []const u8) !void {
    // Parse the filename to extract video metadata
    var video_meta = try zub.video.parseFilename(allocator, file_path);
    defer {
        // Free any allocated strings in video_meta if needed
        // For this implementation, we're not allocating anything in parseFilename
        // so no cleanup is needed
    }

    // If video type is not set, detect it
    if (video_meta.video_type == null) {
        video_meta.video_type = zub.video.detectVideoType(file_path);
    }

    // Initialize providers
    var napiprojekt_provider = zub.NapiProjektProvider.init(allocator);
    defer napiprojekt_provider.deinit();

    var bsplayer_provider = zub.BSPlayerProvider.init(allocator);
    defer bsplayer_provider.deinit();

    // Try to login to BSPlayer (this is required for BSPlayer API)
    bsplayer_provider.login() catch |err| {
        std.debug.print("Warning: Failed to login to BSPlayer: {any}\n", .{err});
    };
    defer _ = bsplayer_provider.logout() catch |err| {
        std.debug.print("Warning: Failed to logout from BSPlayer: {any}\n", .{err});
    };

    // Search for subtitles using all providers
    var all_subtitles = std.ArrayList(zub.Subtitle){};
    defer {
        // Free any allocated content in subtitles
        for (all_subtitles.items) |*subtitle| {
            if (subtitle.content) |content| {
                allocator.free(content);
            }
        }
        all_subtitles.deinit(allocator);
    }

    // Search with NapiProjekt
    const napiprojekt_results = napiprojekt_provider.search(video_meta) catch |err| {
        std.debug.print("Warning: NapiProjekt search failed: {any}\n", .{err});
        const empty_results = &[_]zub.Subtitle{};
        try all_subtitles.appendSlice(allocator, empty_results);
        return;
    };
    defer allocator.free(napiprojekt_results);

    try all_subtitles.appendSlice(allocator, napiprojekt_results);

    // Search with BSPlayer
    const bsplayer_results = bsplayer_provider.search(video_meta) catch |err| {
        std.debug.print("Warning: BSPlayer search failed: {any}\n", .{err});
        const empty_results = &[_]zub.Subtitle{};
        try all_subtitles.appendSlice(allocator, empty_results);
        return;
    };
    defer allocator.free(bsplayer_results);

    try all_subtitles.appendSlice(allocator, bsplayer_results);

    // If no subtitles found, exit early
    if (all_subtitles.items.len == 0) {
        std.debug.print("No subtitles found for {s}\n", .{file_path});
        return;
    }

    // Score all subtitles
    for (all_subtitles.items) |*subtitle| {
        subtitle.score = zub.score.computeScore(subtitle, &video_meta);
    }

    // Select the best subtitle
    const best_subtitle = try zub.core.selectBest(allocator, video_meta, all_subtitles.items, config.min_score);

    if (best_subtitle) |subtitle| {
        if (config.dry_run) {
            // In dry-run mode, just print what would be downloaded
            std.debug.print("Dry-run: Would download subtitle for {s}\n", .{file_path});
            std.debug.print("  Provider: {s}\n", .{subtitle.provider_name});
            std.debug.print("  Language: {any}\n", .{subtitle.language});
            std.debug.print("  Score: {d}\n", .{subtitle.score});
        } else {
            // Download and save the subtitle
            const content = try downloadSubtitle(allocator, &subtitle);
            defer allocator.free(content);

            try saveSubtitle(allocator, file_path, &subtitle, content);
            std.debug.print("Successfully downloaded subtitle for {s}\n", .{file_path});
        }
    } else {
        std.debug.print("No suitable subtitle found for {s} (minimum score: {d})\n", .{ file_path, config.min_score });
    }
}

fn downloadSubtitle(allocator: Allocator, subtitle: *const zub.Subtitle) ![]u8 {
    // For now, we'll just return empty content since the providers already have the content
    // In a real implementation, we would download from the subtitle's download_url
    if (subtitle.content) |content| {
        return allocator.dupe(u8, content);
    }

    // If no content is available, we would download it
    // This is a placeholder implementation
    return allocator.dupe(u8, "");
}

fn saveSubtitle(allocator: Allocator, video_path: []const u8, subtitle: *const zub.Subtitle, content: []const u8) !void {
    // Use subtitle parameter to avoid unused parameter warning
    _ = subtitle;

    // Generate subtitle filename based on video path and language
    const last_dot = std.mem.lastIndexOfScalar(u8, video_path, '.') orelse video_path.len;
    const base_name = video_path[0..last_dot];

    // For simplicity, we'll use .srt extension
    const subtitle_path = try std.fmt.allocPrint(allocator, "{s}.srt", .{base_name});
    defer allocator.free(subtitle_path);

    // Write content to file
    try std.fs.cwd().writeFile(.{ .sub_path = subtitle_path, .data = content });
}
