#!/bin/sh

# Description: Download, verify and install eksctl binary on Linux and Mac
# Author: Chuck Nemeth
# https://eksctl.io/installation/

# Colored output
code_err() { tput setaf 1; printf '%s\n' "$*" >&2; tput sgr0; }
code_grn() { tput setaf 2; printf '%s\n' "$*"; tput sgr0; }
code_yel() { tput setaf 3; printf '%s\n' "$*"; tput sgr0; }

# Define funciton to delete temporary install files
clean_up() {
  printf '%s\n' "[INFO] Cleaning up install files"
  cd && rm -rf "${tmp_dir}"
}

# OS Check
archi=$(uname -sm)
case "$archi" in
  Darwin\ arm64)
    platform="darwin_arm64" ;;
  Darwin\ x86_64)
    platform="darwin_amd64" ;;
  Linux\ armv6)
    platform="linux_armv6" ;;
  Linux\ armv7)
    platform="linux_armv7" ;;
  Linux\ aarch64)
    platform="linux_arm64" ;;
  Linux\ *64)
    platform="linux_amd64" ;;
  *)
    code_err "[ERROR] Unsupported OS. Exiting"; exit 1 ;;
esac

# Variables
bin_dir="$HOME/.local/bin"

if command -v eksctl >/dev/null 2>&1; then
  eksctl_installed_version="$(eksctl version)"
else
  eksctl_installed_version="Not Installed"
fi

eksctl_version="$(curl -Ls https://api.github.com/repos/eksctl-io/eksctl/releases/latest | \
                         awk -F': ' '/tag_name/ { gsub(/\"|v|\,/,"",$2); print $2 }')"
eksctl_url="https://github.com/eksctl-io/eksctl/releases/latest/download"

eksctl_binary="eksctl"
eksctl_tar_file="eksctl_${platform}.tar.gz"
eksctl_sum_file="eksctl_checksums.txt"

# PATH Check
case :$PATH: in
  *:"${bin_dir}":*)  ;;  # do nothing
  *)
    code_err "[ERROR] ${bin_dir} was not found in \$PATH!"
    code_err "Add ${bin_dir} to PATH or select another directory to install to"
    exit 1 ;;
esac

if [ "${eksctl_version}" = "${eksctl_installed_version}" ]; then
  printf '%s\n' "Installed Verision: ${eksctl_installed_version}"
  printf '%s\n' "Latest Version: ${eksctl_version}"
  code_yel "[INFO] Already using latest version. Exiting."
  exit
else
  printf '%s\n' "Installed Verision: ${eksctl_installed_version}"
  printf '%s\n' "Latest Version: ${eksctl_version}"
  tmp_dir="$(mktemp -d /tmp/eksctl.XXXXXXXX)"
  trap clean_up EXIT
  cd "${tmp_dir}" || exit
fi

# Download
printf '%s\n' "[INFO] Downloading the eksctl binary and verification files"
curl -sL -o "${tmp_dir}/${eksctl_tar_file}" "${eksctl_url}/${eksctl_tar_file}"
curl -sL -o "${tmp_dir}/${eksctl_sum_file}" "${eksctl_url}/${eksctl_sum_file}"

# Verify shasum
printf '%s\n' "[INFO] Verifying ${eksctl_tar_file}"
if ! shasum -qc --ignore-missing "${eksctl_sum_file}"; then
  code_err "[ERROR] Problem with checksum!"
  exit 1
fi

# Extract archive
tar xf "${eksctl_tar_file}"

# Create directories
[ ! -d "${bin_dir}" ] && install -m 0700 -d "${bin_dir}"

# Install eksctl binary
if [ -f "${tmp_dir}/${eksctl_binary}" ]; then
  printf '%s\n' "[INFO] Installing the eksctl binary"
  mv "${tmp_dir}/${eksctl_binary}" "${bin_dir}/${eksctl_binary}"
  chmod 0700 "${bin_dir}/${eksctl_binary}"
  hash -r
fi

# VERSION CHECK
code_grn "[INFO] Done!"
code_grn "Installed Version: $(eksctl version)"

# vim: ft=sh ts=2 sts=2 sw=2 sr et
