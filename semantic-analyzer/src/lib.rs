extern crate parser;
mod traverse;

use core::fmt;
use std::collections::HashMap;

use bigdecimal::BigDecimal;
use camino::Utf8PathBuf;
use hex;
use num::BigInt;
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

// TODO: Constrain what the actual possible content can be
type ModuleCanonicalName = String;
type ModulePath = String;
type PackageNamespace = String;
type MultilineStringContent = String;
type CapabilityName = String;
type QualifiedImportNamespace = String;
type CustomTypeName = String;
type CustomTypeConstructorName = CustomTypeName;
type BindingName = String;
type FunctionName = String;
type SimpleRecordKey = String;
// type DontCarePattern = String;
type StringContent = String;
type IntType = BigInt;
type DecimalType = BigDecimal;
type MathsOperatorName = String;
type RecordTypeName = String;
type TypeVariableName = String;
type TypeConceptName = CustomTypeName;
type TypeConceptExpression = CustomTypeExpression;
type TodoTopic = String;

type AppImportDeclaration = ModuleImportDeclaration;
type PackageImportDeclaration = ModuleImportDeclaration;
type DevelopmentModuleImportDeclaration = ModuleImportDeclaration;
type DevelopmentModuleExportDeclaration = ModuleExportDeclaration;

enum ModuleId {
    UnspecifiedModule(ModuleCanonicalName),
    DevelopmentModule(ModuleCanonicalName, ModulePath),
    UserModule(ModuleCanonicalName, ModulePath),
}

enum PackageId {
    Package(PackageNamespace),
}

enum CompilationUnit {
    AppCompilationUnit {
        capability_requests: Vec<CapabilityRequest>,
        imports: Vec<AppImportDeclaration>,
        exports: Vec<AppExportDeclaration>,
        declarations: Vec<Declaration>,
    },
    PackageCompilationUnit {
        package_id: PackageId,
        imports: Vec<PackageImportDeclaration>,
        exports: Vec<PackageExportDeclaration>,
        declarations: Vec<Declaration>,
    },
    DevelopmentModuleCompilationUnit {
        module_id: ModuleId,
        module_docs: ModuleDocs,
        imports: Vec<DevelopmentModuleImportDeclaration>,
        exports: Vec<DevelopmentModuleExportDeclaration>,
        declarations: Vec<Declaration>,
        development_declarations: Vec<DevelopmentDeclaration>,
    },
    ModuleCompilationUnit {
        module_id: ModuleId,
        module_docs: ModuleDocs,
        imports: Vec<ModuleImportDeclaration>,
        exports: Vec<ModuleExportDeclaration>,
        declarations: Vec<Declaration>,
    },
}

struct ModuleDocs {
    content: Vec<MultilineStringContent>,
}

struct CapabilityRequest {
    provided_by: CompilationUnit,
    capability: Capability,
}

struct Capability {
    name: CapabilityName,
    params: Vec<CapabilityArg>,
}

enum CapabilityArg {
    CustomTypeExpressionCapabilityArg(CustomTypeExpression),
    LiteralExpressionCapabilityArg(LiteralExpression),
}

enum AppExportDeclaration {
    FunctionAppExportDeclaration(BindingName),
}

enum ModuleExportDeclaration {
    FunctionModuleExportDeclaration(BindingName),
    CustomTypeModuleExportDeclaration(CustomTypeName),
}

enum PackageExportDeclaration {
    FunctionPackageExportDeclaration(BindingName),
}

struct ModuleImportDeclaration {
    import_module: ModuleId,
    qualified_namespace: QualifiedImportNamespace,
    exposing: Vec<ModuleImportExposingStatement>,
}

enum ModuleImportExposingStatement {
    ImportExposingType {
        expose_as: ExposeTypeAs,
        constructors: Vec<ExposeTypeConstructorAs>,
    },
}

enum ExposeTypeAs {
    ExposeTypeAsOriginalName,
    ExposeTypeRenamed(CustomTypeName),
}

enum ExposeTypeConstructorAs {
    ExposeTypeConstructorAsOriginalName,
    ExposeTypeConstructorRenamed(CustomTypeConstructorName),
}

enum TypeAnnotation {
    ExplicitTypeAnnotation(ExplicitTypeAnnotation),
    InferredTypeAnnotation(InferredTypeAnnotation),
}

struct ExplicitTypeAnnotation {
    // TODO: TypeAnnotation
}

struct InferredTypeAnnotation {
    // TODO: TypeAnnotation
}

enum Declaration {
    FreeTypeDeclaration(FreeTypeDeclaration),
    FunctionDeclaration(FunctionDeclaration),
    LetDeclaration(LetDeclaration),
    ToplevelDocsDeclaration {
        content: Vec<MultilineStringContent>,
    },
    CustomTypeDeclaration {
        name: CustomTypeName,
        type_variables: Vec<TypeVariable>,
        constructors: Vec<CustomTypeConstructorDeclaration>,
    },
    RecordDeclaration {
        name: RecordTypeName,
        type_variables: Vec<TypeVariable>,
        record_type: RecordTypeExpression,
    },
    ExpectAssertionDeclaration(ExpectAssertion),
    TodoDeclaration(TodoExpression),
}

struct FreeTypeDeclaration {
    type_annotation: TypeAnnotation,
}

struct FunctionDeclaration {
    type_annotation: TypeAnnotation,
    name: FunctionName,
    params: Vec<FunctionParameter>,
    body: BlockBody,
}

struct LetDeclaration {
    binding: LetExpression,
}

struct BinaryOperatorDeclaration {
    type_annotation: TypeAnnotation,
    name: MathsOperatorName,
    params: Vec<FunctionParameter>,
    body: BlockBody,
}

struct BinaryOperatorExpression {
    left: Box<CallOrAtom>,
    op: BinaryOperator,
    right: Box<CallOrAtom>,
}

enum BinaryOperator {
    PipeBinaryOperator,
    MathsBinaryOperator(MathsOperator),
}

enum DevelopmentDeclaration {
    TypeConceptDeclaration {
        name: TypeConceptName,
        type_variables: Vec<TypeVariable>,
        requirements: TypeConceptRequirements,
        implementations: Vec<TypeConceptImplementation>,
    },
    TypeConceptInstanceDeclaration {
        concept_name: TypeConceptName,
        instance_types: Vec<CustomTypeName>,
        implementations: Vec<TypeConceptInstanceImplementation>,
    },
    TypeConstructorConceptDeclaration {
        name: TypeConceptName,
        type_variables: Vec<TypeConstructorConceptTypeVariable>,
        requirements: TypeConceptRequirements,
        implementations: Vec<TypeConstructorConceptImplementation>,
    },
}

enum TypeConstructorConceptTypeVariable {
    TypeVariableTypeConceptTypeVariable(TypeVariable),
    CustomTypeNameTypeConceptVariable(CustomTypeName),
    BuiltinTypeTypeConceptVariable(BuiltinType),
}

enum TypeConceptRequirements {
    TypeConceptRequirements {
        requirements: Vec<TypeConceptRequirement>,
    },
    TypeConceptRequirementsWithConstraints {
        constraints: Vec<TypeConceptConstraint>,
        requirements: Vec<TypeConceptRequirement>,
    },
}

enum TypeConceptRequirement {
    TypeDeclarationTypeConceptRequirement(FreeTypeDeclaration),
}

struct TypeConceptConstraint {
    concept_name: TypeConceptName,
    args: Vec<TypeConceptConstraintArg>,
}

enum TypeConceptConstraintArg {
    TypeVariableTypeConceptConstraintArg(TypeVariable),
    TypeConceptTypeConceptConstraintArg(TypeConceptExpression),
}

enum TypeConceptImplementation {
    FunctionDeclarationTypeConceptImplementation(FunctionDeclaration),
    LetDeclarationTypeConceptImplementation(LetDeclaration),
    BinaryOperatorDeclarationTypeConceptImplementation(
        BinaryOperatorDeclaration,
    ),
}

enum TypeConstructorConceptImplementation {
    FunctionDeclarationTypeConstructorConceptImplementation(
        FunctionDeclaration,
    ),
    LetDeclarationTypeConstructorConceptImplementation(LetDeclaration),
}

enum TypeConceptInstanceImplementation {
    FunctionDeclarationTypeConceptInstanceImplementation(FunctionDeclaration),
    LetDeclarationTypeConceptInstanceImplementation(LetDeclaration),
}

struct TypeVariable {
    name: TypeVariableName,
}

enum CustomTypeConstructorDeclaration {
    CustomTypeConstructor {
        name: CustomTypeConstructorName,
        args: Vec<CustomTypeConstructorArg>,
    },
    CustomTypeConstructorWithAppliedConcepts {
        name: CustomTypeConstructorName,
        args: Vec<CustomTypeConstructorArg>,
        concepts: Vec<AppliedContructorConcept>,
    },
}

struct RecordTypeExpression {
    entries: HashMap<SimpleRecordKey, RecordTypeEntry>,
}

enum RecordTypeEntry {
    TypeVariableRecordTypeEntry(TypeVariable),
    CustomTypeExpressionRecordTypeEntry(CustomTypeExpression),
    BuiltinTypeRecordTypeEntry(BuiltinType),
}

enum BuiltinType {
    DecimalBuiltinType(DecimalType),
    IntBuiltinType(IntType),
}

enum CustomTypeConstructorArg {
    CustomTypeNameConstructorArg(CustomTypeName),
    TypeVariableConstructorArg(TypeVariable),
    RecordTypeExpressionConstructorArg(RecordTypeExpression),
    CustomTypeExpressionConstructorArg(CustomTypeExpression),
    BuiltinTypeConstructorArg(BuiltinType),
}

struct CustomTypeExpression {
    name: CustomTypeConstructorName,
    args: Vec<CustomTypeConstructorArg>,
}

// TODO: CustomTypeTrivialValue seems silly, surely we can represent this better?
enum AppliedContructorConcept {
    CustomTypeTrivialValueExpressionAppliedConstructorConcept(
        CustomTypeTrivialValueExpression,
    ),
    ConstructorConceptApplicationExpressionAppliedConstructorConcept(
        ConstructorConceptApplicationExpression,
    ),
}

struct LetExpression {
    type_annotation: TypeAnnotation,
    binding: LetBinding,
    body: BlockBody,
}

struct ExpectAssertion {
    condition: ConditionalExpression,
}

enum TodoExpression {
    TodoExpression(TodoTopic),
    TodoExpressionWithoutTopic(DontCarePattern),
}

// TODO: CustomType pattern in LetBinding?
enum LetBinding {
    BindingNameLetBinding(BindingName),
    RecordPatternLetBinding(RecordPattern),
    SequencePatternLetBinding(SequencePattern),
}

struct RecordPattern {
    keys: Vec<SimpleRecordKey>,
}

struct SequencePattern {
    items: Vec<SequencePatternItem>,
    rest_args: Option<SequenceRestArgsPattern>,
}

enum SequencePatternItem {
    DontCareSequencePattern(DontCarePattern),
    BindingNameSequencePattern(BindingName),
    LiteralExpressionSequencePattern(LiteralExpression),
    RecordPatternSequencePattern(RecordPattern),
    CustomTypeSequencePattern(CustomTypePattern),
}

struct SequenceRestArgsPattern {
    name: BindingName,
}

enum CustomTypePattern {
    TrivialCustomTypePattern {
        constructor: CustomTypeConstructorName,
    },
    ComplexCustomTypePattern {
        constructor: CustomTypeConstructorName,
        args: Vec<CustomTypePatternArg>,
    },
}

enum CustomTypePatternArg {
    DontCareCustomTypePattern(DontCarePattern),
    SequencePatternCustomTypePattern(SequencePattern),
    RecordPatternCustomTypePattern(RecordPattern),
    BindingNameCustomTypePattern(BindingName),
    CustomTypePatternCustomTypePattern(CustomTypePattern),
}

struct DontCarePattern {}

enum LiteralExpression {
    StringLiteral { content: StringContent },
    IntLiteral { content: IntType },
    DecimalLiteral { content: DecimalType },
    // TODO: MultilineStringLiteral will be awkward in some places when it stays a LiteralExpression
    MultilineStringLiteral { content: StringContent },
}

enum FunctionParameter {
    DontCareFunctionParameter(DontCarePattern),
    BindingNameFunctionParameter(BindingName),
    RecordPatternFunctionParameter(RecordPattern),
    SequencePatternFunctionParameter(SequencePattern),
    CustomTypePatternFunctionParameter(CustomTypePattern),
}

enum BlockBody {
    BlockWithSingleReturn {
        return_value: CallOrAtom,
    },
    BlockWithBindings {
        bindings: Vec<BlockBinding>,
        return_value: CallOrAtom,
    },
}

enum BlockBinding {
    LetExpressionBlockBinding(LetExpression),
    ExpectAssertionBlockBinding(ExpectAssertion),
}

enum CallOrAtom {
    CallExpressionCallOrAtom(CallExpression),
    AtomCallOrAtom(Atom),
}

struct CallExpression {
    target: CallTarget,
    params: Vec<CallParameter>,
}

struct ConstructorConceptApplicationExpression {
    target: CustomTypeName,
    params: Vec<CallParameter>,
}

enum CallTarget {
    ValueExpressionCallTarget(ValueExpression),
    CustomTypeTrivialValueExpressionCallTarget(
        CustomTypeTrivialValueExpression,
    ),
}

enum CallParameter {
    CallOrAtomCallParameter(CallOrAtom),
}

enum Atom {
    AnonymousFunctionExpressionAtom(AnonymousFunctionExpression),
    WhenExpressionAtom(WhenExpression),
    BinaryOperatorExpressionAtom(BinaryOperatorExpression),
    ValueExpressionAtom(ValueExpression),
    RecordExpressionAtom(RecordExpression),
    SequenceExpressionAtom(SequenceExpression),
    LiteralExpressionAtom(LiteralExpression),
    CustomTypeTrivialValueExpressionAtom(CustomTypeTrivialValueExpression),
    TodoExpressionAtom(TodoExpression),
}

struct CustomTypeTrivialValueExpression {
    constructor: CustomTypeConstructorName,
}

enum ValueExpression {
    BindingNameValueExpression(BindingName),
    QualifiedAccessValueExpression(QualifiedAccessExpression),
}

enum AnonymousFunctionExpression {
    AnonymousFunction {
        signature: Vec<FunctionParameter>,
        body: Box<BlockBody>,
    },
    AnonymousFunctionWithoutSignature {
        body: Box<BlockBody>,
    },
}

enum RecordExpression {
    RecordExpression {
        entries: HashMap<SimpleRecordKey, CallOrAtom>,
    },
    RecordExpressionWithSplat {
        splat: RecordSplatPattern,
        entries: HashMap<SimpleRecordKey, CallOrAtom>,
    },
}

struct RecordSplatPattern {
    name: BindingName,
}

struct SequenceSplatPattern {
    name: BindingName,
}

struct SequenceExpression {
    items: Vec<SequenceExpressionEntry>,
}

enum SequenceExpressionEntry {
    SplatSequenceExpressionEntry(SequenceSplatPattern),
    AtomSequenceExpressionEntry(Atom),
}

struct ConditionalExpression {
    left: CallOrAtom,
    op: MathsOperator,
    right: CallOrAtom,
}

struct MathsOperator {
    name: MathsOperatorName,
}

// TODO: Model that there has to be at least one branch?
enum WhenExpression {
    WhenExpression {
        subject: Box<CallOrAtom>,
        branches: Vec<WhenBranch>,
    },
    WhenExpressionWithCatchAll {
        subject: Box<CallOrAtom>,
        branches: Vec<WhenBranch>,
        catch_all: WhenBranchCatchAll,
    },
}

enum WhenBranch {
    WhenBranch {
        pattern: WhenBranchPattern,
        consequence: WhenBranchConsequence,
    },
    WhenBranchWithGuard {
        pattern: WhenBranchPattern,
        guard: WhenBranchGuard,
        consequence: WhenBranchConsequence,
    },
}

enum WhenBranchPattern {
    RecordPatternWhenBranchPattern(RecordPattern),
    SequencePatternWhenBranchPattern(SequencePattern),
    LiteralExpressionWhenBranchPattern(LiteralExpression),
    CustomTypePatternWhenBranchPattern(CustomTypePattern),
}

enum WhenBranchGuard {
    ConditionalExpressionWhenBranchGuard(ConditionalExpression),
}

struct WhenBranchCatchAll {
    consequence: WhenBranchConsequence,
}

struct WhenBranchConsequence {
    consequence: Box<CallOrAtom>,
}

struct QualifiedAccessExpression {
    target: QualifiedAccessTarget,
    segment: QualifiedAccessSegment,
}

enum QualifiedAccessTarget {
    RecordQualifiedAccessTarget(BindingName),
    QualifedImportQualifiedAccessTarget(QualifiedImportNamespace),
}

// TODO: Allow "train wreck" a.b.c.d.e accessors?
enum QualifiedAccessSegment {
    BindingNameQualifiedAccessSegment(BindingName),
}

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
