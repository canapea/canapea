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
    // Custom
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
      comment: "import access",
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
      comment: "import access",
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
    // Generated
    {
      match: `${sym.line_comment}.*$`,
      name: tagged("comment.line.number-sign"),
    },
    {
      patterns: [
        {
          match: `^${sym.line_comment}region.*$`,
          name: tagged("comment.block"),
        },
        {
          match: `^${sym.line_comment}endregion.*$`,
          name: tagged("comment.block"),
        },
      ],
    },
    {
      match: `\\b(${sym.dont_care})\\b`,
      name: tagged("keyword.unused"),
    },
    {
      match: `\\b(${keywords.declaration.join("|")})\\b`,
      name: tagged("keyword.other"),
    },
    {
      match: `\\b(${keywords.storage.join("|")})\\b`,
      name: tagged("storage.type"),
    },
    {
      match: `\\b(${keywords.meta.join("|")})\\b`,
      name: tagged("keyword.other.meta"),
    },
    {
      match: `\\b(${keywords.modifier.join("|")})\\b`,
      name: tagged("keyword.other.modifier"),
    },
    {
      match: `\\b(${keywords.control.join("|")})\\b`,
      name: tagged("keyword.control"),
    },
    {
      match: `${escOp(op.eq)}`,
      name: tagged("keyword.operator.assignment"),
    },
    {
      match: `${escOp(op.arrow)}`,
      name: tagged("keyword.operator.arrow"),
    },
    {
      match: `${escOp(op.pipe)}`,
      name: tagged("keyword.operator.pipe"),
    },
    {
      match: `${operators
        .filter((x) => ![op.eq, op.arrow, op.pipe].includes(x))
        .map(escOp)
        .join("|")}`,
      name: tagged("keyword.operator.other"),
    },
    {
      match: `\\${sym.lcurly}|\\${sym.rcurly}`,
      name: tagged("punctuation.bracket"),
    },
    {
      match: `\\${sym.seq_open}|\\${sym.seq_close}]`,
      name: tagged("punctuation.definition.sequence"),
    },
    {
      comment: "string",
      name: tagged("string.quoted.double"),
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
      comment: "string-triple",
      name: tagged("string.quoted.triple"),
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
  ],
  repository: {},
};

try {
  await io.writeFile(args.tmFile, JSON.stringify(tmLanguage, null, 2));
  io.exit(0);
} catch (err) {
  io.print(String(err));
  io.exit(1);
}
