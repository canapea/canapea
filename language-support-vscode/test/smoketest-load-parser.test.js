import assert from "node:assert";
import path from "node:path";
import { test } from "node:test";

import Parser from "web-tree-sitter";

test("Testsetup is working", async () => {
  await Parser.init();

  const lang = await Parser.Language.load(
    path.join(import.meta.dirname, "..", "..", "parser", "tree-sitter-canapea.wasm"),
  );

  const parser = new Parser();
  parser.setLanguage(lang);

  assert.ok(parser.parse(
    `

module

let answer = 42

    `
  ));
});
