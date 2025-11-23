# Dockerfile for generalised development environment
# Replicates the .devcontainer configuration for standalone use
#
# IMPORTANT: This file mirrors .devcontainer/devcontainer.json
# Any changes to system dependencies or tools should be synchronized between:
# - This Dockerfile
# - .devcontainer/devcontainer.json
# - docker-compose.yml

FROM mcr.microsoft.com/devcontainers/python:3.12

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    jq \
    unzip \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install VNC and noVNC for desktop-lite feature
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    fluxbox \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    xdg-utils \
    xterm \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC
RUN mkdir -p /usr/local/novnc \
    && curl -sSL https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz | tar -xzC /usr/local/novnc --strip-components=1 \
    && mkdir -p /usr/local/novnc/utils/websockify \
    && curl -sSL https://github.com/novnc/websockify/archive/v0.12.0.tar.gz | tar -xzC /usr/local/novnc/utils/websockify --strip-components=1

# Optional tools for Docker-in-Docker or Kubernetes development
# Uncomment if needed:

# Install minikube
# RUN curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
#     && chmod +x /usr/local/bin/minikube

# Install helm
# RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install terraform
# RUN wget https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_amd64.zip -O /tmp/terraform.zip \
#     && unzip /tmp/terraform.zip -d /usr/local/bin/ \
#     && rm /tmp/terraform.zip

# Install kubectl
# RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
#     && chmod +x kubectl \
#     && mv kubectl /usr/local/bin/

# Install Google Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb || apt-get -y -f install \
    && rm /tmp/chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Google Antigravity
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list > /dev/null \
    && apt-get update \
    && apt-get install -y antigravity \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CE
RUN apt-get update && apt-get install -y \
    ca-certificates \
    gnupg \
    lsb-release \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN apt-get update \
    && apt-get install -y nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Install JupyterLab
RUN pip install --no-cache-dir jupyterlab

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV DISPLAY=:1
ENV PATH=$PATH:/home/vscode/.local/bin

# Ensure 'docker' group exists and add vscode to it (for Docker socket access)
# This satisfies docker-compose group_add: docker and avoids startup error when the group is missing.
RUN groupadd -f docker && usermod -aG docker vscode

# Create VNC startup script
RUN mkdir -p /home/vscode/.vnc
COPY --chown=vscode:vscode <<EOF /home/vscode/.vnc/xstartup
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xsetroot -cursor_name left_ptr
fluxbox
EOF
RUN chmod +x /home/vscode/.vnc/xstartup

# Create Fluxbox menu
RUN mkdir -p /home/vscode/.fluxbox
COPY --chown=vscode:vscode <<EOF /home/vscode/.fluxbox/menu
[begin] (Development)
  [exec] (Terminal) {xterm}
  [exec] (Google Chrome) {google-chrome}
  [exec] (Antigravity) {antigravity}
  [separator]
  [submenu] (Fluxbox)
    [config] (Configuration)
    [submenu] (Styles) {/usr/share/fluxbox/styles}
    [end]
    [reconfig] (Reconfigure)
    [restart] (Restart)
    [exit] (Exit)
  [end]
[end]
EOF

# Expose ports
# 8080: Application server
# 6080: noVNC web interface
# 5901: VNC server
EXPOSE 8080 6080 5901

# Set working directory
WORKDIR /workspace

# Switch to vscode user
USER vscode

# Note: postCreateCommand.sh will be run by docker-compose entrypoint
