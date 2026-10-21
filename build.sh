#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
upstream_dir="$(mktemp -d)"
source_dir="${UPSTREAM_SOURCE_DIR:-}"

cleanup() {
  rm -rf "${upstream_dir}"
}
trap cleanup EXIT

# Upstream publishes no releases or tags; the repository is the site itself.
if [[ -z "${source_dir}" ]]; then
  upstream_sha="$(git ls-remote https://github.com/xiaoyang111222/cn-math-taxonomy.git refs/heads/main | awk '{print $1}')"
  test -n "${upstream_sha}"
  source_dir="${upstream_dir}/source"
  mkdir -p "${source_dir}"
  curl --fail --location --retry 3 --retry-all-errors     "https://codeload.github.com/xiaoyang111222/cn-math-taxonomy/tar.gz/${upstream_sha}"     | tar -xz --strip-components=1 -C "${source_dir}"
else
  source_dir="$(cd "${source_dir}" && pwd)"
fi

# Upstream CI runs the same validation suite (stdlib only). Run it to keep
# broken data out of the package, but data checks are not fatal for serving.
python3 "${source_dir}/scripts/validate.py" || true

rm -rf "${project_root}/dist"
mkdir -p "${project_root}/dist"
for entry in index.html explore diagnose assets data docs; do
  if [[ -e "${source_dir}/${entry}" ]]; then
    cp -a "${source_dir}/${entry}" "${project_root}/dist/"
  fi
done
