ARG NET_CORE_SDK_VERSION=10.0.400
ARG NODE_VERSION=24.19.0
ARG POWERSHELL_VERSION=7.6.4
ARG KUBECTL_VERSION=1.35.7
ARG HELM_VERSION=4.2.3
ARG COSIGN_VERSION=2.5.3
ARG AZURE_CLI_VERSION=2.88.0-1~noble
ARG SQLSERVER_MODULE_VERSION=22.4.5.1
ARG RIMRAF_VERSION=6.1.3
ARG MONOTAG_VERSION=1.26.0

FROM mcr.microsoft.com/dotnet/sdk:${NET_CORE_SDK_VERSION}

ARG NET_CORE_SDK_VERSION
ARG NODE_VERSION
ARG POWERSHELL_VERSION
ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG COSIGN_VERSION
ARG AZURE_CLI_VERSION
ARG SQLSERVER_MODULE_VERSION
ARG RIMRAF_VERSION
ARG MONOTAG_VERSION
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg jq unzip xz-utils && \
    install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor --batch --yes -o /etc/apt/keyrings/microsoft.gpg && \
    chmod 0644 /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
      > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends "azure-cli=${AZURE_CLI_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js from official tarball
RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    case "$arch" in \
      amd64|x86_64) node_arch="x64" ;; \
      arm64|aarch64) node_arch="arm64" ;; \
      *) echo "Unsupported TARGETARCH: $arch"; exit 1 ;; \
    esac; \
    node_archive="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${node_archive}" -o "${node_archive}"; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" -o SHASUMS256.txt; \
    grep " ${node_archive}$" SHASUMS256.txt | sha256sum --check; \
    mkdir -p /usr/local/lib/nodejs; \
    tar -xJf "${node_archive}" -C /usr/local/lib/nodejs; \
    rm "${node_archive}" SHASUMS256.txt; \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${node_arch}/bin/node /usr/local/bin/node; \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${node_arch}/bin/npm /usr/local/bin/npm; \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-${node_arch}/bin/npx /usr/local/bin/npx
# Install pinned global npm packages used by the build templates.
RUN npm install -g "rimraf@${RIMRAF_VERSION}" "monotag@${MONOTAG_VERSION}"

# Install PowerShell in a system-wide location for the pipeline worker.
RUN dotnet tool install --tool-path /usr/local/share/dotnet-tools powershell --version ${POWERSHELL_VERSION} && \
    ln -s /usr/local/share/dotnet-tools/pwsh /usr/local/bin/pwsh
RUN pwsh -NoLogo -NoProfile -Command \
    "Install-Module SqlServer -RequiredVersion ${SQLSERVER_MODULE_VERSION} -Scope AllUsers -Repository PSGallery -Force"

# Install kubectl for the selected build architecture and verify the published checksum.
RUN set -eux; arch="${TARGETARCH:-amd64}"; \
    curl -fsSLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${arch}/kubectl"; \
    curl -fsSLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${arch}/kubectl.sha256"; \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check; \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256

# Install Helm
RUN set -eux; arch="${TARGETARCH:-amd64}"; \
    curl -fsSLO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${arch}.tar.gz"; \
    curl -fsSLO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${arch}.tar.gz.sha256sum"; \
    sha256sum --check "helm-v${HELM_VERSION}-linux-${arch}.tar.gz.sha256sum"; \
    tar -zxf "helm-v${HELM_VERSION}-linux-${arch}.tar.gz"; \
    install -o root -g root -m 0755 "linux-${arch}/helm" /usr/local/bin/helm; \
    rm -rf "linux-${arch}" helm-v${HELM_VERSION}-linux-${arch}.tar.gz*

# Cosign is used by the release pipeline to sign and verify image digests.
RUN set -eux; arch="${TARGETARCH:-amd64}"; \
    curl -fsSL "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${arch}" \
      -o "/tmp/cosign-linux-${arch}"; \
    curl -fsSL "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_checksums.txt" \
      -o /tmp/cosign_checksums.txt; \
    cd /tmp; \
    grep " cosign-linux-${arch}$" cosign_checksums.txt | sha256sum --check; \
    install -o root -g root -m 0755 "cosign-linux-${arch}" /usr/local/bin/cosign; \
    rm "cosign-linux-${arch}" cosign_checksums.txt

# Intentionally keep the CI worker image on the root default. Azure Pipelines
# initializes container jobs by creating its UID and sudo group in /etc.
