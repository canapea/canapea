use std::fmt::Debug;
use std::fs;
use std::path::Path;

use sem::create_parser;

// TODO: Proper error handling
pub fn generate_ast_for_tests<P, T>(
    paths: T,
) -> impl Iterator<Item = (P, String)>
where
    P: AsRef<Path>,
    P: Debug,
    T: Iterator<Item = P>,
{
    let mut parser = create_parser();

    // paths.into_iter()
    paths
        .map(move |p| {
            let res = fs::read(&p);
            (p, res)
        })
        .filter_map(|(p, res)| match res {
            Ok(txt) => Some((p, txt)),
            Err(err) => {
                print!("{err:#?}");
                None
            }
        })
        .filter_map(move |(p, txt)| match parser.parse(txt, None) {
            Some(tree) => Some((p, tree)),
            None => {
                print!("AST for file '{p:#?}' could not be parsed");
                None
            }
        })
        .map(|(p, ast)| {
            let root = ast.root_node();
            (p, format!("{root:#}"))
        })
}
