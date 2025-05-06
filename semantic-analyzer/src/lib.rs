extern crate parser;

use core::fmt;

use camino::Utf8PathBuf;
use tree_sitter::Parser;

type TreeSitterTree = tree_sitter::Tree;

pub fn create_parser() -> Parser {
    let mut parser = Parser::new();
    parser
        .set_language(&parser::LANGUAGE.into())
        .expect("Error loading Canapea parser");
    parser
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Config {

}

impl Default for Config {
    fn default() -> Self {
        Config {

        }
    }
}

#[derive(Clone, Debug)]
pub struct Forest {
    config: Config,
    trees: Vec<Tree>,
}

impl<'a> IntoIterator for &'a Forest {
    type Item = &'a Tree;

    type IntoIter = std::slice::Iter<'a, Tree>;

    fn into_iter(self) -> Self::IntoIter {
        self.trees.iter()
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
pub struct Tree {
    src_file: Option<Utf8PathBuf>,
    src_code: Code,
    parse_tree: Option<TreeSitterTree>,
    uri: Option<String>,
}

#[derive(Debug)]
pub enum BoundaryError {
    TreeCouldNotBeParsed,
}

impl fmt::Display for BoundaryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BoundaryError::TreeCouldNotBeParsed => write!(f, "Code could not be parsed."),
        }
    }
}

impl Tree {
    pub fn try_from(code: Code) -> Result<Tree, BoundaryError> {
        let mut parser = create_parser();
        match parser.parse(&code, None) {
            Some(tree) => Ok(Self {
                parse_tree: Some(tree),
                src_file: None,
                src_code: code,
                uri: None,
            }),
            None => Err(BoundaryError::TreeCouldNotBeParsed)
        }
    }
    pub fn src_file(&self) -> Option<Utf8PathBuf> {
        self.src_file.clone()
    }
    pub fn src_code(&self) -> Code {
        self.src_code.clone()
    }
}

impl fmt::Display for Tree {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match &self.parse_tree {
            Some(tree) => {
                let root = tree.root_node();
                write!(f, "{root:#}")
            },
            None => write!(f, "(Tree empty)")
        }
    }
}

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
pub struct Seed
{
    path: Option<Utf8PathBuf>,
    code: Code
}

impl Seed {
    pub fn from(path: Option<Utf8PathBuf>, code: Code) -> Seed {
        Self {
            path,
            code,
        }
    }
}

impl Default for Forest {
    fn default() -> Self {
        Self {
            config: Config::default(),
            trees: Vec::new(),
        }
    }
}

impl Forest {
    pub fn from<S, T>(seeds: T, maybe_config: Option<Config>) -> Forest
        where
            S : AsRef<Seed>,
            T : Iterator<Item = S>,
    {
        let config = maybe_config.unwrap_or_default();
        let mut parser = create_parser();

        let trees = seeds.map(|s| {
            let Seed { path, code}= s.as_ref();
            let uri = path.clone().map_or(None, |p|Some(p.to_string()));
            let src_code = code.clone();
            match parser.parse(&src_code, None) {
                Some(tree) => Tree {
                    uri: uri.clone(),
                    src_file: path.clone(),
                    src_code,
                    parse_tree: Some(tree),
                },
                None => {
                    let src_file = path.clone();
                    print!("AST for file '{src_file:#?}' could not be parsed");
                    Tree {
                        uri: uri.clone(),
                        src_file,
                        src_code,
                        parse_tree: None,
                    }
                }
            }
        }).collect();

        Forest {
            config,
            trees,
        }
    }
}


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
