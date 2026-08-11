#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [upstream-branch]"
}

if (( $# > 1 )); then
    usage >&2
    exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

readonly REPOSITORY_URL="https://github.com/Gethe/wow-ui-source.git"
script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
    echo "Could not resolve the script directory." >&2
    exit 1
}
project_root="$(cd "${script_dir}/.." && pwd -P)" || {
    echo "Could not resolve the project root." >&2
    exit 1
}
readonly PROJECT_ROOT="${project_root}"
readonly CHECKOUT_DIR="${PROJECT_ROOT}/.cache/wow-ui-source"
readonly BRANCH="${1:-live}"

if [[ ! "${BRANCH}" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    echo "Invalid branch name: ${BRANCH}" >&2
    exit 2
fi

mkdir -p "$(dirname "${CHECKOUT_DIR}")"

if [[ ! -d "${CHECKOUT_DIR}/.git" ]]; then
    if [[ -e "${CHECKOUT_DIR}" ]]; then
        echo "Refusing to replace non-Git path: ${CHECKOUT_DIR}" >&2
        exit 1
    fi

    git clone \
        --depth=1 \
        --filter=blob:none \
        --no-single-branch \
        "${REPOSITORY_URL}" \
        "${CHECKOUT_DIR}"
fi

if [[ "$(git -C "${CHECKOUT_DIR}" remote get-url origin)" != "${REPOSITORY_URL}" ]]; then
    echo "Unexpected origin in ${CHECKOUT_DIR}; refusing to update it." >&2
    exit 1
fi

if [[ -n "$(git -C "${CHECKOUT_DIR}" status --porcelain)" ]]; then
    echo "The WoW UI reference has local changes; refusing to overwrite them." >&2
    exit 1
fi

git -C "${CHECKOUT_DIR}" fetch \
    --depth=1 \
    --filter=blob:none \
    --prune \
    origin \
    '+refs/heads/*:refs/remotes/origin/*'

if ! git -C "${CHECKOUT_DIR}" show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    echo "Unknown upstream branch: ${BRANCH}" >&2
    echo "Available branches:" >&2
    git -C "${CHECKOUT_DIR}" branch -r >&2
    exit 2
fi

git -C "${CHECKOUT_DIR}" checkout --quiet --detach "origin/${BRANCH}"

printf 'WoW UI source ready: branch=%s commit=%s path=%s\n' \
    "${BRANCH}" \
    "$(git -C "${CHECKOUT_DIR}" rev-parse --short=12 HEAD)" \
    "${CHECKOUT_DIR}"
