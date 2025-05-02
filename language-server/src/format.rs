use std::path::Path;

pub fn format_files<P, T>(paths: T)
where
    P: AsRef<Path>,
    T: Iterator<Item = P>,
{
    for path in paths.into_iter() {
        let buf = path.as_ref();
        println!("TODO: Format file {buf:#?}");
    }
}
