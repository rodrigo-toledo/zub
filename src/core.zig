const std = @import("std");
const zub = @import("root.zig");
const VideoMetadata = @import("video.zig").VideoMetadata;
const Subtitle = @import("subtitle.zig").Subtitle;
const score = @import("score.zig");

pub fn selectBest(allocator: std.mem.Allocator, video: VideoMetadata, candidates: []const Subtitle, min_score: u32) !?Subtitle {
    // Create a mutable copy of candidates for the scoring engine
    var mutable_candidates = try allocator.alloc(Subtitle, candidates.len);
    defer allocator.free(mutable_candidates);

    for (candidates, 0..) |candidate, index| {
        mutable_candidates[index] = candidate;
    }

    // Call the scoring engine to select the best subtitle
    const best_subtitle = score.selectBestSubtitle(mutable_candidates, &video, min_score);

    // Return a copy of the best subtitle if found, otherwise null
    if (best_subtitle) |subtitle| {
        // Create a copy of the subtitle since the one from scoring engine
        // points to our mutable_candidates which will be freed
        return subtitle.*;
    } else {
        return null;
    }
}
