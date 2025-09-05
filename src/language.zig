const std = @import("std");

pub const Language = struct {
    /// Lowercase ISO 639-1 primary code, e.g. "en", "pt".
    primary: [2]u8,
    /// Optional region code (uppercase ISO 3166-1 alpha-2), e.g. "US", "BR".
    region: ?[2]u8,

    pub const en = Language{ .primary = .{ 'e', 'n' }, .region = null };
};

/// Parse canonical language code forms:
/// - "en" (lowercase)
/// - "pt-BR" (lowercase primary, uppercase region)
/// Returns error.InvalidLanguage on malformed input.
pub fn parse(input: []const u8) !Language {
    if (input.len == 2) {
        const a = input[0];
        const b = input[1];
        if ((a >= 'a' and a <= 'z') and (b >= 'a' and b <= 'z')) {
            return Language{ .primary = .{ a, b }, .region = null };
        }
        return error.InvalidLanguage;
    } else if (input.len == 5) {
        // Form: xx-YY
        const a = input[0];
        const b = input[1];
        const dash = input[2];
        const c = input[3];
        const d = input[4];
        if (dash != '-') return error.InvalidLanguage;
        if (!((a >= 'a' and a <= 'z') and (b >= 'a' and b <= 'z'))) return error.InvalidLanguage;
        if (!((c >= 'A' and c <= 'Z') and (d >= 'A' and d <= 'Z'))) return error.InvalidLanguage;
        return Language{ .primary = .{ a, b }, .region = .{ c, d } };
    } else {
        return error.InvalidLanguage;
    }
}

/// Case-sensitive equality on canonicalized codes.
pub fn eql(a: Language, b: Language) bool {
    if (a.primary[0] != b.primary[0] or a.primary[1] != b.primary[1]) return false;
    if (a.region) |ra| {
        if (b.region) |rb| {
            return ra[0] == rb[0] and ra[1] == rb[1];
        } else {
            return false;
        }
    } else {
        return b.region == null;
    }
}

/// Write canonical form "xx" or "xx-YY" into provided buffer, return the slice used.
pub fn toCanonical(buf: []u8, lang: Language) ![]const u8 {
    if (lang.region == null) {
        if (buf.len < 2) return error.BufferTooSmall;
        buf[0] = lang.primary[0];
        buf[1] = lang.primary[1];
        return buf[0..2];
    } else {
        if (buf.len < 5) return error.BufferTooSmall;
        const region = lang.region.?;
        buf[0] = lang.primary[0];
        buf[1] = lang.primary[1];
        buf[2] = '-';
        buf[3] = region[0];
        buf[4] = region[1];
        return buf[0..5];
    }
}
