const std = @import("std");

/// The type of a grammar symbol.
const SymbolType = enum(c_uint) {
    Regular,
    Anonymous,
    Supertype,
    Auxiliary,
};

/// The metadata associated with a language.
///
/// Currently, this metadata can be used to check the [Semantic Version](https://semver.org/)
/// of the language. This version information should be used to signal if a given parser might
/// be incompatible with existing queries when upgrading between major versions, or minor versions
/// if it's in zerover.
pub const LanguageMetadata = extern struct {
    major_version: u8,
    minor_version: u8,
    patch_version: u8,
};

const LanguageFn = *const fn () callconv(.c) *const Language;

/// An opaque object that defines how to parse a particular language.
pub const Language = opaque {
    /// Free any dynamically-allocated resources for this language, if this is the last reference.
    pub fn destroy(self: *const Language) void {
        ts_language_delete(self);
    }
};

extern fn ts_language_abi_version(self: *const Language) u32;
extern fn ts_language_copy(self: *const Language) *const Language;
extern fn ts_language_delete(self: *const Language) void;
extern fn ts_language_field_count(self: *const Language) u32;
extern fn ts_language_field_id_for_name(self: *const Language, name: [*]const u8, name_length: u32) u16;
extern fn ts_language_field_name_for_id(self: *const Language, id: u16) ?[*:0]const u8;
extern fn ts_language_metadata(self: *const Language) ?*const LanguageMetadata;
extern fn ts_language_name(self: *const Language) ?[*:0]const u8;
extern fn ts_language_next_state(self: *const Language, state: u16, symbol: u16) u16;
extern fn ts_language_state_count(self: *const Language) u32;
extern fn ts_language_subtypes(self: *const Language, supertype: u16, length: *u32) [*c]const u16;
extern fn ts_language_supertypes(self: *const Language, length: *u32) [*c]const u16;
extern fn ts_language_symbol_count(self: *const Language) u32;
extern fn ts_language_symbol_for_name(self: *const Language, string: [*]const u8, length: u32, is_named: bool) u16;
extern fn ts_language_symbol_name(self: *const Language, symbol: u16) ?[*:0]const u8;
extern fn ts_language_symbol_type(self: *const Language, symbol: u16) SymbolType;
// extern fn ts_lookahead_iterator_new(self: *const Language, state: u16) ?*LookaheadIterator;
