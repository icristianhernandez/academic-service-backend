#!/usr/bin/env bash
set -euo pipefail

tbls_version="1.92.3"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${root_dir}/.tools/tbls"
bin_dir="${install_dir}/bin"
binary_path="${bin_dir}/tbls"

os_name="$(uname -s)"
arch_name="$(uname -m)"

case "${os_name}" in
Linux) os="linux" ;;
Darwin) os="darwin" ;;
*)
	echo "Unsupported OS: ${os_name}" >&2
	exit 1
	;;
esac

case "${arch_name}" in
x86_64 | amd64) arch="amd64" ;;
arm64 | aarch64) arch="arm64" ;;
*)
	echo "Unsupported architecture: ${arch_name}" >&2
	exit 1
	;;
esac

mkdir -p "${bin_dir}"

archive_name="tbls_v${tbls_version}_${os}_${arch}.tar.gz"
download_url="https://github.com/k1LoW/tbls/releases/download/v${tbls_version}/${archive_name}"
tmp_dir="$(mktemp -d)"

cleanup() {
	rm -rf "${tmp_dir}"
}
trap cleanup EXIT

curl -fsSL "${download_url}" -o "${tmp_dir}/${archive_name}"
tar -xzf "${tmp_dir}/${archive_name}" -C "${tmp_dir}"

if [ ! -f "${tmp_dir}/tbls" ]; then
	echo "tbls binary not found in archive" >&2
	exit 1
fi

install -m 0755 "${tmp_dir}/tbls" "${binary_path}"

"${binary_path}" version
