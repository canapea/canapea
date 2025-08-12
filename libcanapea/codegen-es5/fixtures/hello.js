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

    // Decl found: main=types.GrammarRule.function_declaration
    function main(_,) {
(console.log("Hello, Canapea!",{}))
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


}));
