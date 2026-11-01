use nix::libc::IF_NAMESIZE;

pub fn make_interface_name(prefix: &str, full_name: &str) -> String {
    assert_ne!(full_name, "");

    let max_length = IF_NAMESIZE - prefix.len() - "\0".len();
    let name_offset = full_name.len().saturating_sub(max_length);

    format!("{prefix}{}", &full_name[name_offset..])
}
