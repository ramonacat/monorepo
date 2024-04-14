{config, ...}: {
  nix = {
    buildMachines = [
      {
        hostName = "caligari";
        systems = ["aarch64-linux"];
        sshUser = "root";
        maxJobs = 8;
        publicHostKey = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFDaTBtaWkyU0xpQ3Vxak11ZlBBTE4wZ25jSVFDQllTY1BpWjFBNlVHeENQcWh0dkJVTzRGT0g2ZXMwbmw2WWZrbTdsQTZwbWJ4aEtPUFRUdDBMK0JWQmJpYzVERVdaVFUyL2J2V2FDZDd3Mm9GWVhscEN3K3ZWY0dUeVAwYWh2SWYyV2pscG0yRUtyTXlyUFg2UjUvMVF4RUtBZ1luRSs3R1YwZEZ1bDlBZ1MzRmZYUmgrbFM3cDZPcFJiWlBleWhkQ2pTd3RXV3phbTZYUjNaY3B1QkRPM0FFZ3RqOEZTNkxiaW4xVEhYTmVTemdqcnNsd0xhZXA4bUUvOFljQlFGWnpHK3p2WUNCZm54USsvd1JNN2Q4NFFlV3ZmaFZzQTNuSkh3RnA0WTc5YUJLSXlxTFU1bWlOY1hyZDlIYjhRRmQxSTB1bzEyYkxxVWROdnNxQnpUNGJqWm9Gb21oUnozMitNcnVFaGIxZGd0Z21RVEJYS1VrRE5WSjJNeEZpSFF5Z01qQnhjc3B5cy90ODZoMTIrdTlzenNBU1FXSkQrME15ZDJPRkJIVEFhRjVhbnB0ajV4Wk9EUld2eXVCNkttdlc0aDJva2I2MUZsbEVYbWpmZlJxdmo4bHN4ZWI0NXdoVk5aYTdoNE05WmJrbm93dWNDZjVZdnlEdWR3eng0RC8wRTlGUi8wUFZIOWt4dDVpajhHNkZUcUhKOFhiMC9mM1FsbnQ2VGlURGtmbDUzUG5BbVZ3VVlGZ3hjNVZnYm1hUDN2NU5ZQlhOWk1OMXZPSHZnWm5jQmpxM0MxWHlRZWcrOW9SYWRNa3pyUmpBQWFkWnFPUlA0TzBUamQ4Mkp2QkdqbEVWYnNjRnVzN2tKM1lzUlVKZnA2SHNsaVhCSWUvMDM5S25VNnNxdnc9PSByb290QGNhbGlnYXJpCg==";
        sshKey = config.age.secrets.universal-root.path;
        supportedFeatures = ["big-parallel" "kvm"];
      }
    ];
    distributedBuilds = true;
  };
}
