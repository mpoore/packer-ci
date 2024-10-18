FROM photon:latest AS base
ARG VERSION
ARG TARGETOS
ARG TARGETARCH
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

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/$VERSION/packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip ./
RUN unzip packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin

# Complete
FROM base
COPY --from=packer /usr/local/bin/packer /usr/local/bin/packer