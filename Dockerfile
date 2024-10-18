FROM photon:latest AS base
ARG VERSION
ARG PACKER_PLUGIN_DIR="${HOME}/.packer.d/plugins/"
LABEL maintainer="mpoore.io"
LABEL version="$VERSION"

# Update packages and install new ones
RUN <<EOF
tdnf -y -q install unzip git wget tar bindutils coreutils xorriso jq mkpasswd
tdnf -y -q autoremove
tdnf -q clean all
EOF

# Add version and plugin files
ADD PLUGINS .
ADD VERSION .

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_linux_amd64.zip ./
RUN unzip packer_${VERSION}_linux_amd64.zip -d /usr/local/bin

# Install Plugins
RUN <<EOF
while IFS= read -r line
do
  echo "Downloading ${line}..."
  LATEST_RELEASE=$(curl -s https://api.github.com/repos/${line}/releases/latest | grep 'browser_download_url' | grep "${TARGETOS}_${TARGETARCH}" | cut -d '"' -f 4)
  curl -L "${LATEST_RELEASE}" -o "/tmp/plugin.zip"
  echo "Installing ${line}..."
  unzip -o "/tmp/plugin.zip" -d "${PACKER_PLUGIN_DIR}"
done < PLUGINS
EOF

FROM base
COPY --from=packer /usr/local/bin/packer /usr/local/bin/packer
COPY --from=packer ${PACKER_PLUGIN_DIR} ${PACKER_PLUGIN_DIR}

# Complete