FROM photon:latest AS base
ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ARG ARTIFACTORY_URL
LABEL maintainer="mpoore.io"
LABEL version="$VERSION"

# Update packages and install new ones
RUN <<EOF
tdnf -y -q install unzip git wget tar bindutils coreutils xorriso jq mkpasswd
tdnf -y -q autoremove
tdnf -q clean all
EOF

# Add version file
ADD VERSION .
ADD PLUGINS .

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/$VERSION/packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip ./
RUN unzip packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin

# Install Packer plugins from Artifactory
RUN jq -c '.plugins[]' PLUGINS | while read i; do \
    name=$(echo $i | jq -r '.name'); \
    version=$(echo $i | jq -r '.version'); \
    wget ${ARTIFACTORY_URL}/${name}/${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip --no-check-certificate; \
    unzip ${name}_${version}_x5.0_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin; \
done

# Complete
FROM base
COPY --from=packer /usr/local/bin /usr/local/bin/