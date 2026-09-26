#!/usr/bin/env bash
set -euo pipefail

# CI has no GPU: check the image's driver without loading modules or querying hardware.
kernel_version=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n')
driver_version=$(rpm -q nvidia-driver --queryformat '%{VERSION}')

for module in nvidia nvidia_modeset nvidia_drm nvidia_uvm; do
    module_version=$(modinfo -k "$kernel_version" -F version "$module")
    if [[ "$module_version" != "$driver_version" ]]; then
        echo "NVIDIA version mismatch: $module is $module_version, userspace is $driver_version" >&2
        exit 1
    fi
done

[[ $(modinfo -k "$kernel_version" -F license nvidia) == 'Dual MIT/GPL' ]]
command -v nvidia-smi
command -v nvidia-ctk
rpm -q nvidia-driver-cuda nvidia-container-toolkit libva-nvidia-driver

for argument in rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1; do
    grep -Fq "$argument" /usr/lib/bootc/kargs.d/*.toml
done

echo "Verified NVIDIA open driver $driver_version for kernel $kernel_version"
