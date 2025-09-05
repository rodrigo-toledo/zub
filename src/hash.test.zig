const std = @import("std");
const h = @import("hash.zig");

fn writeFile(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{ .read = true, .truncate = true });
    defer file.close();
    try file.writeAll(data);
}

test "OpenSubtitles hash rejects small files" {
    var small: [1024]u8 = undefined;
    for (&small, 0..) |*b, i| {
        b.* = @as(u8, @intCast(i & 0xff));
    }

    const path = "test_os_small.bin";
    defer std.fs.cwd().deleteFile(path) catch {};

    try writeFile(path, &small);

    try std.testing.expectError(error.FileTooSmall, h.computeOpenSubtitlesHashU64(path));
}

test "OpenSubtitles hash for 128KiB pattern" {
    var first: [65536]u8 = undefined;
    var last: [65536]u8 = undefined;

    // Fill patterns
    for (&first, 0..) |*b, i| {
        b.* = @as(u8, @intCast(i & 0xff));
    }
    for (&last, 0..) |*b, i| {
        b.* = @as(u8, @intCast(255 - (i & 0xff)));
    }

    const path = "test_os_large.bin";
    defer std.fs.cwd().deleteFile(path) catch {};

    // Write file: first 64KiB then last 64KiB
    {
        const f = try std.fs.cwd().createFile(path, .{ .read = true, .truncate = true });
        defer f.close();
        try f.writeAll(&first);
        try f.writeAll(&last);
    }

    // Compute expected 64-bit hash
    const file_size: u64 = 131072;
    var expected: u64 = file_size;

    var buf: [8]u8 = undefined;
    var i: usize = 0;
    while (i < first.len) : (i += 8) {
        @memcpy(buf[0..], first[i .. i + 8]);
        expected +%= std.mem.readInt(u64, buf[0..], .little);
    }

    i = 0;
    while (i < last.len) : (i += 8) {
        @memcpy(buf[0..], last[i .. i + 8]);
        expected +%= std.mem.readInt(u64, buf[0..], .little);
    }

    const actual = try h.computeOpenSubtitlesHashU64(path);
    try std.testing.expectEqual(expected, actual);
}

test "NapiProjekt MD5 hex lower (first 10MB window)" {
    const path = "test_napi_md5.txt";
    defer std.fs.cwd().deleteFile(path) catch {};
    const content = "abc";
    try writeFile(path, content);

    const hex = try h.computeNapiProjektHashHex(std.testing.allocator, path);
    defer std.testing.allocator.free(hex);

    // MD5("abc") is a well-known test vector
    try std.testing.expectEqual(@as(usize, 32), hex.len);
    try std.testing.expectEqualStrings("900150983cd24fb0d6963f7d28e17f72", hex);
}
