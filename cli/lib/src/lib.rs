extern crate libc;

use std::ffi::CStr;
use std::str;

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
        Ok(paths) => lsp::format_files(paths.into_iter().filter_map(|p| p.ok())),
        Err(_err) => {
            // TODO: panic! on glob pattern error?
            // panic!(err)
            ()
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
