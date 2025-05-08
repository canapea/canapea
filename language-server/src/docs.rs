use std::fmt::Debug;
use std::fs;
use std::path::Path;

use sem::Sapling;

// TODO: Proper error handling
pub fn generate_ast_for_tests<P, T>(
    paths: T,
) -> impl Iterator<Item = (P, String)>
where
    P: AsRef<Path>,
    P: Debug,
    T: Iterator<Item = P>,
{
    // paths.into_iter()
    paths
        .map(move |p| {
            let res = fs::read(&p);
            (p, res)
        })
        .filter_map(|(p, res)| match res {
            Ok(txt) => Some((p, txt)),
            Err(err) => {
                print!("{err:#?}");
                None
            }
        })
        .map(move |(p, txt)| (p, Sapling::from(txt)))
        .map(|(p, sapling)| (p, format!("{sapling}")))
}
