#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes before deploying." >&2
  exit 1
fi

remote_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
remote_branch="${remote_branch:-master}"

ssh_key="${HOME}/.ssh/id_ed25519_personal"
remote_host="noah#lincke.org@lincke.org"
remote_root="/home/noah/public_html"
ssh_cmd=(ssh -i "$ssh_key")
rsync_ssh="ssh -i $ssh_key"

git push origin "HEAD:${remote_branch}"

"${ssh_cmd[@]}" "$remote_host" "mkdir -p '$remote_root/assets' '$remote_root/images'"
rsync -az --delete -e "$rsync_ssh" "$repo_root/assets/" "$remote_host:$remote_root/assets/"
rsync -az --delete -e "$rsync_ssh" "$repo_root/images/" "$remote_host:$remote_root/images/"
rsync -az -e "$rsync_ssh" "$repo_root/index.html" "$remote_host:$remote_root/index.html"

echo "Deployed GitHub repo and synced $remote_root on $remote_host."
