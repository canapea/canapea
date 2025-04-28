#include "janetconf.h"
#include "janet.c"

const char* hello(){
    return "Hello World!";
}

void janet_hello(/*char* code*/) {
    // Initialize the virtual machine. Do this before any calls to Janet functions.
    janet_init();

    // Get the core janet environment. This contains all of the C functions in the core
    // as well as the code in src/boot/boot.janet.
    JanetTable *env = janet_core_env(NULL);

    // One of several ways to begin the Janet vm.
    janet_dostring(env, "(print `Hello, Janet!`)", "main", NULL);
    //janet_dostring(env, code, "main", NULL);

    // Use this to free all resources allocated by Janet.
    janet_deinit();
}
