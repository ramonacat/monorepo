#!/usr/bin/env bash

nix build --verbose --builders 'ssh://ramona@blackwood' .#nixosConfigurations.iso.config.system.build.isoImage
