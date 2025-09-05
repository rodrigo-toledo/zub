const std = @import("std");
const VideoMetadata = @import("video.zig").VideoMetadata;
const Subtitle = @import("subtitle.zig").Subtitle;

// Episode scoring weights
const EPISODE_WEIGHT_HASH = 971;
const EPISODE_WEIGHT_SERIES = 486;
const EPISODE_WEIGHT_SEASON = 54;
const EPISODE_WEIGHT_EPISODE = 54;
const EPISODE_WEIGHT_YEAR = 162;

// Movie scoring weights
const MOVIE_WEIGHT_HASH = 323;
const MOVIE_WEIGHT_TITLE = 162;
const MOVIE_WEIGHT_YEAR = 54;

pub fn isEpisode(video_meta: *const VideoMetadata) bool {
    // A video is considered an episode if it has a series field
    // otherwise it's a movie
    return video_meta.series != null;
}

pub fn computeScore(subtitle: *const Subtitle, video_meta: *const VideoMetadata) u32 {
    // Determine if this is an episode or movie based on video_type field
    const is_episode = if (video_meta.video_type) |vt| vt == .Episode else false;

    var score: u32 = 0;

    if (is_episode) {
        // Hash match
        if (subtitle.hash) |s_hash| {
            if (video_meta.hash) |v_hash| {
                if (std.mem.eql(u8, s_hash, v_hash)) {
                    score += EPISODE_WEIGHT_HASH;
                }
            }
        }

        // Series match
        if (subtitle.series) |s_series| {
            if (video_meta.series) |v_series| {
                if (std.mem.eql(u8, s_series, v_series)) {
                    score += EPISODE_WEIGHT_SERIES;
                }
            }
        }

        // Season match
        if (subtitle.season) |s_season| {
            if (video_meta.season) |v_season| {
                if (s_season == v_season) {
                    score += EPISODE_WEIGHT_SEASON;
                }
            }
        }

        // Episode match
        if (subtitle.episode) |s_episode| {
            if (video_meta.episode) |v_episode| {
                if (s_episode == v_episode) {
                    score += EPISODE_WEIGHT_EPISODE;
                }
            }
        }

        // Year match
        if (subtitle.year) |s_year| {
            if (video_meta.year) |v_year| {
                if (s_year == v_year) {
                    score += EPISODE_WEIGHT_YEAR;
                }
            }
        }
    } else {
        // Movie scoring
        // Hash match
        if (subtitle.hash) |s_hash| {
            if (video_meta.hash) |v_hash| {
                if (std.mem.eql(u8, s_hash, v_hash)) {
                    score += MOVIE_WEIGHT_HASH;
                }
            }
        }

        // Title match (for movies)
        if (subtitle.title) |s_title| {
            if (video_meta.title) |v_title| {
                if (std.mem.eql(u8, s_title, v_title)) {
                    score += MOVIE_WEIGHT_TITLE;
                }
            }
        }

        // Year match (for movies)
        if (subtitle.year) |s_year| {
            if (video_meta.year) |v_year| {
                if (s_year == v_year) {
                    score += MOVIE_WEIGHT_YEAR;
                }
            }
        }
    }

    return score;
}

pub fn selectBestSubtitle(subtitles: []Subtitle, video_meta: *const VideoMetadata, min_score: u32) ?*Subtitle {
    if (subtitles.len == 0) {
        return null;
    }

    var best_subtitle: ?*Subtitle = null;
    var best_score: u32 = 0;
    var best_has_hash_match: bool = false;

    for (subtitles) |*subtitle| {
        const score = computeScore(subtitle, video_meta);

        // Check if this subtitle meets the minimum score
        if (score >= min_score) {
            // Check if this subtitle has a hash match
            const has_hash_match = if (subtitle.hash) |s_hash|
                if (video_meta.hash) |v_hash| std.mem.eql(u8, s_hash, v_hash) else false
            else
                false;

            // Update best subtitle if:
            // 1. This is the first valid subtitle
            // 2. This has a hash match and the current best doesn't
            // 3. This has a better score (when hash match status is the same)
            if (best_subtitle == null) {
                best_subtitle = subtitle;
                best_score = score;
                best_has_hash_match = has_hash_match;
            } else if (has_hash_match and !best_has_hash_match) {
                // Prefer hash matches over non-hash matches
                best_subtitle = subtitle;
                best_score = score;
                best_has_hash_match = has_hash_match;
            } else if (has_hash_match == best_has_hash_match and score > best_score) {
                // If both have hash matches or both don't, prefer higher score
                best_subtitle = subtitle;
                best_score = score;
                best_has_hash_match = has_hash_match;
            }
        }
    }

    return best_subtitle;
}
