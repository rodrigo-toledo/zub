const std = @import("std");
const zub = @import("root.zig");
const Language = @import("language.zig").Language;
const language = @import("language.zig");

pub const Config = struct {
    languages: []Language,
    paths: [][]const u8,
    min_score: u32,
    dry_run: bool,

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.languages);
        allocator.free(self.paths);
    }
};

pub const parse = language.parse;
pub const eql = language.eql;

pub fn parseArgs(allocator: std.mem.Allocator, args: []const []const u8) !Config {
    var languages = std.ArrayListUnmanaged(Language){};
    defer languages.deinit(allocator);

    var paths = std.ArrayListUnmanaged([]const u8){};
    defer paths.deinit(allocator);

    var min_score: u32 = 0;
    var dry_run: bool = false;

    var i: usize = 1; // Skip the program name
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--lang")) {
            i += 1;
            if (i >= args.len) {
                return error.InvalidArgument;
            }
            const lang_str = args[i];
            const lang = try language.parse(lang_str);
            try languages.append(allocator, lang);
        } else if (std.mem.eql(u8, arg, "--min-score")) {
            i += 1;
            if (i >= args.len) {
                return error.InvalidArgument;
            }
            const score_str = args[i];
            min_score = std.fmt.parseInt(u32, score_str, 10) catch {
                return error.InvalidArgument;
            };
        } else if (std.mem.eql(u8, arg, "--dry-run")) {
            dry_run = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            // Unknown flag
            return error.InvalidArgument;
        } else {
            // This is a path
            try paths.append(allocator, arg);
        }
    }

    return Config{
        .languages = try languages.toOwnedSlice(allocator),
        .paths = try paths.toOwnedSlice(allocator),
        .min_score = min_score,
        .dry_run = dry_run,
    };
}
