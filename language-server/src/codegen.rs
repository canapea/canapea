extern crate codegen_es5;

use std::{fs, path::Path};

use camino::Utf8Path;

use sem::{Seed, Nursery};

#[derive(Debug)]
pub enum CodegenTarget {
    ECMAScript5,
}

pub fn generate<P, T>(paths: T, target: CodegenTarget) -> Vec<u8>
where
    P: AsRef<Path>,
    P: std::fmt::Debug,
    T: Iterator<Item = P>,
{
    let seeds = paths
        .into_iter()
        .map(|std_path| {
            let path = Utf8Path::from_path(std_path.as_ref())
                .expect("Only UTF8 paths are supported");

            println!("Reading file: {}...", path);
            match fs::read(path) {
                Err(err) => {
                    println!("{}", err);
                    None
                }
                Ok(code) => Some(Seed::from(Some(path.to_path_buf()), code)),
            }
        })
        .filter_map(|it| it);

    let nursery = Nursery::from(seeds, None);
    match target {
        CodegenTarget::ECMAScript5 => codegen_es5::generate_code(nursery),
    }
}
