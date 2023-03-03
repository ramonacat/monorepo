#!/usr/bin/env bash

nix build -L .#nixosConfigurations.iso.config.system.build.isoImage