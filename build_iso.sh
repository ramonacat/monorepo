#!/usr/bin/env bash

nix build --verbose --builders 'ssh://ramona@caligari' .#nixosConfigurations.iso.config.system.build.isoImage
