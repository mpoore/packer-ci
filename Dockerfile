FROM photon:latest AS base

ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ARG ARTIFACTORY_URL
ARG BUILDDATE

LABEL org.opencontainers.image.base.name="docker.io/library/photon:latest"
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
tdnf -y -q install unzip git wget tar bindutils coreutils xorriso jq mkpasswd
tdnf -y -q autoremove
tdnf -q clean all
EOF

# Add version file and plugins file
ADD VERSION .
ADD PLUGINS .

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/$VERSION/packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip ./
RUN unzip -o packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin

# Install Packer plugins from Artifactory
RUN jq -c '.plugins[]' PLUGINS | while read i; do \
    name=$(echo $i | jq -r '.name'); \
    version=$(echo $i | jq -r '.version'); \
    wget -q ${ARTIFACTORY_URL}/${name}/${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip --no-check-certificate; \
    unzip -o ${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin; \
done

# Copy binary files for Packer and plugins
FROM base
COPY --from=packer /usr/local/bin /usr/local/bin/

# Append labels for plugins
