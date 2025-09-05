const std = @import("std");
const video = @import("video.zig");
const Language = @import("language.zig").Language;

pub const Subtitle = struct {
    id: []const u8,
    provider_name: []const u8,
    language: Language,
    hearing_impaired: bool = false,
    score: u32 = 0,
    content: ?[]const u8 = null,
    download_url: ?[]const u8 = null,

    // Metadata for scoring
    series: ?[]const u8 = null,
    season: ?u16 = null,
    episode: ?u16 = null,
    title: ?[]const u8 = null,
    year: ?u16 = null,
    release_group: ?[]const u8 = null,
    fps: ?f32 = null,
    hash: ?[]const u8 = null,

    pub fn getMatches(self: *const Subtitle, matches: *std.ArrayListUnmanaged([]const u8), allocator: std.mem.Allocator, video_meta: *const video.VideoMetadata) !void {
        if (self.hash) |s_hash| {
            if (video_meta.hash) |v_hash| {
                if (std.mem.eql(u8, s_hash, v_hash)) {
                    try matches.append(allocator, "hash");
                }
            }
        }
        if (self.series) |s_series| {
            if (video_meta.series) |v_series| {
                if (std.mem.eql(u8, s_series, v_series)) {
                    try matches.append(allocator, "series");
                }
            }
        }
        if (self.season) |s_season| {
            if (video_meta.season) |v_season| {
                if (s_season == v_season) {
                    try matches.append(allocator, "season");
                }
            }
        }
        if (self.episode) |s_episode| {
            if (video_meta.episode) |v_episode| {
                if (s_episode == v_episode) {
                    try matches.append(allocator, "episode");
                }
            }
        }
        if (self.year) |s_year| {
            if (video_meta.year) |v_year| {
                if (s_year == v_year) {
                    try matches.append(allocator, "year");
                }
            }
        }
        if (self.release_group) |s_rg| {
            if (video_meta.release_group) |v_rg| {
                if (std.mem.eql(u8, s_rg, v_rg)) {
                    try matches.append(allocator, "release_group");
                }
            }
        }
    }
};
