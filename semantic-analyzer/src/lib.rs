extern crate parser;

use core::fmt;

use camino::Utf8PathBuf;
use tree_sitter::Parser;

type TreeSitterTree = tree_sitter::Tree;
type TreeSitterNode<'a> = tree_sitter::Node<'a>;

fn create_parser() -> Parser {
    let mut parser = Parser::new();
    parser
        .set_language(&parser::LANGUAGE.into())
        .expect("Error loading Canapea parser");
    parser
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Config {}

impl Default for Config {
    fn default() -> Self {
        Config {}
    }
}

#[derive(Clone, Debug)]
pub struct Nursery {
    config: Config,
    saplings: Vec<Sapling>,
}

impl<'a> IntoIterator for &'a Nursery {
    type Item = &'a Sapling;

    type IntoIter = std::slice::Iter<'a, Sapling>;

    fn into_iter(self) -> Self::IntoIter {
        self.saplings.iter()
    }
}

// impl<'a> IntoIterator for &'a mut Parent {
//     type Item = &'a mut Child;

//     type IntoIter = std::slice::IterMut<'a, Child>;

//     fn into_iter(self) -> Self::IntoIter {
//         self.children.iter_mut()
//     }
// }

type Code = Vec<u8>;

#[derive(Clone, Debug)]
pub struct Sapling {
    src_file: Option<Utf8PathBuf>,
    src_code: Code,
    parse_tree: Option<TreeSitterTree>,
    uri: Option<String>,
}

impl Sapling {
    pub fn try_from(code: Code) -> Result<Sapling, BoundaryError> {
        let mut parser = create_parser();
        match parser.parse(&code, None) {
            Some(tree) => Ok(Self {
                parse_tree: Some(tree),
                src_file: None,
                src_code: code,
                uri: None,
            }),
            None => Err(BoundaryError::TreeCouldNotBeParsed),
        }
    }
    // pub fn src_file(&self) -> Option<Utf8PathBuf> {
    //     self.src_file.clone()
    // }
    // pub fn src_code(&self) -> Code {
    //     self.src_code.clone()
    // }
}

#[derive(Debug)]
pub enum BoundaryError {
    TreeCouldNotBeParsed,
}

impl fmt::Display for BoundaryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BoundaryError::TreeCouldNotBeParsed => {
                write!(f, "Code could not be parsed.")
            }
        }
    }
}

impl fmt::Display for Sapling {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match &self.parse_tree {
            Some(tree) => {
                let root = tree.root_node();
                write!(f, "{root:#}")
            }
            None => write!(f, "(Tree empty)"),
        }
    }
}

struct Node<'a> {
    node: TreeSitterNode<'a>,
}

impl<'a> Node<'a> {
    pub fn from(&self, node: TreeSitterNode<'a>) -> Self {
        Self { node }
    }
}

// impl<'a> IntoIterator for &'a Tree {
//     type Item = &'a Node;

//     type IntoIter = std::slice::Iter<'a, Node>;

//     fn into_iter(self) -> Self::IntoIter {
//         if self.parse_tree.is_none() {
//             return iter::empty();
//         }
//         let tree = self.parse_tree.expect("Should not happen");
//         let cursor = tree.walk();

//     }
// }

// impl fmt::Debug for EnrichedTree {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         let root = self.parse_tree.root_node();
//         write!(f, "{{Tree {:?}}}", root)
//     }
// }

// impl Clone for EnrichedTree {
//     fn clone(&self) -> Self {
//         Self {
//             parse_tree: self.parse_tree.clone(),
//         }
//     }
// }

#[derive(Debug)]
pub struct Seed {
    path: Option<Utf8PathBuf>,
    code: Code,
}

impl Seed {
    pub fn from(path: Option<Utf8PathBuf>, code: Code) -> Seed {
        Self { path, code }
    }
}

impl Default for Nursery {
    fn default() -> Self {
        Self {
            config: Config::default(),
            saplings: Vec::new(),
        }
    }
}

impl Nursery {
    pub fn from<T>(seeds: T, maybe_config: Option<Config>) -> Nursery
    where
        T: Iterator<Item = Seed>,
    {
        let config = maybe_config.unwrap_or_default();
        let mut parser = create_parser();

        let saplings = seeds
            .map(|s| {
                let Seed { path, code } = s;
                let uri = path.clone().map_or(None, |p| Some(p.to_string()));
                let src_code = code.clone();
                match parser.parse(&src_code, None) {
                    Some(tree) => Sapling {
                        uri: uri.clone(),
                        src_file: path.clone(),
                        src_code,
                        parse_tree: Some(tree),
                    },
                    None => {
                        let src_file = path.clone();
                        print!(
                            "AST for file '{src_file:#?}' could not be parsed"
                        );
                        Sapling {
                            uri: uri.clone(),
                            src_file,
                            src_code,
                            parse_tree: None,
                        }
                    }
                }
            })
            .collect();

        Nursery { config, saplings }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
