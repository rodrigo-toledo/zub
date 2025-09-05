const std = @import("std");
const language = @import("language.zig");

test "parse canonical - en" {
    const lang = try language.parse("en");
    try std.testing.expect(std.mem.eql(u8, lang.primary[0..], "en"));
    try std.testing.expect(lang.region == null);
}

test "parse canonical - pt-BR" {
    const lang = try language.parse("pt-BR");
    try std.testing.expect(std.mem.eql(u8, lang.primary[0..], "pt"));
    try std.testing.expect(lang.region != null);
    const r = lang.region.?;
    try std.testing.expect(std.mem.eql(u8, r[0..], "BR"));
}

test "parse rejects non-canonical" {
    try std.testing.expectError(error.InvalidLanguage, language.parse("EN"));
    try std.testing.expectError(error.InvalidLanguage, language.parse("pt-br"));
    try std.testing.expectError(error.InvalidLanguage, language.parse("e"));
    try std.testing.expectError(error.InvalidLanguage, language.parse("eng"));
    try std.testing.expectError(error.InvalidLanguage, language.parse("ptBR"));
}

test "eql basic behavior" {
    const Language = language.Language;
    const a = Language{ .primary = .{ 'e', 'n' }, .region = null };
    const b = Language{ .primary = .{ 'e', 'n' }, .region = null };
    try std.testing.expect(language.eql(a, b));
    const c = Language{ .primary = .{ 'p', 't' }, .region = .{ 'B', 'R' } };
    try std.testing.expect(!language.eql(a, c));
    const d = Language{ .primary = .{ 'e', 'n' }, .region = .{ 'U', 'S' } };
    try std.testing.expect(!language.eql(a, d));
}

test "toCanonical formatting and capacity" {
    const Language = language.Language;
    var buf2: [2]u8 = undefined;
    var buf5: [5]u8 = undefined;

    const en = Language{ .primary = .{ 'e', 'n' }, .region = null };
    const out_en = try language.toCanonical(buf2[0..], en);
    try std.testing.expectEqualStrings("en", out_en);

    const ptbr = Language{ .primary = .{ 'p', 't' }, .region = .{ 'B', 'R' } };
    try std.testing.expectError(error.BufferTooSmall, language.toCanonical(buf2[0..], ptbr));

    const out_ptbr = try language.toCanonical(buf5[0..], ptbr);
    try std.testing.expectEqualStrings("pt-BR", out_ptbr);
}
