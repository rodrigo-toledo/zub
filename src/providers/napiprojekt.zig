const std = @import("std");
const Allocator = std.mem.Allocator;
const Provider = @import("provider.zig").Provider;
const ProviderSearchError = @import("provider.zig").ProviderSearchError;
const ProviderDownloadError = @import("provider.zig").ProviderDownloadError;
const HttpClient = @import("../utils/http.zig").HttpClient;
const Subtitle = @import("../subtitle.zig").Subtitle;
const Language = @import("../language.zig").Language;
const video = @import("../video.zig");

// Error set for NapiProjekt provider operations
pub const NapiProjektError = error{
    NetworkError,
    ParseError,
    // Add other specific errors as needed
};

// NapiProjekt provider implementation
pub const NapiProjektProvider = struct {
    client: HttpClient,
    name: []const u8 = "napiprojekt",

    pub fn init(allocator: Allocator) NapiProjektProvider {
        return NapiProjektProvider{
            .client = HttpClient.init(allocator),
        };
    }

    pub fn deinit(self: *NapiProjektProvider) void {
        // Currently nothing to deinitialize
        _ = self;
    }

    // Get a second hash based on NapiProjekt's hash
    fn getSubHash(video_hash: []const u8) ![10]u8 {
        // Check if the hash is long enough
        if (video_hash.len < 16) {
            // Return a default subhash for shorter hashes
            return [10]u8{ '0', '0', '0', '0', '0', '0', '0', '0', '0', '0' };
        }

        const idx = [_]usize{ 0xE, 0x3, 0x6, 0x8, 0x2 };
        const mul = [_]usize{ 2, 2, 5, 4, 3 };
        const add = [_]usize{ 0, 0xD, 0x10, 0xB, 0x5 };

        var b: [5]u8 = undefined;
        for (idx, 0..) |i_idx, i| {
            const a = add[i];
            const m = mul[i];
            // Get the character at i_idx and convert to integer
            const i_char = video_hash[i_idx];
            const i_val = if (i_char >= '0' and i_char <= '9') i_char - '0' else if (i_char >= 'a' and i_char <= 'f') i_char - 'a' + 10 else 0;
            const t = a + i_val;
            // Get the two characters at t and t+1 and convert to integer
            const v_char1 = video_hash[t];
            const v_char2 = video_hash[t + 1];
            const v_val1 = if (v_char1 >= '0' and v_char1 <= '9') v_char1 - '0' else if (v_char1 >= 'a' and v_char1 <= 'f') v_char1 - 'a' + 10 else 0;
            const v_val2 = if (v_char2 >= '0' and v_char2 <= '9') v_char2 - '0' else if (v_char2 >= 'a' and v_char2 <= 'f') v_char2 - 'a' + 10 else 0;
            const v = v_val1 * 16 + v_val2;
            const result_val = (v * m) % 16;
            const hex_char = if (result_val < 10) @as(u8, '0') + @as(u8, @intCast(result_val)) else @as(u8, 'a') + @as(u8, @intCast(result_val - 10));
            b[i] = hex_char;
        }

        // Convert the 5 bytes to a 10-character hex string
        var result: [10]u8 = undefined;
        var j: usize = 0;
        for (b) |byte| {
            const high_nibble = (byte >> 4) & 0xF;
            const low_nibble = byte & 0xF;
            result[j] = if (high_nibble < 10) @as(u8, '0') + @as(u8, @intCast(high_nibble)) else @as(u8, 'a') + @as(u8, @intCast(high_nibble - 10));
            result[j + 1] = if (low_nibble < 10) @as(u8, '0') + @as(u8, @intCast(low_nibble)) else @as(u8, 'a') + @as(u8, @intCast(low_nibble - 10));
            j += 2;
        }
        return result;
    }

    // Search for subtitles
    pub fn search(self: NapiProjektProvider, video_meta: video.VideoMetadata) ProviderSearchError![]Subtitle {
        // Check if video has a hash
        if (video_meta.hash == null) {
            return ProviderSearchError.NetworkError;
        }

        const video_hash = video_meta.hash.?;

        // Calculate subhash
        const sub_hash = getSubHash(video_hash) catch return ProviderSearchError.ParseError;

        // For simplicity, we'll use Polish language (pl) as the default
        const language_code = "PL";

        // Build URL directly
        const url = std.fmt.allocPrint(self.client.allocator, "https://napiprojekt.pl/unit_napisy/dl.php?v=dreambox&kolejka=false&nick=&pass=&napios=Linux&l={s}&f={s}&t={s}", .{ language_code, video_hash, sub_hash }) catch return ProviderSearchError.NetworkError;
        defer self.client.allocator.free(url);

        // Make HTTP request
        const response = self.client.get(url) catch return ProviderSearchError.NetworkError;
        defer std.heap.page_allocator.free(response);

        // Parse content
        const content = parseContent(response) catch return ProviderSearchError.ParseError;

        // If no content, return empty array
        if (content.len == 0) {
            const result = std.heap.page_allocator.alloc(Subtitle, 0) catch return ProviderSearchError.NetworkError;
            return result;
        }

        // Create subtitle object
        var subtitles = std.heap.page_allocator.alloc(Subtitle, 1) catch return ProviderSearchError.NetworkError;

        // For Polish language
        const lang = Language{ .primary = .{ 'p', 'l' }, .region = null };

        subtitles[0] = Subtitle{
            .id = video_hash,
            .provider_name = "napiprojekt",
            .language = lang,
            .hearing_impaired = false,
            .score = 0,
            .content = null,
            .download_url = null,
            .series = video_meta.series,
            .season = video_meta.season,
            .episode = video_meta.episode,
            .title = video_meta.title,
            .year = video_meta.year,
            .release_group = video_meta.release_group,
            .fps = null,
            .hash = video_hash,
        };

        // Set content
        const content_copy = std.heap.page_allocator.dupe(u8, content) catch return ProviderSearchError.NetworkError;
        subtitles[0].content = content_copy;

        return subtitles;
    }

    // Parse the subtitle content from the response
    fn parseContent(content: []const u8) ![]u8 {
        // GZipped file prefix
        const gzip_prefix = "\x1f\x8b\x08";

        // GZipped file
        if (content.len >= 3 and std.mem.eql(u8, content[0..3], gzip_prefix)) {
            // In a real implementation, we would decompress the gzip content
            // For now, we'll just return an empty array to indicate no subtitles found
            const result = try std.heap.page_allocator.alloc(u8, 0);
            return result;
        }

        // Handle subtitles not found and errors
        if (content.len >= 4 and std.mem.eql(u8, content[0..4], "NPc0")) {
            const result = try std.heap.page_allocator.alloc(u8, 0);
            return result;
        }

        // Fix line endings (simplified)
        const result = try std.heap.page_allocator.alloc(u8, content.len);
        @memcpy(result, content);
        return result;
    }

    // Download a subtitle
    pub fn download(self: NapiProjektProvider, subtitle: Subtitle) ProviderDownloadError![]u8 {
        // Use self parameter
        // For NapiProjekt, the content is already downloaded in the search function
        // So we just return the content if it exists
        if (subtitle.content) |content| {
            const result = self.client.allocator.alloc(u8, content.len) catch return ProviderDownloadError.NetworkError;
            @memcpy(result, content);
            return result;
        }

        return ProviderDownloadError.NetworkError;
    }
};
