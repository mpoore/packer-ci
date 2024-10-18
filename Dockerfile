FROM photon:latest AS base
ARG VERSION
LABEL maintainer="mpoore.io"
LABEL version="$VERSION"

# Update packages and install new ones
RUN <<EOF
tdnf install -y curl unzip git wget tar bindutils coreutils xorriso jq mkpasswd
tdnf autoremove -y
tdnf clean all
EOF

# Add version and plugin files
ADD PLUGINS .
ADD VERSION .

# Install Packer
FROM base AS packer
ADD https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_linux_amd64.zip ./
RUN unzip packer_${VERSION}_linux_amd64.zip -d /usr/local/bin

# Install Plugins
FROM base
COPY --from=packer /usr/local/bin/packer /usr/local/bin/packer
RUN <<EOF
while IFS= read -r line
do
    packer plugins install $line
done < PLUGINS
EOF

# Complete