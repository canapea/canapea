//use std::env::var;

// Example custom build script.
fn main() {
    // Tell Cargo that if the given file changes, to rerun this build script.
    println!("cargo:rerun-if-changed=janet.c");
    println!("cargo:rerun-if-changed=janet.h");
    println!("cargo:rerun-if-changed=janetconf.h");
    println!("cargo:rerun-if-changed=src/mylib.c");
    // Use the `cc` crate to build a C file and statically link it.
    cc::Build::new()
        //.cpp(true)
        //.include("include")
        .file("mylib.c")
        .compile("mylib");
}

// https://stackoverflow.com/questions/24145823/how-do-i-convert-a-c-string-into-a-rust-string-and-back-via-ffi
// https://stackoverflow.com/questions/43826572/where-should-i-place-a-static-library-so-i-can-link-it-with-a-rust-program

// fn main() {
//     let manifest_dir = var("CARGO_MANIFEST_DIR").unwrap();
//     println!("cargo:rustc-link-search={}/scripting/target", manifest_dir);
//     //println!("cargo:rustc-link-lib=mylib");
// }
