resource "hcloud_ssh_key" "ramona" {
  name       = "ramona"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwvvTZjbvSDU7oK4B5VfsEBann7ktIVj5ShTWoFaGwH"
}

resource "hcloud_ssh_key" "ci" {
  name       = "ci"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkRskZZaMsOngUvKYgL8K6t5FBhMurjTkqbfxNLj0wE"
}
