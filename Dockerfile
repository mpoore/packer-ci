FROM photon:latest AS base
ARG VERSION
ARG TARGETOS
ARG TARGETARCH
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
ADD https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip ./
RUN unzip packer_${VERSION}_${TARGETOS}_${TARGETARCH}.zip -d /usr/local/bin

# Install Plugins
RUN <<EOF
# Check if TARGETOS and TARGETARCH are set (use default values if not)
OS="${TARGETOS:-$(uname | tr '[:upper:]' '[:lower:]')}"
ARCH="${TARGETARCH:-$(uname -m)}"

# Convert architecture for specific cases (for local environment, not Docker)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
fi

echo "Installing plugins for target OS: ${OS} and Architecture: ${ARCH}"
while IFS= read -r line
do
  LATEST_RELEASE=$(curl -s https://api.github.com/repos/${line}/releases/latest | grep 'browser_download_url' | grep "${OS}_${ARCH}" | cut -d '"' -f 4)
  echo "Downloading from ${LATEST_RELEASE}..."
  curl -L "${LATEST_RELEASE}" -o "/tmp/plugin.zip"
  echo "Installing ${line}..."
  unzip -o "/tmp/plugin.zip" -d "${PACKER_PLUGIN_DIR}"
done < PLUGINS
EOF

FROM base
COPY --from=packer /usr/local/bin/packer /usr/local/bin/packer
COPY --from=packer ${PACKER_PLUGIN_DIR} ${PACKER_PLUGIN_DIR}

# Complete