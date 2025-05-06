extern crate parser;

use tree_sitter::Parser;

pub fn create_parser() -> Parser {
    let mut parser = Parser::new();
    parser
        .set_language(&parser::LANGUAGE.into())
        .expect("Error loading Canapea parser");
    parser
}

pub fn enrich() {
    let _parser = create_parser();
}
