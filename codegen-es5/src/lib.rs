extern crate sem;

use sem::Forest;

pub fn generate_code(forest: Forest) -> Vec<u8> {
    let mut buf: Vec<u8> = Vec::default();

    // for sapling in nursery.iter() {
    //     let Tree { } = tree;
    // }

    forest.visit(|s_expr| {
        println!("{}", s_expr);
    });

    let s = "console.log('TODO')".to_owned();
    let mut v = s.into_bytes();
    let _ = &buf.append(&mut v);

    return buf;
}
