const vscode = require("vscode");
const path = require("node:path");
const fs = require("node:fs");

const Parser = require("web-tree-sitter");

module.exports = {
  activate,
  deactivate,
};

const initParser = Parser.init();

/**
 * @param {vscode.ExtensionContext} context
 */
async function activate(context) {
  /** @type {Map<string, Parser.Tree>} */
  const trees = new Map();

  /** @type {Parser?} */
  let parser = null;

  const wasmPath = path.join(
    context.extensionPath,
    "assets",
    "tree-sitter-canapea.wasm",
  );

  /**
   * Load the parser model for a given language
   * @returns a promise resolving to boolean an indicating whether the language could be loaded
   */
  async function loadLanguage() {
    if (parser !== null) {
      return true;
    }

    if (!fs.existsSync(wasmPath)) {
      throw Error(`Parser for language not found at ${wasmPath}`);
    }

    const wasm = path.relative(process.cwd(), wasmPath);
    await initParser;
    const language = await Parser.Language.load(wasm);
    const tmpParser = new Parser();
    tmpParser.setLanguage(language);
    parser = tmpParser;

    return true;
  }

  /**
   *
   * @param {vscode.TextDocument} document
   * @returns
   */
  async function open(document) {
    const uriString = document.uri.toString();
    if (trees.has(uriString)) {
      return;
    }

    if (!(await loadLanguage())) {
      return;
    }

    const t = parser.parse(document.getText()); // TODO don't use getText, use Parser.Input
    trees.set(uriString, t);
  }

  /**
   * @param {vscode.TextDocument} document
   */
  function openIfLanguageLoaded(document) {
    const uriString = document.uri.toString();
    if (trees.has(uriString)) {
      return null;
    }

    if (parser === null) {
      return null;
    }

    const t = parser.parse(document.getText()); // TODO don't use getText, use Parser.Input
    trees.set(uriString, t);
    return t;
  }

  /**
   * NOTE: if you make this an async function, it seems to cause edit anomalies
   * @param {vscode.TextDocumentChangeEvent} edit
   */
  function edit(edit) {
    if (parser === null || !edit) {
      return;
    }
    updateTree(parser, edit);
  }

  /**
   * @param {Parser} parser
   * @param {vscode.TextDocumentChangeEvent} edit
   */
  function updateTree(parser, edit) {
    if (edit.contentChanges.length === 0 ||
        edit.contentChanges.range.isEmpty()
    ) {
      return;
    }
    const old = trees.get(edit.document.uri.toString());
    if (!old) {
      return;
    }
    for (const e of edit.contentChanges) {
      const startIndex = e.rangeOffset;
      const oldEndIndex = e.rangeOffset + e.rangeLength;
      const newEndIndex = e.rangeOffset + e.text.length;
      const startPos = edit.document.positionAt(startIndex);
      const oldEndPos = edit.document.positionAt(oldEndIndex);
      const newEndPos = edit.document.positionAt(newEndIndex);
      const startPosition = asPoint(startPos);
      const oldEndPosition = asPoint(oldEndPos);
      const newEndPosition = asPoint(newEndPos);
      const delta = {
        startIndex,
        oldEndIndex,
        newEndIndex,
        startPosition,
        oldEndPosition,
        newEndPosition,
      };
      old.edit(delta);
    }
    const t = parser.parse(edit.document.getText(), old); // TODO don't use getText, use Parser.Input
    trees.set(edit.document.uri.toString(), t);
  }

  /**
   * @param {vscode.Position} pos
   * @returns {Parser.Point}
   */
  function asPoint(pos) {
    return { row: pos.line, column: pos.character };
  }

  /**
   * @param {vscode.TextDocument} document
   */
  function close(document) {
    trees.delete(document.uri.toString());
  }

  async function colorAllOpen() {
    for (const editor of vscode.window.visibleTextEditors) {
      await open(editor.document);
    }
  }

  /**
   * @param {vscode.TextDocument} document
   */
  function openIfVisible(document) {
    if (
      vscode.window.visibleTextEditors.some(
        (editor) => editor.document.uri.toString() === document.uri.toString()
      )
    ) {
      return open(document);
    }
  }

  context.subscriptions.push(
    vscode.window.onDidChangeVisibleTextEditors(colorAllOpen),
  );
  context.subscriptions.push(
    vscode.workspace.onDidChangeTextDocument(edit),
  );
  context.subscriptions.push(
    vscode.workspace.onDidCloseTextDocument(close),
  );
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument(openIfVisible),
  );

  // Don't wait for the initial color, it takes too long to inspect the themes and causes VSCode extension host to hang
  colorAllOpen();

  /**
   *
   * @param {vscode.Uri} uri
   * @returns
   */
  function getTreeForUri(uri) {
    if (!trees.has(uri.toString())) {
      const document = vscode.workspace.textDocuments.find(
        (textDocument) => textDocument.uri.toString() === uri.toString()
      );

      if (document == null) {
        throw new Error(`Document ${uri} is not open`);
      }

      const ret = openIfLanguageLoaded(document);

      if (ret != null) {
        return ret;
      }

      if (parser === null) {
        throw new LanguageStillLoadingError();
      }
    }

    return trees.get(uri.toString());
  }

  const extensionApi = {
    loadLanguage,

    /**
     * @param {vscode.TextDocument} document
     */
    getTree(document) {
      return getTreeForUri(document.uri);
    },

    getTreeForUri,

    /**
     * @param {vscode.Location} location
     */
    getNodeAtLocation(location) {
      return getTreeForUri(location.uri).rootNode.descendantForPosition({
        row: location.range.start.line,
        column: location.range.start.character,
      });
    },
  };
  return extensionApi;
}

// this method is called when your extension is deactivated
function deactivate() {}

class LanguageStillLoadingError extends Error {
  constructor() {
    super(`Language "canapea" is still loading; please wait and try again`);
    this.name = "LanguageStillLoadingError";
  }
}
