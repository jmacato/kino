# Kino

[![Build](https://github.com/jmacato/kino/actions/workflows/build.yml/badge.svg)](https://github.com/jmacato/kino/actions/workflows/build.yml)

Personal Fedora Silverblue image published as `ghcr.io/jmacato/kino:latest`.
It follows the latest stable [BlueBuild Silverblue NVIDIA open image](https://github.com/blue-build/base-images), currently Fedora 44.
The `latest` base tag also follows future stable Fedora releases.

The base supplies NVIDIA's open kernel modules for Turing and newer GPUs,
including the RTX 3060 Laptop, along with matching graphics and CUDA driver
libraries, `nvidia-smi`, NVIDIA Container Toolkit, and video acceleration.
Kino adds ASUS controls, Looking Glass, virtualization and development tools,
and Firefox and Loupe from Flathub. The retired WebKitGTK 4.0 development
package is replaced by WebKitGTK 4.1; applications using it may need porting.

## Build

GitHub Actions builds daily and on pushes to `main`, signs with the existing
`SIGNING_SECRET`, and publishes to GHCR. Pull requests and the migration branch
build without publishing. The build checks that NVIDIA's open kernel modules
match both the image kernel and userspace driver, and that CUDA/container
tools and NVIDIA boot arguments are present. Actual GPU operation is checked
after booting the image.

Local recipe validation:

```bash
bluebuild validate recipes/recipe.yml
```

## Upgrade an existing Kino installation

Wait for a successful build on `main` and update this checkout. Verify the
published image against the repository's current signing key:

```bash
cosign verify --key cosign.pub ghcr.io/jmacato/kino:latest
```

Older Kino deployments can still trust an earlier image-signing key. If
`/etc/pki/containers/kino.pub` differs from this repository's `cosign.pub`,
install the verified current public key before upgrading:

```bash
sudo install -m 0644 cosign.pub /etc/pki/containers/kino.pub
```

Then stage the new image:

```bash
sudo rpm-ostree upgrade
```

Review any dependency errors from locally layered packages before rebooting.
Older Fedora 41 installations use rpm-ostree and may not import the NVIDIA
boot arguments embedded in the new base. After successfully staging the image,
set them explicitly:

```bash
sudo rpm-ostree kargs \
  --append-if-missing=rd.driver.blacklist=nouveau \
  --append-if-missing=modprobe.blacklist=nouveau \
  --append-if-missing=nvidia-drm.modeset=1 \
  --append-if-missing=nvidia-drm.fbdev=1 \
  --delete-if-present=nomodeset
```

The new base uses BlueBuild's kernel/module signing key. If Secure Boot is
enabled, enroll that key using the [upstream migration instructions](https://github.com/blue-build/base-images#migration-from-ublue-base-images)
before booting it. No enrollment is needed while Secure Boot is disabled.

Reboot when ready, then verify:

```bash
nvidia-smi
lspci -nnk -d 10de:2520
```

The GPU should report `Kernel driver in use: nvidia`. If the new deployment
fails to boot, select the previous deployment in the boot menu.

## Verify the published image

```bash
cosign verify --key cosign.pub ghcr.io/jmacato/kino:latest
```
