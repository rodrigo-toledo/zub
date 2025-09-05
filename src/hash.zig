const std = @import("std");

pub fn computeOpenSubtitlesHashU64(path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    if (file_size < 2 * 65536) return error.FileTooSmall;

    var hash: u64 = file_size;

    // Read first 64 KiB
    var first: [65536]u8 = undefined;
    try file.seekTo(0);
    const n1 = try file.readAll(first[0..]);
    if (n1 != first.len) return error.UnexpectedEof;

    var i: usize = 0;
    while (i < first.len) : (i += 8) {
        var chunk: [8]u8 = undefined;
        @memcpy(chunk[0..], first[i .. i + 8]);
        hash +%= std.mem.readInt(u64, &chunk, .little);
    }

    // Read last 64 KiB
    var last: [65536]u8 = undefined;
    try file.seekTo(file_size - 65536);
    const n2 = try file.readAll(last[0..]);
    if (n2 != last.len) return error.UnexpectedEof;

    i = 0;
    while (i < last.len) : (i += 8) {
        var chunk: [8]u8 = undefined;
        @memcpy(chunk[0..], last[i .. i + 8]);
        hash +%= std.mem.readInt(u64, &chunk, .little);
    }

    return hash;
}

pub fn computeNapiProjektHashHex(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = try file.getEndPos();
    const ten_mb: u64 = 10 * 1024 * 1024;
    const to_read_u64: u64 = if (size < ten_mb) size else ten_mb;
    const to_read: usize = @intCast(to_read_u64);

    const buf = try allocator.alloc(u8, to_read);
    defer allocator.free(buf);

    const n = try file.readAll(buf);
    const slice = buf[0..n];

    var digest: [16]u8 = undefined;
    std.crypto.hash.Md5.hash(slice, &digest, .{});

    // Convert digest to lowercase hex
    const out = try allocator.alloc(u8, 32);
    errdefer allocator.free(out);

    const hexdigits = "0123456789abcdef";
    var j: usize = 0;
    for (digest) |b| {
        out[j] = hexdigits[(b >> 4) & 0x0F];
        out[j + 1] = hexdigits[b & 0x0F];
        j += 2;
    }

    return out;
}
