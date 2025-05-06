extern crate codegen_es5;

use std::{fs, path::PathBuf};

use camino::Utf8Path;

use sem::{Forest, Seed};

#[derive(Debug)]
pub enum CodegenTarget {
    ECMAScript5,
}

pub fn generate(root_dir: PathBuf, target: CodegenTarget) -> Vec<u8> {
    let p =
        Utf8Path::from_path(&root_dir).expect("Only UTF8 paths are supported");

    let mut seeds: Vec<Seed> = Vec::default();

    for entry in p.read_dir_utf8().expect("read_dir call failed") {
        if let Ok(entry) = entry {
            if !entry.file_name().ends_with(".cnp") {
                continue;
            }
            let path = entry.path();
            println!("Canapea file found: {}", path);
            match fs::read(path) {
                Err(err) => println!("{}", err),
                Ok(code) => {
                    seeds.push(Seed::from(Some(path.to_path_buf()), code));
                }
            }
        }
    }

    let it = seeds.into_iter();
    let forest = Forest::from(it, None);
    match target {
        CodegenTarget::ECMAScript5 => codegen_es5::generate_code(forest),
    }
}
