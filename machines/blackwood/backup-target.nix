_: {
  config = {
    services.nfs.server.exports = ''
      /var/backups/ 100.0.0.0/8(rw,sync,all_squash,anonuid=16969,no_subtree_check,insecure)
    '';
  };
}
