#!/usr/bin/env bash

nix build --verbose --builders 'ssh://ramona@hallewell' .#nixosConfigurations.iso.config.system.build.isoImage
