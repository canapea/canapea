extern crate tree_sitter_canapea;

use tree_sitter::Parser;


pub(crate) fn create_parser() -> Parser {
    let mut parser = Parser::new();
    parser
        .set_language(&tree_sitter_canapea::LANGUAGE.into())
        .expect("Error loading Canapea parser");
    parser
}
