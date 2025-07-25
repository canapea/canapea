#!/usr/bin/env node
import process from "node:process";
import lang from "../tree-sitter.json" with { type: "json" };
import grammar from "../src/grammar.json" with { type: "json" };

const adapters = {
  node: {
    print(s) {
      process.stdout.write(s);
    },
  },
};

const io = adapters.node;

io.print(`(* ${lang.grammars[0].title} EBNF language grammar v${lang.metadata.version} *)\n`);
io.print(`(* License: ${lang.metadata.license} (https://spdx.org/licenses/${lang.metadata.license}.html) *)\n`);
io.print(`(* Homepage: www.canapea.org *)\n`);
io.print(`(* > Generated from Tree-Sitter "grammar.json" at ${new Date(Date.now()).toISOString()} *)\n`);
io.print(`(* > Note that this grammar does not model the language's significant *)\n`);
io.print(`(* > indentation and is for informational purposes only. *)\n`);
io.print("\n");
for (const [name, rule] of Object.entries(grammar.rules)) {
  io.print(`${name} ::=`);
  traverse(name, rule);
  io.print("\n\n");
}

/** Should be OK to use recursion, we're hardly gonna hit that 200+ stack frames */
function traverse(name, rule) {
  switch (rule.type) {
    case "ALIAS":
      io.print(" ( ");
      traverse(rule.type, rule.content);
      io.print(" ) ");
      break;
    case "BLANK":
      // Intentionally left blank
      break;
    case "CHOICE":
      {
        const { members } = rule;
        const isOptional = members.length == 2 && members[1].type == "BLANK";
        if (isOptional) {
          io.print(" (");
          traverse(rule.type, members[0]);
          io.print(" )? ");
        } else {
          io.print(" (");
          for (const [key, member] of Object.entries(members)) {
            if (Number(key) > 0) {
              io.print(" | ");
            }
            traverse(rule.type, member);
          }
          io.print(" ) ");
        }
      }
      break;
    case "FIELD":
      io.print(" ( ");
      traverse(rule.type, rule.content);
      io.print(" ) ");
      break;
    case "IMMEDIATE_TOKEN":
      io.print(" ( ");
      traverse(rule.type, rule.content);
      io.print(" ) ");
      break;
    case "PATTERN":
      io.print(` ${rule.value.replace("\\d", "[0-9]")}`);
      break;
    case "PREC": // Fallthrough
    case "PREC_DYNAMIC": // Fallthrough
    case "PREC_LEFT": // Fallthrough
    case "PREC_RIGHT":
      io.print("  ( ");
      traverse(rule.type, rule.content);
      io.print(" ) ");
      break;
    case "REPEAT":
      io.print(" ( ");
      traverse(rule.type, rule.content);
      io.print(" )* ");
      break;
    case "REPEAT1":
      io.print(" (");
      traverse(rule.type, rule.content);
      io.print(" )+ ");
      break;
    case "SEQ":
      io.print(" (");
      for (const member of Object.values(rule.members)) {
        traverse(rule.type, member);
      }
      io.print(" ) ");
      break;

    case "STRING":
      {
        const value = rule.value.replace("\\", "\\\\");
        if (value.indexOf("'") >= 0) {
          io.print(` "${value}" `);
        }
        else {
          io.print(` '${value}' `);
        }
      }
      break;

    case "SYMBOL":
      io.print(` ${rule.name}`);
      break;

    case "TOKEN":
      io.print(" ( ");
      traverse(rule.type, rule.content);
      io.print(" ) ");
      // io.print(" )* ");
      break;

    default:
      throw `Unknown rule : ${rule.type}`;
  }
}
