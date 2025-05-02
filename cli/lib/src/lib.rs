extern crate libc;

use std::ffi::CStr;
use std::fmt::Debug;
use std::path::Path;
use std::{fs, str};

use glob::glob;
use libc::c_char;

#[link(name = "mylib")]
unsafe extern "C" {
    unsafe fn hello() -> *const c_char;
    unsafe fn janet_hello();
}

pub fn say_hello() {
    unsafe { janet_hello() };
    let c_buf: *const c_char = unsafe { hello() };
    let c_str: &CStr = unsafe { CStr::from_ptr(c_buf) };
    let str_slice: &str = c_str.to_str().unwrap();
    println!("{}", str_slice);
    //let str_buf: String = str_slice.to_owned(); // if necessary
    //println!("{}", str_buf);
}

pub fn format_files(glob_pattern: &str) {
    match glob(glob_pattern) {
        Ok(paths) => lsp::format::format_files(paths.filter_map(|p| p.ok())),
        Err(_err) => {
            unimplemented!()
        }
    }
}

pub enum FileTreatment {
    Preserve,
    Overwrite,
}

pub enum DirectoryTreatment {
    MirrorDirectoryStructure,
    FlattenIntoTarget,
}

pub struct AstTestOptions {
    pub file_treatment: FileTreatment,
    pub directory_treatment: DirectoryTreatment,
    pub target: Option<String>,
}

fn write_ast_file<P, C>(path: P, contents: C)
where
    P: AsRef<Path>,
    P: Debug,
    C: AsRef<[u8]>,
{
    match fs::write(&path, contents) {
        Ok(_) => println!("File {path:#?} written."),
        Err(err) => println!("{err:#?}"),
    }
}

pub fn generate_ast_test_files(glob_pattern: &str, options: AstTestOptions) {
    let AstTestOptions {
        file_treatment,
        directory_treatment,
        target,
    } = options;

    let paths = glob(glob_pattern)
        .expect("Glob pattern should match files")
        .filter_map(|p| p.ok());

    for (p, ast) in lsp::docs::generate_ast_for_tests(paths) {
        let src = fs::read_to_string(&p).expect("File should have been here");
        let ast_file = match directory_treatment {
            DirectoryTreatment::FlattenIntoTarget => {
                let base_path = match &target {
                    Some(string) => {
                        std::env::current_dir()
                            .expect("CWD does not exist or insufficient permissions")
                            .join(string)
                            .canonicalize()
                            .expect("Specified target directory does not exist or insufficient permissions")
                    },
                    None => std::env::current_dir()
                        .expect("CWD either does not exist or insufficient permissions"),
                };

                let flat_name: String = p
                    .to_str()
                    .expect("Path should be convertible to a string")
                    .chars()
                    .map(|c| match c {
                        'A'..='Z' => c,
                        'a'..='z' => c,
                        '0'..='9' => c,
                        '-' => c,
                        _ => '_',
                    })
                    .collect();

                base_path.join(format!("{flat_name}.ast.txt"))
            }
            DirectoryTreatment::MirrorDirectoryStructure => {
                p.with_extension("ast.txt")
            }
        };
        let test_contents = format!(
            r#"
===
GEN[org.canapea] {p:#?}
===

{src:#}

---

{ast:#}

        "#
        );

        match (fs::exists(&ast_file), &file_treatment) {
            (Ok(true), FileTreatment::Preserve) => {
                println!(
                    "File {ast_file:#?} already exists, skipping due to config..."
                );
            }
            (Ok(true), FileTreatment::Overwrite) => {
                write_ast_file(&ast_file, test_contents)
            }
            (Ok(false), _) => write_ast_file(&ast_file, test_contents),
            (Err(err), _) => {
                println!("{err:#?}");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
