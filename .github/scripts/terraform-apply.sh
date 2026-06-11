#!/usr/bin/env bash
set -euo pipefail

pushd terraform

eval "$(ssh-agent)"
ssh-add ~/.ssh/id_ed25519
ssh-add -L
age -d -i ~/.ssh/id_ed25519 plan.tfplan.age >plan.tfplan
terraform apply -input=false plan.tfplan && rm plan.tfplan
