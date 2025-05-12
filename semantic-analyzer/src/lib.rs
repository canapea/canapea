extern crate parser;
mod traverse;

use core::fmt;
use std::collections::HashMap;

use camino::Utf8PathBuf;
use hex;
use sha2::{Digest, Sha256};
use traverse::{Order, traverse};
use tree_sitter::Parser;

type TSTree = tree_sitter::Tree;
type TSNode<'a> = tree_sitter::Node<'a>;
type TSRange = tree_sitter::Range;
type TSNodeId = usize;

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

type Code = Vec<u8>;

#[derive(Clone, Debug, Hash, PartialEq, Eq)]
pub struct CodeDigest(String);

impl CodeDigest {
    fn from_code(code: &Code) -> CodeDigest {
        let hash = Sha256::digest(code);

        CodeDigest(hex::encode(hash))
    }
}


#[derive(Clone, Debug)]
pub struct Sapling {
    seed_id: SeedId,
    parse_tree: Option<TSTree>,
    src_file: SeedPath,
    src_code: Code,
}

impl Sapling {
    pub fn from(code: Code) -> Sapling {
        let mut parser = create_parser();
        match parser.parse(&code, None) {
            Some(tree) => Self {
                seed_id: SeedId::create_anonymous(&code),
                parse_tree: Some(tree),
                src_file: SeedPath::UnspecifiedPath,
                src_code: code,
            },
            None => Self {
                seed_id: SeedId::create_anonymous(&code),
                parse_tree: None,
                src_file: SeedPath::UnspecifiedPath,
                src_code: code,
            },
        }
    }
    // pub fn src_file(&self) -> Option<Utf8PathBuf> {
    //     self.src_file.clone()
    // }
    // pub fn src_code(&self) -> Code {
    //     self.src_code.clone()
    // }
}

impl fmt::Display for Sapling {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match &self.parse_tree {
            Some(tree) => {
                let root = tree.root_node();
                write!(f, "{root:#}")
            }
            None => {
                write!(f, "(source_file)")
            }
        }
    }
}

#[derive(Clone, Debug)]
pub struct Seed {
    id: SeedId,
    path: SeedPath,
    code: Code,
}

#[derive(Clone, Debug)]
pub enum SeedPath {
    UnspecifiedPath,
    FilePath(Utf8PathBuf),
}

#[derive(Clone, Debug, Hash, PartialEq, Eq)]
pub enum SeedId {
    Anonymous(CodeDigest),
    FileUri(String, CodeDigest),
}

impl SeedId {
    fn create_anonymous(code: &Code) -> SeedId {
        Self::Anonymous(CodeDigest::from_code(code))
    }
    fn create_file_uri(path: &Utf8PathBuf, code: &Code) -> SeedId {
        Self::FileUri(
            format!("file://{}", path.to_string()),
            CodeDigest::from_code(code),
        )
    }
}

impl Seed {
    pub fn from_code(code: Code) -> Seed {
        Self {
            id: SeedId::create_anonymous(&code),
            path: SeedPath::UnspecifiedPath,
            code,
        }
    }
    pub fn from(path: Utf8PathBuf, code: Code) -> Seed {
        Self {
            id: SeedId::create_file_uri(&path, &code),
            path: SeedPath::FilePath(path),
            code,
        }
    }
}

// impl Default for Nursery {
//     fn default() -> Self {
//         Self {
//             config: Config::default(),
//             saplings: HashMap::default(),
//         }
//     }
// }

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

impl Nursery {
    pub fn from<T>(seeds: T, maybe_config: Option<Config>) -> Nursery
    where
        T: Iterator<Item = Seed>,
    {
        let config = maybe_config.unwrap_or_default();
        let mut parser = create_parser();

        let saplings = seeds
            .map(|s| {
                let Seed { id, path, code } = s;
                let src_code = code.clone();
                match parser.parse(&src_code, None) {
                    Some(tree) => Sapling {
                        seed_id: id,
                        parse_tree: Some(tree),
                        src_code,
                        src_file: path.clone(),
                    },
                    None => {
                        let src_file = path.clone();
                        print!(
                            "AST for file '{src_file:#?}' could not be parsed"
                        );
                        Sapling {
                            seed_id: id,
                            parse_tree: None,
                            src_code,
                            src_file,
                        }
                    }
                }
            })
            .collect();

        Nursery { config, saplings }
    }
}

pub struct Forest<'a> {
    config: Config,
    trees_by_id: HashMap<SeedId, Tree<'a>>,
    // saplings_by_id: HashMap<SeedId, Sapling>>,
    // nursery: Nursery,
    // trees: Vec<Tree<'a>>,
    // ts_tree_refs: Vec<TSNodeId>,
}

impl<'a> Forest<'a> {
    pub fn from_seeds<T>(seeds: T, maybe_config: Option<Config>) -> Self
    where
        T: Iterator<Item = Seed>,
    {
        let nursery = Nursery::from(seeds, maybe_config);
        let forest = Forest::from_nursery(nursery);
        forest
    }

    pub fn from_nursery(nursery: Nursery) -> Self {
        let config = *&nursery.config.clone();
        let mut trees_by_id = HashMap::default();
        // let saplings = nursery.into_iter().map(|s| s.to_owned());

        for sapling in nursery.into_iter() {
            // for sapling in saplings {
            let tree = Tree::from(sapling);
            trees_by_id.insert(sapling.seed_id.clone(), tree);
        }

        Self {
            config,
            trees_by_id,
        }
    }

    pub fn visit(&self, callback: impl Fn(String) -> ()) {
        for (_id, tree) in &self.trees_by_id {
            match &tree.kind {
                TreeKind::SourceCode { ts_tree, .. }
                | TreeKind::SourceFile { ts_tree, .. } => {
                    for node in traverse(ts_tree.walk(), Order::Pre) {
                        callback(node.to_sexp());
                    }
                }
                _ => (),
            };
        }
    }
}

// trait Visitor<'a> {
//     fn visit(node: Node<'a>) -> ();
// }

// impl<'a> IntoIterator for &'a Forest<'a> {
//     type Item = &'a (&'a SeedId, &'a Tree<'a>);

//     type IntoIter = std::slice::Iter<'a, (&'a SeedId, &'a Tree<'a>)>;

//     fn into_iter(self) -> Self::IntoIter {
//         self.trees_by_id.iter().map(|(k, v)| {
//             (k, v)
//         }).collect::<Vec<_>>().to_owned().iter()
//     }
// }

struct Tree<'a> {
    seed_id: SeedId,
    kind: TreeKind<'a>,
}

enum TreeKind<'a> {
    SourceCode {
        root: Node<'a>,
        src_code: Code,
        state: TreeState,
        ts_tree: TSTree,
        // ts_tree_ref: TSNodeId,
    },
    SourceFile {
        file: Utf8PathBuf,
        root: Node<'a>,
        src_code: Code,
        state: TreeState,
        ts_tree: TSTree,
        // ts_tree_ref: TSNodeId,
    },
    UnrecognizedCode {
        src_code: Code,
    },
    UnrecognizedFile {
        file: Utf8PathBuf,
    },
}

impl<'a> Tree<'a> {
    pub fn from(sapling: &Sapling) -> Self {
        let kind = match &sapling.parse_tree {
            Some(tree) => {
                let root = Node::from(tree.root_node());
                match &sapling.src_file {
                    SeedPath::FilePath(file) => TreeKind::SourceFile {
                        file: file.clone(),
                        root,
                        src_code: sapling.src_code.clone(),
                        state: TreeState::default(),
                        ts_tree: tree.to_owned(),
                    },
                    SeedPath::UnspecifiedPath => TreeKind::SourceCode {
                        root,
                        src_code: sapling.src_code.clone(),
                        state: TreeState::default(),
                        ts_tree: tree.to_owned(),
                    },
                }
            }
            None => match &sapling.src_file {
                SeedPath::FilePath(file) => {
                    TreeKind::UnrecognizedFile { file: file.clone() }
                }
                SeedPath::UnspecifiedPath => TreeKind::UnrecognizedCode {
                    src_code: sapling.src_code.clone(),
                },
            },
        };
        Self {
            seed_id: sapling.seed_id.clone(),
            kind,
            // ts_tree_ref: s.parse_tree
        }
    }
}

struct Node<'a> {
    // node: TreeSitterNode<'a>,
    name_in_grammar: &'a str,
    id_in_grammar: u16,
    ts_range: TSRange,
    ts_ref: TSNodeId,
}

impl<'a> Node<'a> {
    pub fn from(node: TSNode) -> Self {
        Self {
            id_in_grammar: node.grammar_id(),
            name_in_grammar: node.grammar_name(),
            ts_range: node.range(),
            ts_ref: node.id(),
        }
    }
}


struct TreeState {}

impl Default for TreeState {
    fn default() -> Self {
        Self {
            // modules: HashMap::default(),
        }
    }
}

// struct ModuleState {
//     module_id: ModuleId,
// }

// // TODO: Constrain what the actual possible String content can be
// type ModulePath = String;
// type StringContent = String;
// type CapabilityName = String;
// type QualifiedImportNamespace = String;
// type CustomTypeName = String;
// type CustomTypeConstructorName = String;
// type TypeDeclarationName = String;
// type FunctionName = String;

// enum ModuleId {
//     Unknown,
//     DevelopmentModule(ModulePath),
//     UserModule(ModulePath),
// }

// enum CompilationUnit {
//     ModuleCompilationUnit {
//         module_id: ModuleId,
//         module_docs: Option<MultilineStringLiteral>,
//         module_declaration: ModuleDeclaration,
//         imports: Vec<ModuleImportDeclaration>,
//         declarations: Vec<Declaration>,
//     },
// }

// struct MultilineStringLiteral {
//     content: StringContent,
// }

// enum ModuleDeclaration {
//     ApplicationDeclaration {
//         capability_requests: Vec<CapabilityRequest>,
//         exports: Vec<ApplicationExportDeclaration>,
//     },
//     DevelopmentModuleDeclaration {
//         declared_id: ModuleId,
//         exports: Vec<ModuleExportDeclaration>,
//     },
//     ModuleDeclaration {
//         declared_id: ModuleId,
//         exports: Vec<ModuleExportDeclaration>,
//     },
// }

// struct CapabilityRequest {
//     provided_by: CompilationUnit,
//     capability: Capability,
// }

// enum CapabilityArg {
//     TypeParameterArg,
//     CustomTypeArg,
//     StringLiteralTypeArg,
//     IntLiteralTypeArg,
//     DecimalLiteralTypeArg,
// }

// struct Capability {
//     name: CapabilityName,
//     params: Vec<CapabilityArg>,
// }

// enum ApplicationExportDeclaration {
//     FunctionApplicationExportDeclaration,
// }

// enum ModuleExportDeclaration {
//     FunctionModuleExportDeclaration,
//     TypeModuleExportDeclaration,
// }

// struct ModuleImportDeclaration {
//     import_module: ModuleId,
//     qualified_namespace: QualifiedImportNamespace,
//     exposing: Vec<ModuleImportExposingStatement>,
// }

// enum ModuleImportExposingStatement {
//     ImportExposingType {
//         expose_as: ExposeTypeAs,
//         constructors: Vec<ExposeTypeConstructor>,
//     },
// }

// enum ExposeTypeAs {
//     ExposeTypeAsTypeName,
//     ExposeRenamedTypeName {
//         name: CustomTypeName,
//     },
// }

// enum ExposeTypeConstructor {
//     ExposeTypeConstructorName,
//     ExposeRenamedTypeConstructor {
//         name: CustomTypeConstructorName,
//     },
// }

// struct TypeDeclaration {

// }

// enum Declaration {
//     FreeTypeDeclaration {
//         type_annotation: TypeDeclaration,
//     },
//     FunctionDeclaration {
//         type_annotation: TypeDeclaration,
//         name: FunctionName,
//         params: Vec<FunctionParameter>,
//         body: BlockBody,
//     },
//     LetExpression,
//     ToplevelDocs,
//     CustomTypeDeclaration,
//     RecordDeclaration,
//     ExpectAssertion,
//     ExpectTodoExpression,
//     // TODO: Development modules only?
//     TypeConceptDeclaration,
//     TypeConceptInstanceDeclaration,
//     TypeConstructorConceptDeclaration,
// }

// struct BlockBody {

// }

// struct FunctionParameter {

// }

// impl<'a> IntoIterator for &'a mut Parent {
//     type Item = &'a mut Child;

//     type IntoIter = std::slice::IterMut<'a, Child>;

//     fn into_iter(self) -> Self::IntoIter {
//         self.children.iter_mut()
//     }
// }

// #[derive(Debug)]
// pub enum BoundaryError {
//     TreeCouldNotBeParsed,
// }

// impl fmt::Display for BoundaryError {
//     fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
//         match self {
//             BoundaryError::TreeCouldNotBeParsed => {
//                 write!(f, "Code could not be parsed.")
//             }
//         }
//     }
// }

// #[derive(Clone, Debug)]
// pub struct Sapling {
//     parse_tree: Option<TreeSitterTree>,
//     src_file: Option<Utf8PathBuf>,
//     src_code: Code,
//     uri: Option<String>,
// }

// #[derive(Clone, Debug)]
// pub struct SaplingView(Sapling);

// #[derive(Clone, Debug)]
// enum Sapling {
//     Healthy(Healthy),
//     Broken(Broken),
// }

// #[derive(Clone, Debug)]
// struct Healthy {
//     parse_tree: TreeSitterTree,
//     src_file: Option<Utf8PathBuf>,
//     src_code: Code,
//     uri: Option<String>,
// }

// #[derive(Clone, Debug)]
// struct Broken {
//     src_file: Option<Utf8PathBuf>,
//     src_code: Code,
//     uri: Option<String>,
// }

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

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
