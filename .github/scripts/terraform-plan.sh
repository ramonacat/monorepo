#!/usr/bin/env bash

set -euo pipefail
pushd terraform

terraform plan -out=plan.tfplan
plan_output=$(terraform show -no-color "plan.tfplan")
age -R ~/.ssh/id_ed25519.pub plan.tfplan >plan.tfplan.age
rm plan.tfplan

{
	echo "READABLE_OUTPUT<<EOF"
	echo '```'
	echo -e "$plan_output"
	echo '```'
	echo 'EOF'
} >>"$GITHUB_OUTPUT"
