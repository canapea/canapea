;(function __canapea__(__$setup, undefined) {
  "use strict";

  //
  // .module_signature anonymous0
  //

  // Module anonymous0
  function __$$canapea_module$$__$anonymous0$__(__exports__) {
    if (__$$canapea_module$$__$anonymous0$__.$) return __$$canapea_module$$__$anonymous0$__.$;
    __exports__ = __exports__ || {};

    // .import_expose_capability: +StdOut from $canapea$io$
    const $StdOut = __$$canapea_module$$__$$canapea$io$$___capability_$StdOut;

    // .named_module_import: $canapea$io$stdout$ as stdout
    const stdout = __$$canapea_module$$__$$canapea$io$stdout$$__();

    // .named_module_import: $app$lib$ as lib
    const lib = __$$canapea_module$$__$$app$lib$$__();

    // .import_expose_type: T from $app$lib$
    const T = __$$canapea_module$$__$$app$lib$$___type_T;

    // Decl found: Cap=types.GrammarRule.custom_type_declaration
    const Cap = null;

    // Decl found: main=types.GrammarRule.function_declaration
    const main = null;

    // Sneakily export application main entry point for later usage
    Object.defineProperty(__exports__, '__main__', { get() { return main; }, configurable: false, writable: false, enumerable: false });

    return (__$$canapea_module$$__$anonymous0$__.$ = __exports__);
  }

  // Build the module graph and return application entrypoint
  __$setup.produceMain = function () {
    return __$$canapea_module$$__$anonymous0$__().__main__;
  };

  // Module Body Close

  //
  // .module_signature $app$lib$
  //

  // .module_export_opaque_type: R
  function __$$canapea_module$$__$$app$lib$$___type_R() { }

  // .module_export_type_with_constructors: T
  function __$$canapea_module$$__$$app$lib$$___type_T() { }

  // Module $app$lib$
  function __$$canapea_module$$__$$app$lib$$__(__exports__) {
    if (__$$canapea_module$$__$$app$lib$$__.$) return __$$canapea_module$$__$$app$lib$$__.$;
    __exports__ = __exports__ || {};

    // .import_expose_capability: +StdIn from $canapea$io$
    const $StdIn = __$$canapea_module$$__$$canapea$io$$___capability_$StdIn;

    // .import_expose_capability: +StdOut from $canapea$io$
    const $StdOut = __$$canapea_module$$__$$canapea$io$$___capability_$StdOut;

    // .named_module_import: $canapea$lang$int$ as int
    const int = __$$canapea_module$$__$$canapea$lang$int$$__();

    // .import_expose_type: Int from $canapea$lang$int$
    const Int = __$$canapea_module$$__$$canapea$lang$int$$___type_Int;

    // Decl found: R=types.GrammarRule.record_declaration
    const R = null;

    // Decl found: T=types.GrammarRule.custom_type_declaration
    const T = null;

    // Decl found: constant=types.GrammarRule.let_declaration
    const constant = null;

    // Decl found: fn=types.GrammarRule.function_declaration
    const fn = null;

    // .module_export_value: constant
    Object.defineProperty(__exports__, 'constant', { get() { return constant; }, configurable: false, writable: false });

    // .module_export_value: fn
    Object.defineProperty(__exports__, 'fn', { get() { return fn; }, configurable: false, writable: false });

    return (__$$canapea_module$$__$$app$lib$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$lang$int$
  //

  // .module_export_opaque_type: Int
  function __$$canapea_module$$__$$canapea$lang$int$$___type_Int() { }

  // Module $canapea$lang$int$
  function __$$canapea_module$$__$$canapea$lang$int$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$lang$int$$__.$) return __$$canapea_module$$__$$canapea$lang$int$$__.$;
    __exports__ = __exports__ || {};

    // Decl found: add=types.GrammarRule.function_declaration
    const add = null;

    return (__$$canapea_module$$__$$canapea$lang$int$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$io$
  //

  // .module_export_capability: $StdIn
  function __$$canapea_module$$__$$canapea$io$$___capability_$StdIn() { }

  // .module_export_capability: $StdOut
  function __$$canapea_module$$__$$canapea$io$$___capability_$StdOut() { }

  // Module $canapea$io$
  function __$$canapea_module$$__$$canapea$io$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$io$$__.$) return __$$canapea_module$$__$$canapea$io$$__.$;
    __exports__ = __exports__ || {};

    return (__$$canapea_module$$__$$canapea$io$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$io$stdout$
  //

  // Module $canapea$io$stdout$
  function __$$canapea_module$$__$$canapea$io$stdout$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$io$stdout$$__.$) return __$$canapea_module$$__$$canapea$io$stdout$$__.$;
    __exports__ = __exports__ || {};

    // Decl found: write=types.GrammarRule.function_declaration
    const write = null;

    // .module_export_value: write
    Object.defineProperty(__exports__, 'write', { get() { return write; }, configurable: false, writable: false });

    return (__$$canapea_module$$__$$canapea$io$stdout$$__.$ = __exports__);
  }
  // Module Body Close


  __$setup();
}((function (globalThis, pure, impure) {

  function setup() {
    globalThis.CanapeaApp = function CanapeaApp(opaque) {
      const main = setup.produceMain();
      main.call(null, opaque);
    };
  }
  setup.produceMain = function () { throw "No entry point found"; };

  return setup;
}(typeof globalThis !== "undefined" ? globalThis : self, {$:"+RunPureCode"},{$:"+RunImpureCode"}))));
