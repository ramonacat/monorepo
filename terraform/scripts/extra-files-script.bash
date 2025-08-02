#!/usr/bin/env bash

pushd $SECRETS_PATH

RSA_KEY=$(agenix -d "$HOSTNAME-ssh-host-key-rsa.age")
ED25519_KEY=$(agenix -d "$HOSTNAME-ssh-host-key-ed25519.age")

popd

mkdir -p etc/ssh/

echo "$ED25519_KEY" > etc/ssh/ssh_host_ed25519_key
echo "$RSA_KEY" > etc/ssh/ssh_host_rsa_key

chmod 0600 etc/ssh/ssh_host*

ssh-keygen -f etc/ssh/ssh_host_ed25519_key -y > etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -f etc/ssh/ssh_host_rsa_key -y > etc/ssh/ssh_host_rsa_key.pub
