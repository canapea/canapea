extern crate sem;

use sem::Nursery;

pub fn generate_code(_nursery: Nursery) -> Vec<u8> {
    let mut buf: Vec<u8> = Vec::default();

    // for tree in forest.iter() {
    //     let Tree { } = tree;
    // }

    let s = "console.log('TODO')".to_owned();
    let mut v = s.into_bytes();
    let _ = &buf.append(&mut v);

    return buf;
}
