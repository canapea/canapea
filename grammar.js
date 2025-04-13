/**
 * @file Lang0 grammar for tree-sitter
 * @author Martin Feineis <mfeineis@users.noreply.github.com>
 * @license UPL
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "lang0",

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => "hello"
  }
});
