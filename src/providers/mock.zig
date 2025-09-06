const std = @import("std");
const root = @import("../root.zig");
const Provider = root.Provider;
const VideoMetadata = root.VideoMetadata;
const Subtitle = root.Subtitle;
const Language = root.Language;

pub const MockProvider = struct {
    name: []const u8,
    allocator: std.mem.Allocator,
    // Configuration for mock behavior
    should_fail_search: bool,
    should_fail_download: bool,
    subtitles_to_return: []const Subtitle,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) MockProvider {
        return MockProvider{
            .name = name,
            .allocator = allocator,
            .should_fail_search = false,
            .should_fail_download = false,
            .subtitles_to_return = &[_]Subtitle{},
        };
    }

    pub fn initWithSubtitles(allocator: std.mem.Allocator, name: []const u8, subtitles: []const Subtitle) MockProvider {
        return MockProvider{
            .name = name,
            .allocator = allocator,
            .should_fail_search = false,
            .should_fail_download = false,
            .subtitles_to_return = subtitles,
        };
    }

    pub fn initWithError(allocator: std.mem.Allocator, name: []const u8, fail_search: bool, fail_download: bool) MockProvider {
        return MockProvider{
            .name = name,
            .allocator = allocator,
            .should_fail_search = fail_search,
            .should_fail_download = fail_download,
            .subtitles_to_return = &[_]Subtitle{},
        };
    }

    pub fn search(self: MockProvider, video: VideoMetadata) Provider.ProviderSearchError![]Subtitle {
        _ = video; // Unused parameter

        if (self.should_fail_search) {
            return Provider.ProviderSearchError.NetworkError;
        }

        // Return a copy of the subtitles
        const result = self.allocator.dupe(Subtitle, self.subtitles_to_return) catch |err| {
            return switch (err) {
                error.OutOfMemory => Provider.ProviderSearchError.NetworkError,
            };
        };
        return result;
    }

    pub fn download(self: MockProvider, subtitle: Subtitle) Provider.ProviderDownloadError![]u8 {
        _ = subtitle; // Unused parameter

        if (self.should_fail_download) {
            return Provider.ProviderDownloadError.NetworkError;
        }

        // Return some mock content
        const content = "This is mock subtitle content";
        const result = self.allocator.dupe(u8, content) catch |err| {
            return switch (err) {
                error.OutOfMemory => Provider.ProviderDownloadError.NetworkError,
            };
        };
        return result;
    }

    // Convert to Provider interface
    pub fn toProvider(self: MockProvider) Provider {
        return Provider{
            .name = self.name,
            .search = struct {
                fn searchFn(video: VideoMetadata) Provider.ProviderSearchError![]Subtitle {
                    // This is a limitation of Zig - we can't capture the self instance
                    // In a real implementation, we would need to store the provider instance somewhere
                    // For now, we'll return an error to indicate this isn't fully implemented
                    _ = video;
                    return Provider.ProviderSearchError.NetworkError;
                }
            }.searchFn,
            .download = struct {
                fn downloadFn(subtitle: Subtitle) Provider.ProviderDownloadError![]u8 {
                    // This is a limitation of Zig - we can't capture the self instance
                    // In a real implementation, we would need to store the provider instance somewhere
                    // For now, we'll return an error to indicate this isn't fully implemented
                    _ = subtitle;
                    return Provider.ProviderDownloadError.NetworkError;
                }
            }.downloadFn,
        };
    }
};
