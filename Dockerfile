FROM photon:latest
ARG VERSION
LABEL maintainer="mpoore.io"
LABEL version="$VERSION"

# Update packages and install new ones
RUN tdnf install -y curl unzip git wget tar bindutils coreutils xorriso jq mkpasswd && \
    tdnf autoremove -y && \
    tdnf clean all

# Install Packer
ADD https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_linux_amd64.zip ./
RUN unzip packer_${VERSION}_linux_amd64.zip -d /bin && \
    rm -f packer_${VERSION}_linux_amd64.zip

# Complete
ADD VERSION .