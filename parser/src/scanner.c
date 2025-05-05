/// (c) 2025 Martin Feineis
/// Cobbled together with the help of these example projects:
/// * Special thanks to https://github.com/elm-tooling/tree-sitter-elm/
/// * https://github.com/tree-sitter/tree-sitter-python
/// * https://github.com/tree-sitter/tree-sitter-haskell

#include "tree_sitter/parser.h"
#include "tree_sitter/alloc.h"
#include "tree_sitter/array.h"

#include <assert.h>

// TODO: For perf it'd be advantageous, if we could just memcpy the whole state
typedef struct {
    uint32_t indent_length;
    uint32_t blocks_to_close;
    Array(uint8_t) indents;
} Scanner;

#pragma region Scanner type "members"

static void destroy(Scanner* scanner) {
    scanner->indent_length = 0;
    scanner->blocks_to_close = 0;
    array_delete(&scanner->indents);

    ts_free(scanner);
}

static unsigned serialize(Scanner* scanner, char* buffer) {
    // FIXME: Not sure where this heuristic 3 comes from but it seems to work
    if (3 // scanner->indent_length
        + 3 // scanner->blocks_to_close
        + scanner->indents.size 
        >= TREE_SITTER_SERIALIZATION_BUFFER_SIZE
    ) {
        return 0;
    }

    size_t size = 0;
    {
        // Push (sizeof(indent_length))
        size_t indent_length_size = sizeof(scanner->indent_length);
        buffer[size++] = (char)indent_length_size;
        if (indent_length_size > 0) {
            // Push (indent_length)
            memcpy(&buffer[size], &scanner->indent_length, indent_length_size);
        }
        size += indent_length_size;
    }
    {
        // Push (sizeof(blocks_to_close))
        size_t blocks_to_close_size = sizeof(scanner->blocks_to_close);
        if (blocks_to_close_size > UINT8_MAX) {
            // This is a silly amount of blocks but better safe than sorry
            blocks_to_close_size = UINT8_MAX;
        }
        buffer[size++] = (char)blocks_to_close_size;
        if (blocks_to_close_size > 0) {
            // Push (blocks_to_close)
            memcpy(&buffer[size], &scanner->blocks_to_close, blocks_to_close_size);
        }
        size += blocks_to_close_size;
    }
    {
        // Push(...indents), starting with 1
        for (uint32_t iter = 1
            ; iter != scanner->indents.size
                && size < TREE_SITTER_SERIALIZATION_BUFFER_SIZE
            ; ++iter
        ) {
            // Push (indents[iter])
            uint8_t indent_value = *array_get(&scanner->indents, iter);
            buffer[size++] = (char)indent_value;
        }
    }
    return size;
}

static void deserialize(Scanner* scanner, const char* buffer, unsigned length) {
    scanner->indent_length = 0;
    scanner->blocks_to_close = 0;
    array_delete(&scanner->indents);
    array_push(&scanner->indents, 0);

    if (length == 0) {
        return;
    }

    size_t size = 0;
    {
        // Read(sizeof(indent_length))
        size_t indent_length_size = (unsigned char)buffer[size++];
        if (indent_length_size > 0) {
            // Read (indent_length)
            memcpy(&scanner->indent_length, &buffer[size], indent_length_size);
            size += indent_length_size;
        }
    }
    {
        // Read(sizeof(blocks_to_close))
        size_t blocks_to_close_size = (unsigned char)buffer[size++];
        if (blocks_to_close_size > 0) {
            // Read (blocks_to_close)
            memcpy(&scanner->blocks_to_close, &buffer[size], blocks_to_close_size);
            size += blocks_to_close_size;
        }
    }
    {
        // Read (...indents)
        for (; size < length; ++size) {
            // Read (indent[size])
            uint8_t indent_value = (unsigned char)buffer[size];
            array_push(&scanner->indents, indent_value);
        }
    }
    assert(size == length);
}

#pragma endregion

#pragma region Utilities

static inline void skip(TSLexer* lexer) { lexer->advance(lexer, true); }

static inline void advance(TSLexer *lexer) { lexer->advance(lexer, false); }

static void advance_to_line_end(TSLexer *lexer) {
    while (true) {
        if (lexer->lookahead == '\n' || lexer->eof(lexer)) {
            break;
        }
        advance(lexer);
    }
}

#pragma endregion

enum TokenType {
    IMPLICIT_BLOCK_OPEN,
    IMPLICIT_BLOCK_CLOSE,
    IS_IN_ERROR_RECOVERY,
};

static bool scan(Scanner* scanner, TSLexer* lexer, const bool* valid_symbols) {
    if (valid_symbols[IS_IN_ERROR_RECOVERY]){
        // opt-out of manual error recovery, let the internal lexer handle that
        return false;
    }

    // Commenting this in is a cheeky way to allow us to quickly look for
    // compiler warnings that tree-sitter doesn't treat as errors
    // cause_a_compile_error_to_check_for_warnings(&scanner->indents);

    // First handle all blocks that need to be closed due to a previous scan op
    if (scanner->blocks_to_close > 0 && valid_symbols[IMPLICIT_BLOCK_CLOSE]) {
        scanner->blocks_to_close -= 1;
        lexer->result_symbol = IMPLICIT_BLOCK_CLOSE;
        return true;
    }

    // Since we're not looking for actual tokens but just checking for whitespace
    // and follow-up non-whitespace the internal lexer always stays here
    lexer->mark_end(lexer);

    // Check if we have newlines and how much indentation
    bool has_newline = false;
    bool _can_call_mark_end = true;

    // newline_search:
    while (true) {
        if (lexer->lookahead == ' ' || lexer->lookahead == '\r') {
            skip(lexer);
        }
        else if (lexer->lookahead == '\n') {
            skip(lexer);
            has_newline = true;

            // column_search:
            while (true) {
                if (lexer->lookahead == ' ') {
                    skip(lexer);
                }
                else {
                    scanner->indent_length = lexer->get_column(lexer);
                    break; // column_search;
                }
            }
        }
        else if (lexer->lookahead == '#') {
            // Scan past line comments. As far as the special token
            // types we're scanning for here are concerned line comments
            // are like whitespace. There is nothing useful to be
            // learned from, say, their indentation. So we advance past
            // them here.
            //
            // The one thing we need to keep in mind is that we should
            // not call `lexer->mark_end(lexer)` after this point, or
            // the comment will be lost.
            _can_call_mark_end = false;
            advance_to_line_end(lexer);
        }
        else if (lexer->eof(lexer)) {
            if (valid_symbols[IMPLICIT_BLOCK_CLOSE]) {
                lexer->result_symbol = IMPLICIT_BLOCK_CLOSE;
                return true;
            }

            break;
        }
        else {
            break; // newline_search;
        }
    }

    if (valid_symbols[IMPLICIT_BLOCK_OPEN] && !lexer->eof(lexer)) {
        array_push(&scanner->indents, lexer->get_column(lexer));
        lexer->result_symbol = IMPLICIT_BLOCK_OPEN;
        return true;
    }

    if (has_newline) {
        // We've seen a newline, now it's time to check, if we need to close
        // multiple blocks to get back up to the right level
        scanner->blocks_to_close = 0;

        // track_closed_blocks:
        while (scanner->indent_length <= *array_back(&scanner->indents)) {
            if (scanner->indent_length == *array_back(&scanner->indents)) {
                // If the indentation didn't change we do nothing
                break; // track_closed_blocks;
            }
            if (scanner->indent_length < *array_back(&scanner->indents)) {
                // Less indentation means we need to close at least one block
                array_pop(&scanner->indents);
                scanner->blocks_to_close += 1;
            }
        }

        // Handle the first closing block now, if any, if there are more
        // they will be handled on the next scan operation because
        // we can only ever "return" one token per scan
        if (scanner->blocks_to_close > 0 && valid_symbols[IMPLICIT_BLOCK_CLOSE]) {
            scanner->blocks_to_close -= 1;
            lexer->result_symbol = IMPLICIT_BLOCK_CLOSE;
            return true;
        }
        if (lexer->eof(lexer) && valid_symbols[IMPLICIT_BLOCK_CLOSE]) {
            lexer->result_symbol = IMPLICIT_BLOCK_CLOSE;
            return true;
        }
    }

    // Nothing found we can handle, let the internal lexer take over
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
