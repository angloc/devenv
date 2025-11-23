#!/bin/bash
#
# IMPORTANT: This script is used by both .devcontainer and docker-compose setups
# Any changes should be compatible with both environments and synchronized with:
# - .devcontainer/devcontainer.json
# - Dockerfile
# - docker-compose.yml

# Avoid problems with ownership by container versus host user
git config --global --add safe.directory '*'

# Hopefully avois=d problems with line endings
git config --global core.autocrlf input

# Copy ssh credentials to mutable location
sudo mkdir -p ~/.ssh && \
    sudo cp -r ~/.ssh-readonly/* ~/.ssh/ && \
    sudo chmod 700 ~/.ssh && \
    sudo find ~/.ssh -type f ! -name "*.pub" \
                ! -name "config" \
                ! -name "known_hosts*" \
                -exec chmod 600 {} \; && \
    sudo find ~/.ssh -type f \( -name "*.pub" \
                        -o -name "config" \
                        -o -name "known_hosts*" \) \
                -exec chmod 644 {} \; && \
    sudo chown -R vscode  ~/.ssh

# Ensure the Docker daemon socket is available to the vscode user
if [ -e /var/run/docker.sock ]; then
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi
sudo usermod -aG docker vscode

# Make ruff etcetera available to the vscode user
pip install --upgrade pip
pip install --no-cache-dir -r ./.devcontainer/requirements.txt

# Install minikube if not present
#if ! command -v minikube &> /dev/null; then
#  echo "Installing minikube..."
#  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
#  chmod +x minikube && \
#  sudo mv minikube /usr/local/bin/
#else
#  echo "minikube is already installed"
#fi

# Install helm if not present
#if ! command -v helm &> /dev/null; then
#  echo "Installing helm..."
#  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
#else
#  echo "helm is already installed"
#fi

# Install terraform if not present
#if ! command -v terraform &> /dev/null; then
#  echo "Installing terraform..."
#  wget https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_amd64.zip -O terraform.zip && \
#  unzip terraform.zip && \
#  sudo mv terraform /usr/local/bin/ && \
#  rm terraform.zip
#else
#  echo "terraform is already installed"
#fi

# Install kubectl

# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/

# Install Google Chrome
# echo "Installing Google Chrome..."
# sudo apt-get update -y
# sudo apt-get install -y wget gnupg
# wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get -y -f install
# rm google-chrome-stable_current_amd64.deb

export PYTHONDONTWRITEBYTECODE=1

# Install Node.js and npm if not present
if ! command -v npm &> /dev/null; then
  echo "Installing Node.js and npm..."
  sudo apt-get update -y
  sudo apt-get install -y nodejs npm
else
  echo "npm is already installed"
fi

# Install NPM tools from .devcontainer/package.json
if [ -f ./.devcontainer/package.json ]; then
  echo "Installing NPM tools..."
  (cd .devcontainer && npm install)
  
  # Add node_modules/.bin to PATH if not already accepted
  if ! grep -q "export PATH=\$PATH:$(pwd)/.devcontainer/node_modules/.bin" ~/.bashrc; then
    echo "export PATH=\$PATH:$(pwd)/.devcontainer/node_modules/.bin" >> ~/.bashrc
  fi
else
  echo "No .devcontainer/package.json found, skipping NPM tools installation."
fi
