#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only

# Check for mandatory env vars
if [[ -z "${VERSION}" ]]; then
    echo "VERSION is not set"
    exit 1
fi

# Prepare build environment
rm -rf dist/tmp && mkdir -p dist/tmp/packages
cp dist/mimir-linux-* dist/tmp/packages

# Run through binaries which need a package
for name in mimir; do
    # Run through supported architecture
    for arch in amd64 arm64; do
        config_path="dist/tmp/config-${name}-${arch}.json"

        # Render NFPM configuration file using jsonnet
        docker run --rm \
          -v "$(pwd)/packaging/nfpm/nfpm.jsonnet:/nfpm/nfpm.jsonnet" \
          -it 'bitnami/jsonnet' \
          -V "name=${name}" -V "arch=${arch}" "/nfpm/nfpm.jsonnet" > "${config_path}"

        # Run through supported packager
        for packager in deb rpm; do
          # Build package using NFPM
          docker run --rm \
		    -v  "$(pwd):/work:delegated,z" \
            -w /work \
            -e "VERSION=${VERSION}" \
		    -it goreleaser/nfpm:v2.22.2 \
            package \
            --config ${config_path} \
            --packager ${packager} \
            --target /work/dist/

          # Rename mimir packages as we want to keep the same standard as
          # the one builded by FPM
          if [ "${name}" == 'mimir' ] && [ "${packager}" == 'deb' ] && [ "${arch}" == 'amd64' ]; then
            mv -f "dist/mimir_${VERSION}_amd64.deb" "dist/mimir-${VERSION}_amd64.deb"
          fi
          if [ "${name}" == 'mimir' ] && [ "${packager}" == 'deb' ] && [ "${arch}" == 'arm64' ]; then
            mv -f "dist/mimir_${VERSION}_arm64.deb" "dist/mimir-${VERSION}_arm64.deb"
          fi
          if [ "${name}" == 'mimir' ] && [ "${packager}" == 'rpm' ] && [ "${arch}" == 'amd64' ]; then
            mv -f "dist/mimir-${VERSION}.x86_64.rpm" "dist/mimir-${VERSION}_amd64.rpm"
          fi
          if [ "${name}" == 'mimir' ] && [ "${packager}" == 'rpm' ] && [ "${arch}" == 'arm64' ]; then
            mv -f "dist/mimir-${VERSION}.aarch64.rpm" "dist/mimir-${VERSION}_arm64.rpm"
          fi
        done
    done
done

# Compute checksum of builded packages
for pkg in dist/*.deb dist/*.rpm; do
	sha256sum "${pkg}" | cut -d ' ' -f 1 > "${pkg}-sha-256";
done

# Cleanup build environment
rm -rf dist/tmp
