const root = @import("../root.zig");

// Define error sets for provider operations
pub const ProviderSearchError = error{
    NetworkError,
    ParseError,
    // Add other specific search errors as needed
};

pub const ProviderDownloadError = error{
    NetworkError,
    IoError,
    // Add other specific download errors as needed
};

pub const Provider = struct {
    name: []const u8,
    /// Search for subtitles matching the given video metadata
    search: *const fn (video: root.VideoMetadata) ProviderSearchError![]root.Subtitle,
    /// Download the content of a specific subtitle
    download: *const fn (subtitle: root.Subtitle) ProviderDownloadError![]u8,
};
