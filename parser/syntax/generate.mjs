import process from "node:process";
import path from "node:path";
import fs from "node:fs/promises";
import {
  EXT,
  LANG,
  NAME,
  SCOPE,
  sym,
  op,
  keywords,
  operators,
  scopes,
  other_operators,
} from "./spec.mjs";

const adapters = {
  node: {
    args() {
      // const [_exe, _file, tmFile, scmDir] = process.argv;
      return {
        tmFile: path.join(
          import.meta.dirname,
          "../../.vscode/extensions/sol3/syntaxes/sol3.tmLanguage.json",
        ),
        scmDir: path.join(import.meta.dirname, "../queries/"),
      };
    },
    print(...args) {
      process.stdout.write(args.map(String).join(""));
    },
    async writeFile(filename, data) {
      await fs.writeFile(filename, data, { encoding: "utf8" });
    },
    exit: process.exit,
  },
};

const io = adapters.node;

// Generate tmLanguage.json and the lexical part of highlights.scm.

const args = io.args();
io.print("Generating syntax files...\n");
// io.print("  args:", args, "\n");

/** @param {string} s */
const tagged = (s) => `${s}.${LANG}`;

const escOp = (op) =>
  [...op]
    .map((x) => ["\\", x])
    .flat()
    .join("");

const tmLanguage = {
  $schema:
    "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
  comment: `Generated TextMate Grammar for ${LANG}`,
  name: NAME,
  scopeName: SCOPE,
  fileTypes: [EXT],
  patterns: [
    /// Custom for now...
    {
      comment: "capability reference",
      match: `\\b(${escOp(sym.cap_prefix)}[A-Z][a-zA-Z0-9]*)\\b`,
      name: tagged("support.other.capability"),
    },
    {
      comment: "custom type constructor",
      match: "\\b([A-Z][a-zA-Z0-9]*)\\b",
      name: tagged("entity.name.type.union"),
    },
    {
      comment: "module member access",
      match: `\\b([a-z][a-zA-Z0-9_]*)(${escOp(op.module_access)})\\b`,
      captures: {
        1: {
          name: tagged("meta.value.module"),
        },
        2: {
          name: tagged("entity.other.import-access"),
        },
      },
    },
    {
      comment: "field definition",
      match: `([a-z][a-zA-Z0-9_]*)(${escOp(op.field_def)})\\s+`,
      captures: {
        1: {
          name: tagged("variable.other.field-name"),
        },
        2: {
          name: tagged("keyword.operator.field-def"),
        },
      },
    },
    /// Mostly generated from configuration
    {
      comment: scopes.comments.line.comment,
      match: `${sym.line_comment}.*$`,
      name: tagged(scopes.comments.line.tmg),
    },
    {
      comment: scopes.comments.region.comment,
      patterns: [
        {
          match: `^${sym.line_comment}region.*$`,
          name: tagged(scopes.comments.region.tmg),
        },
        {
          match: `^${sym.line_comment}endregion.*$`,
          name: tagged(scopes.comments.region.tmg),
        },
      ],
    },
    {
      comment: scopes.keywords.declaration.comment,
      match: `\\b(${keywords.declaration.join("|")})\\b`,
      name: tagged(scopes.keywords.declaration.tmg),
    },
    {
      comment: scopes.keywords.import.comment,
      match: `\\b(${keywords.import.join("|")})\\b`,
      name: tagged(scopes.keywords.import.tmg),
    },
    keywords.storage.length
      ? {
          comment: scopes.keywords.storage.comment,
          match: `\\b(${keywords.storage.join("|")})\\b`,
          name: tagged(scopes.keywords.storage.tmg),
        }
      : null,
    {
      comment: scopes.keywords.meta.comment,
      match: `\\b(${keywords.meta.join("|")})\\b`,
      name: tagged(scopes.keywords.meta.tmg),
    },
    {
      comment: scopes.keywords.modifier.comment,
      match: `\\b(${keywords.modifier.join("|")})\\b`,
      name: tagged(scopes.keywords.modifier.tmg),
    },
    keywords.control.length
      ? {
          comment: scopes.keywords.control.comment,
          match: `\\b(${keywords.control.join("|")})\\b`,
          name: tagged(scopes.keywords.control.tmg),
        }
      : null,
    {
      comment: scopes.keywords.unused.comment,
      match: `\\b(${sym.dont_care})\\b`,
      name: tagged(scopes.keywords.unused.tmg),
    },
    {
      comment: scopes.operators.assignment.comment,
      match: `${escOp(op.eq)}`,
      name: tagged(scopes.operators.assignment.tmg),
    },
    {
      comment: scopes.operators.arrow.comment,
      match: `${escOp(op.arrow)}`,
      name: tagged(scopes.operators.arrow.tmg),
    },
    {
      comment: scopes.operators.pipe.comment,
      match: `${escOp(op.pipe)}`,
      name: tagged(scopes.operators.pipe.tmg),
    },
    {
      comment: scopes.operators.other.comment,
      match: `${other_operators.map(escOp).join("|")}`,
      name: tagged(scopes.operators.other.tmg),
    },
    {
      comment: scopes.punctuation.bracket.comment,
      match: `\\${sym.lcurly}|\\${sym.rcurly}`,
      name: tagged(scopes.punctuation.bracket.tmg),
    },
    {
      comment: scopes.punctuation.sequence.comment,
      match: `\\${sym.seq_open}|\\${sym.seq_close}`,
      name: tagged(scopes.punctuation.sequence.tmg),
    },
    /// Strings
    {
      comment: scopes.literals.string.comment,
      name: tagged(scopes.literals.string.tmg),
      begin: `${sym.string_open}`,
      beginCaptures: {
        0: {
          name: tagged("punctuation.definition.string.begin"),
        },
      },
      end: `${sym.string_close}`,
      endCaptures: {
        0: {
          name: tagged("punctuation.definition.string.end"),
        },
      },
      patterns: [
        {
          match:
            "\\\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|SYN|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL|[abfnrtv\\\\\\\"'\\&]|x[0-9a-fA-F]{1,5})",
          name: tagged("constant.character.escape"),
        },
        {
          match: "\\^[A-Z@\\[\\]\\\\\\^_]",
          name: tagged("constant.character.escape.control"),
        },
      ],
    },
    {
      comment: scopes.literals.multi_string.comment,
      name: tagged(scopes.literals.multi_string.tmg),
      begin: `${sym.multi_string_open}`,
      beginCaptures: {
        0: {
          name: tagged("punctuation.definition.string.begin"),
        },
      },
      end: `${sym.multi_string_close}`,
      endCaptures: {
        0: {
          name: tagged("punctuation.definition.string.end"),
        },
      },
      patterns: [
        {
          match:
            "\\\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|SYN|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL|[abfnrtv\\\\\\\"'\\&]|x[0-9a-fA-F]{1,5})",
          name: tagged("constant.character.escape"),
        },
        {
          match: "\\^[A-Z@\\[\\]\\\\\\^_]",
          name: tagged("constant.character.escape.control"),
        },
      ],
    },
  ].filter(Boolean),
  repository: {},
};

const highlights = [
  `; highlights.scm (generated)`,
  "",
  "; comments",
  ...Object.values(scopes.comments).flatMap((entry) => {
    return entry.tsg ? [`(${entry.tsg}) @${tagged(entry.hlt)}`] : [];
  }),
  "",
  ...Object.entries(keywords).flatMap(([category, list]) => {
    const cat = scopes.keywords[category];
    const hlt = cat.hlt;
    return hlt
      ? [
          `; keywords.${category}`,
          ...list.flatMap((kw) => {
            let x = `"${kw}"`;
            if (cat.no_hlt_yet && kw in cat.no_hlt_yet) {
              return [];
            }
            if (cat.to_tsg && kw in cat.to_tsg) {
              const tsg = cat.to_tsg[kw];
              if (Array.isArray(tsg)) {
                return tsg.map((it) => `(${it}) @${tagged(hlt)}`);
              }
              x = `(${tsg})`;
            }
            return [`${x} @${tagged(hlt)}`];
          }),
          "",
        ]
      : [];
  }),
  "; literals",
  ...Object.values(scopes.literals).flatMap((entry) => {
    return entry.tsg ? [`(${entry.tsg}) @${tagged(entry.hlt)}`] : [];
  }),
  "",
  "; assignment",
  `"${op.eq}" @${tagged(scopes.operators.assignment.hlt)}`,
  "",
  "; arrow",
  scopes.operators.arrow.hlt
    ? `"${op.arrow}" @${tagged(scopes.operators.arrow.hlt)}`
    : "",
  "",
  "; pipe",
  scopes.operators.pipe.hlt
    ? `"${op.pipe}" @${tagged(scopes.operators.pipe.hlt)}`
    : null,
  "",
  "; other operators",
  ...Object.values(other_operators).flatMap((op) => {
    const cat = scopes.operators.other;
    if (cat.no_hlt_yet && op in cat.no_hlt_yet) {
      return [];
    }
    return [`"${op}" @${tagged(scopes.operators.other.hlt)}`];
  }),
  "",
].join("\n");

const locals = [
  "; locals.scm",
  "",
  `(let_decl) @scope.local`,
  `(function_expr) @scope.local`,
  "",
].join("\n");

const tags = [
  "; tags.scm",
  "",
  "(script_decl) @definition.module",
  "(module_decl) @definition.module",
  "(application_decl) @definition.module",
  "(experimental_module_decl) @definition.module",
  "(kernel_module_decl) @definition.module",
  "",
  "(let_decl binding: (_) @name (function_expr)) @definition.function",
  "",
].join("\n");

try {
  await io.writeFile(args.tmFile, JSON.stringify(tmLanguage, null, 2));
  await io.writeFile(path.join(args.scmDir, "highlights.scm"), highlights);
  await io.writeFile(path.join(args.scmDir, "locals.scm"), locals);
  await io.writeFile(path.join(args.scmDir, "tags.scm"), tags);
  io.exit(0);
} catch (err) {
  io.print(String(err));
  io.exit(1);
}
