#!/usr/bin/env bash

BRANCH_NAME=update_$(date +%Y%m%d%H%M%S)
git config user.name "roboramona"
git config user.email "<>"

git checkout -b "$BRANCH_NAME"
nix flake update --commit-lock-file
git push origin "$BRANCH_NAME"

REQUEST_BODY=$(jq --null-input --arg branch_name "$BRANCH_NAME" '{"base": "main", "head": $branch_name, "title": "Nix Flake Update"}')

response=$(curl --fail --silent -X POST \
	"https://code.ramona.fun/api/v1/repos/${CI_REPO_OWNER}/${CI_REPO_NAME}/pulls" \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-H "Authorization: token ${FORGEJO_TOKEN}" \
	-d "$REQUEST_BODY")
pr_id=$(echo "$response" | jq -r '.number')

REQUEST_BODY='{"Do": "merge", "merge_when_checks_succeed": true}'
curl --fail --silent -X POST \
	"https://code.ramona.fun/api/v1/repos/${CI_REPO_OWNER}/${CI_REPO_NAME}/pulls/$pr_id/merge" \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-H "Authorization: token ${FORGEJO_TOKEN}" \
	-d "$REQUEST_BODY"
