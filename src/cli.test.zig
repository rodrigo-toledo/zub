const std = @import("std");
const zub = @import("root.zig");
const cli = zub.cli;
const Language = zub.Language;

test "CLI parses one language and one path" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "--lang", "en", "/videos/Show.S01E01.mkv" };
    var config = try cli.parseArgs(allocator, &args);
    defer config.deinit(allocator);

    // Check languages
    try std.testing.expectEqual(@as(usize, 1), config.languages.len);
    const expected_lang = try zub.parse("en");
    try std.testing.expect(zub.eql(expected_lang, config.languages[0]));

    // Check paths
    try std.testing.expectEqual(@as(usize, 1), config.paths.len);
    try std.testing.expectEqualStrings("/videos/Show.S01E01.mkv", config.paths[0]);

    // Check defaults
    try std.testing.expectEqual(@as(u32, 0), config.min_score);
    try std.testing.expectEqual(false, config.dry_run);
}

test "CLI rejects unknown flags" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "--unknown" };
    _ = cli.parseArgs(allocator, &args) catch |err| {
        try std.testing.expect(err == error.InvalidArgument);
        return;
    };

    // If we reach here, the function didn't return an error as expected
    try std.testing.expect(false);
}

test "CLI parses repeated languages and multiple paths" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "-l", "en", "-l", "pt", "/a.mkv", "/b.mkv" };
    var config = try cli.parseArgs(allocator, &args);
    defer config.deinit(allocator);

    // Check languages
    try std.testing.expectEqual(@as(usize, 2), config.languages.len);
    const expected_lang_en = try zub.parse("en");
    const expected_lang_pt = try zub.parse("pt");
    try std.testing.expect(zub.eql(expected_lang_en, config.languages[0]));
    try std.testing.expect(zub.eql(expected_lang_pt, config.languages[1]));

    // Check paths
    try std.testing.expectEqual(@as(usize, 2), config.paths.len);
    try std.testing.expectEqualStrings("/a.mkv", config.paths[0]);
    try std.testing.expectEqualStrings("/b.mkv", config.paths[1]);
}

test "parse --help sets help=true" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "--help" };
    var config = try cli.parseArgs(allocator, &args);
    defer config.deinit(allocator);

    // Check help flag
    try std.testing.expectEqual(true, config.help);

    // Check defaults for other fields
    try std.testing.expectEqual(@as(usize, 0), config.languages.len);
    try std.testing.expectEqual(@as(usize, 0), config.paths.len);
    try std.testing.expectEqual(@as(u32, 0), config.min_score);
    try std.testing.expectEqual(false, config.dry_run);
}

test "parse -h sets help=true" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "-h" };
    var config = try cli.parseArgs(allocator, &args);
    defer config.deinit(allocator);

    // Check help flag
    try std.testing.expectEqual(true, config.help);

    // Check defaults for other fields
    try std.testing.expectEqual(@as(usize, 0), config.languages.len);
    try std.testing.expectEqual(@as(usize, 0), config.paths.len);
    try std.testing.expectEqual(@as(u32, 0), config.min_score);
    try std.testing.expectEqual(false, config.dry_run);
}

test "help allows zero paths" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "--help" };
    var config = try cli.parseArgs(allocator, &args);
    defer config.deinit(allocator);

    // Should parse successfully even with zero paths
    try std.testing.expectEqual(true, config.help);
}

test "helpText contains required sections" {
    const txt = zub.cli.helpText();

    // Check for required substrings
    try std.testing.expect(std.mem.indexOf(u8, txt, "Usage: zub [OPTIONS] [PATH ...]") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "-l, --lang") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "--min-score") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "--dry-run") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "-h, --help") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "recursively") != null);
    try std.testing.expect(std.mem.indexOf(u8, txt, "Examples") != null);
}

test "unknown flag still errors" {
    const allocator = std.testing.allocator;

    const args = [_][]const u8{ "zub", "--not-a-flag" };
    _ = cli.parseArgs(allocator, &args) catch |err| {
        try std.testing.expect(err == error.InvalidArgument);
        return;
    };

    // If we reach here, the function didn't return an error as expected
    try std.testing.expect(false);
}
