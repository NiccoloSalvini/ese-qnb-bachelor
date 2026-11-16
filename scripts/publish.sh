#!/usr/bin/env bash
# Publish the rendered site (_site/) into its academic-year folder on gh-pages.
#
#   bash scripts/publish.sh 2026-27
#
# Each A.Y. lives in its own folder on the gh-pages branch, so a new year never
# overwrites an old one: https://niccolosalvini.github.io/ese-qnb-bachelor/2026-27/
# Only the folder of the year being published is replaced. The root index.html
# redirects to the most recent year folder present on the branch.
set -euo pipefail

AY="${1:?usage: publish.sh <academic year, e.g. 2026-27>}"
[[ "$AY" =~ ^[0-9]{4}-[0-9]{2}$ ]] || { echo "AY must look like 2026-27, got '$AY'" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel)"
SITE="$ROOT/_site"
REMOTE="${REMOTE:-origin}"
[[ -f "$SITE/index.html" ]] || { echo "No $SITE/index.html: run 'make build' first" >&2; exit 1; }

WT="$(mktemp -d)"
cleanup() { git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; }
trap cleanup EXIT

if git -C "$ROOT" ls-remote --exit-code --heads "$REMOTE" gh-pages >/dev/null 2>&1; then
  git -C "$ROOT" fetch -q "$REMOTE" gh-pages
  git -C "$ROOT" worktree add -q -B gh-pages "$WT" "$REMOTE/gh-pages"
else
  # first publish: an empty orphan branch
  git -C "$ROOT" worktree add -q --detach "$WT"
  git -C "$WT" checkout -q --orphan gh-pages
  git -C "$WT" rm -rq --cached . >/dev/null 2>&1 || true
  find "$WT" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
fi

# replace this year's folder, leave the other years alone
rm -rf "${WT:?}/$AY"
mkdir -p "$WT/$AY"
cp -R "$SITE/." "$WT/$AY/"

# root redirect to the most recent year on the branch
LATEST="$(find "$WT" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]' -exec basename {} \; | sort | tail -n 1)"
cat > "$WT/index.html" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Quantitative Business Methods · ESE Florence</title>
<meta http-equiv="refresh" content="0; url=./$LATEST/">
<link rel="canonical" href="./$LATEST/">
</head>
<body><p><a href="./$LATEST/">Quantitative Business Methods, A.Y. $LATEST</a></p></body>
</html>
HTML
touch "$WT/.nojekyll"

git -C "$WT" add -A
if git -C "$WT" diff --cached --quiet; then
  echo "Nothing changed in $AY."
else
  git -C "$WT" commit -q -m "Publish A.Y. $AY ($(git -C "$ROOT" rev-parse --short HEAD))"
  git -C "$WT" push -q "$REMOTE" gh-pages
  echo "Published A.Y. $AY to gh-pages (folder $AY/; root redirects to $LATEST/)."
fi
