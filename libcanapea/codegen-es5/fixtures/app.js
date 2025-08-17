;(function __canapea__shell__(globalThis, code) {
  "use strict";

  const pure = {$:"+RunPureCode"};
  const impure = {$:"+RunImpureCode"};

  function setup() {
  }
  setup.produceMain = function () { throw "No entry point found"; };

  code(setup);

  const main = setup.produceMain();
  main.call(null, {});

}(typeof globalThis !== "undefined" ? globalThis : self, function __canapea__(__$setup, undefined) {

  //
  // .module_signature anonymous0
  //

  // Module anonymous0
  function __$$canapea_module$$__$anonymous0$__(__exports__) {
    if (__$$canapea_module$$__$anonymous0$__.$) return __$$canapea_module$$__$anonymous0$__.$;
    __exports__ = __exports__ || {};

    // .import_expose_capability: +StdOut from $canapea$$io$
    const $StdOut = __$$canapea_module$$__$$canapea$$io$$___capability_$StdOut;

    // .named_module_import: $canapea$$io$stdout$ as stdout
    const stdout = __$$canapea_module$$__$$canapea$$io$stdout$$__();

    // .named_module_import: $app$lib$ as lib
    const lib = __$$canapea_module$$__$$app$lib$$__();

    // .import_expose_type: T from $app$lib$
    const T = __$$canapea_module$$__$$app$lib$$___type_T;

    // Decl found: Cap=types.GrammarRule.custom_type_declaration
    const Cap = null;

    // Decl found: main=types.GrammarRule.function_declaration
    function main(_0) {
      return (function ($ret) {
;
        return $ret;
      }(null));
    }

    // Sneakily export application main entry point for later usage
    Object.defineProperty(__exports__, '__main__', { get() { return main; }, configurable: false, enumerable: false });

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

    // .import_expose_capability: +StdIn from $canapea$$io$
    const $StdIn = __$$canapea_module$$__$$canapea$$io$$___capability_$StdIn;

    // .import_expose_capability: +StdOut from $canapea$$io$
    const $StdOut = __$$canapea_module$$__$$canapea$$io$$___capability_$StdOut;

    // .named_module_import: $canapea$$lang$int$ as int
    const int = __$$canapea_module$$__$$canapea$$lang$int$$__();

    // .import_expose_type: Int from $canapea$$lang$int$
    const Int = __$$canapea_module$$__$$canapea$$lang$int$$___type_Int;

    // Decl found: R=types.GrammarRule.record_declaration
    const R = null;

    // Decl found: T=types.GrammarRule.custom_type_declaration
    const T = null;

    // Decl found: fortyTwo=types.GrammarRule.let_declaration
    const fortyTwo = (function ($ret) {
$ret = 42;
      return $ret;
    }(null));

    // Decl found: pi=types.GrammarRule.let_declaration
    const pi = (function ($ret) {
$ret = 3.14159265;
      return $ret;
    }(null));

    // Decl found: hello=types.GrammarRule.let_declaration
    const hello = (function ($ret) {
$ret = "Hello!";
      return $ret;
    }(null));

    // Decl found: sum=types.GrammarRule.let_declaration
    const sum = (function ($ret) {
const one = $ret = (function ($ret) { $ret = 1 ; return $ret; }(null)); const two = $ret = (function ($ret) { $ret = 2 ; return $ret; }(null));
      return $ret;
    }(null));

    // Decl found: fn=types.GrammarRule.function_declaration
    function fn(x, y, z) {
      return (function ($ret) {
;
        return $ret;
      }(null));
    }

    // .module_export_value: pi
    Object.defineProperty(__exports__, 'pi', { get() { return pi; }, configurable: false });

    // .module_export_value: fn
    Object.defineProperty(__exports__, 'fn', { get() { return fn; }, configurable: false });

    return (__$$canapea_module$$__$$app$lib$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$$lang$int$
  //

  // .module_export_opaque_type: Int
  function __$$canapea_module$$__$$canapea$$lang$int$$___type_Int() { }

  // Module $canapea$$lang$int$
  function __$$canapea_module$$__$$canapea$$lang$int$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$$lang$int$$__.$) return __$$canapea_module$$__$$canapea$$lang$int$$__.$;
    __exports__ = __exports__ || {};

    // Decl found: add=types.GrammarRule.function_declaration
    function add(x, y) {
      return (function ($ret) {
;
        return $ret;
      }(null));
    }

    return (__$$canapea_module$$__$$canapea$$lang$int$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$$io$
  //

  // .module_export_capability: $StdIn
  function __$$canapea_module$$__$$canapea$$io$$___capability_$StdIn() { }

  // .module_export_capability: $StdOut
  function __$$canapea_module$$__$$canapea$$io$$___capability_$StdOut() { }

  // Module $canapea$$io$
  function __$$canapea_module$$__$$canapea$$io$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$$io$$__.$) return __$$canapea_module$$__$$canapea$$io$$__.$;
    __exports__ = __exports__ || {};

    return (__$$canapea_module$$__$$canapea$$io$$__.$ = __exports__);
  }
  // Module Body Close

  //
  // .module_signature $canapea$$io$stdout$
  //

  // Module $canapea$$io$stdout$
  function __$$canapea_module$$__$$canapea$$io$stdout$$__(__exports__) {
    if (__$$canapea_module$$__$$canapea$$io$stdout$$__.$) return __$$canapea_module$$__$$canapea$$io$stdout$$__.$;
    __exports__ = __exports__ || {};

    // .import_expose_capability: +StdOut from $canapea$$io$
    const $StdOut = __$$canapea_module$$__$$canapea$$io$$___capability_$StdOut;

    // Decl found: write=types.GrammarRule.function_declaration
    function write(cap, buffer) {
      return (function ($ret) {
;
        return $ret;
      }(null));
    }

    // .module_export_value: write
    Object.defineProperty(__exports__, 'write', { get() { return write; }, configurable: false });

    return (__$$canapea_module$$__$$canapea$$io$stdout$$__.$ = __exports__);
  }
  // Module Body Close


}));
