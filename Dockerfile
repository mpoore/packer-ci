ARG LOCALREGISTRY

FROM alpine:latest AS base

ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ARG BUILDDATE

LABEL org.opencontainers.image.base.name="docker.io/library/alpine:latest"
LABEL org.opencontainers.image.created="$BUILDDATE"
LABEL org.opencontainers.image.authors="Michael Poore (https://mpoore.io)"
LABEL org.opencontainers.image.url="https://github.com/mpoore/packer-ci"
LABEL org.opencontainers.image.documentation="https://github.com/mpoore/packer-ci"
LABEL org.opencontainers.image.source="https://github.com/mpoore/packer-ci"
LABEL org.opencontainers.image.version="$VERSION"
LABEL org.opencontainers.image.vendor="mpoore.io"
LABEL org.opencontainers.image.licenses="Apache-2.0 AND BSL-1.1 AND MPL-2.0"
LABEL org.opencontainers.image.title="Packer Image Builder"
LABEL org.opencontainers.image.description="HashiCorp Packer packaged with some plugins, by mpoore.io."

# Update packages and install new ones
RUN <<EOF
apk update -q
apk add -q --no-cache unzip git wget tar bind-tools coreutils xorriso jq openssl ca-certificates
EOF

# Add version file and plugins file
ADD VERSION .
ADD PLUGINS .

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/$VERSION/packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip ./
RUN unzip -o packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin

# Install Packer plugins directly from their source repositories. Packer 1.7+
# no longer discovers plugin binaries from $PATH - they must be registered
# under the namespaced plugins directory with a matching SHA256SUM file, which
# `packer plugins install --path` generates for us from the downloaded binary.
# `set -e` ensures a failed download/install aborts the build instead of
# silently producing (and later pushing) an image missing a plugin.
RUN set -e; \
    mkdir -p /tmp/plugin-extract; \
    jq -c '.plugins[]' PLUGINS | while read i; do \
    name=$(echo $i | jq -r '.name'); \
    version=$(echo $i | jq -r '.version'); \
    source=$(echo $i | jq -r '.source'); \
    shortname=$(echo $name | sed 's/^packer-plugin-//'); \
    hostnamespace=$(echo $source | sed -e 's#https://##' -e "s#/${name}\$##"); \
    wget -q --timeout=60 --tries=5 ${source}/releases/download/${version}/${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip; \
    unzip -o ${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip -d /tmp/plugin-extract; \
    packer plugins install --path /tmp/plugin-extract/${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH} ${hostnamespace}/${shortname}; \
    done; \
    rm -rf /tmp/plugin-extract

# Copy binary files for Packer and plugins
FROM base
COPY --from=packer /usr/local/bin /usr/local/bin/
COPY --from=packer /root/.config/packer/plugins /root/.config/packer/plugins/

# Append labels for plugins