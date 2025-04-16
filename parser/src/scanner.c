/// (c) 2025 Martin Feineis
/// Cobbled together with the help of these example projects:
/// * Special thanks to https://github.com/elm-tooling/tree-sitter-elm/
/// * https://github.com/tree-sitter/tree-sitter-python
/// * https://github.com/tree-sitter/tree-sitter-haskell

#include "tree_sitter/parser.h"
#include "tree_sitter/alloc.h"
#include "tree_sitter/array.h"

#include <assert.h>
#include <string.h>

typedef struct {
    uint32_t indent_length;
    Array(uint8_t) indents;
} Scanner;

#pragma region Scanner type "members"

static void destroy(Scanner* scanner) {
    scanner->indent_length = 0;
    array_delete(&scanner->indents);

    ts_free(scanner);
}

static unsigned serialize(Scanner* scanner, char* buffer) {
    size_t indent_length_size = sizeof(scanner->indent_length);
    if (3 + indent_length_size + scanner->indents.size
        >= TREE_SITTER_SERIALIZATION_BUFFER_SIZE) {
        return 0;
    }

    size_t size = 0;
    buffer[size++] = (char)indent_length_size;
    if (indent_length_size > 0) {
        memcpy(&buffer[size], &scanner->indent_length, indent_length_size);
    }
    size += indent_length_size;

    uint32_t iter = 1;
    for (; iter < scanner->indents.size
            && size < TREE_SITTER_SERIALIZATION_BUFFER_SIZE
        ; ++iter
    ) {
        uint8_t indent_value = *array_get(&scanner->indents, iter);
        buffer[size++] = (char)indent_value;
    }

    return size;
}

static void deserialize(Scanner* scanner, const char* buffer, unsigned length) {
    scanner->indent_length = 0;
    array_delete(&scanner->indents);
    array_push(&scanner->indents, 0);

    if (length == 0) {
        return;
    }

    size_t size = 0;

    size_t indent_length_size = (unsigned char)buffer[size++];
    if (indent_length_size > 0) {
        memcpy(&scanner->indent_length, &buffer[size], indent_length_size);
        size += indent_length_size;
    }

    for (; size + 1 < length; ++size) {
        uint8_t indent_value = (unsigned char)buffer[size];
        array_push(&scanner->indents, indent_value);
    }

    assert(size == length);
}

#pragma endregion

#pragma region Utilities

static inline void advance(TSLexer* lexer) { lexer->advance(lexer, false); }

static void advance_to_line_end(TSLexer* lexer) {
    while (true) {
        if (lexer->lookahead == '\n' || lexer->eof(lexer)) {
            break;
        }
        advance(lexer);
    }
}

static inline void skip(TSLexer* lexer) { lexer->advance(lexer, true); }

static bool is_space(TSLexer* lexer) {
    return lexer->lookahead == ' '
        || lexer->lookahead == '\r'
        || lexer->lookahead == '\n';
}

#pragma endregion

enum TokenType {
    // INDENT_BLOCK_OPEN,
    // INDENT_BLOCK_CLOSE,
    IS_IN_ERROR_RECOVERY,
};

static bool scan(Scanner* scanner, TSLexer* lexer, const bool* valid_symbols) {
    if (valid_symbols[IS_IN_ERROR_RECOVERY]){
        // opt-out of manual error recovery, let the internal lexer handle that
        return false;
    }

    // TODO: Actually implement scanning stuff
    return false;
}

#pragma region tree-sitter Scanner raw C interface

bool tree_sitter_canapea_external_scanner_scan(
    void* payload,
    TSLexer* lexer,
    const bool* valid_symbols
) {
    Scanner* scanner = (Scanner*)payload;
    return scan(scanner, lexer, valid_symbols);
}

void* tree_sitter_canapea_external_scanner_create() {
    return (Scanner*)ts_calloc(1, sizeof(Scanner));
}

void tree_sitter_canapea_external_scanner_destroy(void* payload) {
    Scanner* scanner = (Scanner*)payload;
    destroy(scanner);
}

unsigned tree_sitter_canapea_external_scanner_serialize(
    void* payload,
    char* buffer
) {
    Scanner* scanner = (Scanner*)payload;
    return serialize(scanner, buffer);
}

void tree_sitter_canapea_external_scanner_deserialize(
    void* payload,
    const char* buffer,
    unsigned length
) {
    Scanner* scanner = (Scanner*)payload;
    deserialize(scanner, buffer, length);
}

#pragma endregion
