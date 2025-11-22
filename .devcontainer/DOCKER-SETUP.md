# Docker Development Environment Setup

This directory contains Docker configuration files that replicate the `.devcontainer` environment for standalone use.

**IMPORTANT: Configuration Synchronization**
All Docker configuration files are co-located in `.devcontainer`. When making changes to the development environment, ensure synchronization across:
- `.devcontainer/Dockerfile` ↔ `.devcontainer/devcontainer.json`
- `.devcontainer/docker-compose.yml` ↔ `.devcontainer/devcontainer.json`
- `.devcontainer/postCreateCommand.sh` (shared by both setups)

## Files

- **Dockerfile**: Builds a development container with Docker CE, development tools, and VNC support
- **docker-compose.yml**: Orchestrates the container with Docker-in-Docker enabled

## Quick Start

### 1. Build and Start the Container

From the project root, use the `-f` flag to specify the compose file location.

If rebuilding, you may be better with an explicit build first:

```bash
docker compose -f ./.devcontainer/docker-compose.yml build --no-cache 
```

Then start it up:

```bash
docker compose -f .devcontainer/docker-compose.yml up -d
```

This will:
- Build the development image (first time only)
- Start the container with Docker-in-Docker enabled
- Start the Docker daemon inside the container
- Mount your project directory to `/workspace`
- Mount your SSH keys (read-only)
- Run `.devcontainer/postCreateCommand.sh` to complete the setup
- Install Python packages, Node.js dependencies, and CLI tools

### 2. Verify Container is Running

The container takes a while to run the above. Use Docker's observation tools.

Check the container status:

```bash
docker compose -f .devcontainer/docker-compose.yml ps
```

You should see the `dev` service running. The container runs Docker daemon as a service and stays running in the background.

```bash
docker container list
```

This should show container webcomponents-dev running.

You can view its logs to confirm the installation was
successful.

```bash
docker container logs webcomponents-dev
```

### 3. Access the Development Container

Connect to the running container on-demand:

```bash
# Get a bash shell in the container:
docker compose -f .devcontainer/docker-compose.yml exec dev bash

# Or run individual commands:
docker compose -f .devcontainer/docker-compose.yml exec dev docker ps
docker compose -f .devcontainer/docker-compose.yml exec dev npm --version
```

### 4. Use VS Code

You can continue using VS Code on your host machine to edit files. The project directory is mounted, so changes are immediately reflected in both the host and container.

Alternatively, use VS Code's "Attach to Running Container" feature:
1. Install the "Dev Containers" extension in VS Code
2. Click the remote indicator in the bottom-left corner
3. Select "Attach to Running Container"
4. Choose `webcomponents-dev`

## Configuration Options

### SSH Keys

**For Windows users**: The default configuration mounts SSH keys from `%USERPROFILE%\.ssh`

**For Linux/Mac users**: Edit `docker-compose.yml`:
```yaml
# Comment out the Windows line:
# - ${USERPROFILE}/.ssh:/home/vscode/.ssh-readonly:ro

# Uncomment the Linux/Mac line:
- ${HOME}/.ssh:/home/vscode/.ssh-readonly:ro
```

### Docker-in-Docker

The environment runs Docker daemon inside the container using Docker-in-Docker. This provides:
- Complete isolation from the host Docker
- Ability to run nested containers
- Persistent Docker data in a named volume (`docker-dind-data`)

**Service-Based Architecture**: The Docker daemon runs as the main container process (foreground), making the container a proper service rather than an interactive shell. The container remains running as long as the Docker daemon is healthy.

The startup sequence:
1. Runs `postCreateCommand.sh` to install dependencies and configure the environment
2. Starts Docker daemon as the main process

**Note**: This requires privileged mode, which is already configured in `docker-compose.yml`.

### VNC/noVNC (Optional)

The container includes VNC support for GUI applications. To enable:

1. Uncomment the VNC startup commands in `docker-compose.yml`
2. Access via:
   - VNC client: `localhost:5901` (password: `vscode`)
   - Web browser: `http://localhost:6080/vnc.html`

## Available Ports

- **8080**: Application server
- **6080**: noVNC web interface
- **5901**: VNC server

## Installed Tools

The container includes:
- Python 3.12 with pip
- Node.js and npm
- Docker CE with Docker Compose (via Docker-in-Docker)
- Git
- VNC/noVNC (for GUI applications)
- All Python packages from `.devcontainer/dev-requirements.txt`

**Optional tools** (commented out in Dockerfile, uncomment if needed):
- Kubernetes tools (kubectl, minikube, helm)
- Terraform
- Google Chrome

## Container Management

All commands below assume you're running from the project root. Add `-f .devcontainer/docker-compose.yml` to each command.

### Stop the container
```bash
docker compose -f .devcontainer/docker-compose.yml down
```

### Rebuild after Dockerfile changes
```bash
docker compose -f .devcontainer/docker-compose.yml up -d --build
```

### View logs
```bash
docker compose -f .devcontainer/docker-compose.yml logs -f dev
```

### Remove everything (including volumes)
```bash
docker compose -f .devcontainer/docker-compose.yml down -v
```

## Troubleshooting

### Docker Daemon Not Starting

The Docker daemon runs as the main container process. If the container is running but Docker commands fail, check the container logs:

```bash
# View container logs (includes Docker daemon output)
docker compose -f .devcontainer/docker-compose.yml logs -f dev

# Manually verify Docker is running inside the container
docker compose -f .devcontainer/docker-compose.yml exec dev docker info
```

If the daemon failed to start, the container will exit. Check why with:
```bash
docker compose -f .devcontainer/docker-compose.yml ps
docker compose -f .devcontainer/docker-compose.yml logs dev
```

If needed, rebuild the container:
```bash
docker compose -f .devcontainer/docker-compose.yml down -v
docker compose -f .devcontainer/docker-compose.yml up -d --build
```

### Permission Issues

The container runs as the `vscode` user with sudo privileges. If you need to run commands as root:

```bash
# Execute commands with sudo inside the container
docker compose -f .devcontainer/docker-compose.yml exec dev sudo <command>
```

### SSH Key Permissions

The `postCreateCommand.sh` script automatically copies SSH keys from `/home/vscode/.ssh-readonly` to `/home/vscode/.ssh` with correct permissions.

### Python Package Installation Issues

If Python packages fail to install, you can manually run:

```bash
docker compose exec dev bash
pip install -r ./.devcontainer/dev-requirements.txt
```

## Differences from .devcontainer

This setup is functionally equivalent to the `.devcontainer` configuration but:
- Uses `docker compose` instead of VS Code Dev Containers
- Runs Docker daemon inside the container (Docker-in-Docker) as the main process
- Container runs as a service (not in interactive mode)
- Connect to the container on-demand with `docker compose exec`
- Allows editing files with any editor on the host
- Independent from devcontainer.json (no configuration sharing needed)

## Example Workflow

```bash
# Start the environment (from project root)
docker compose -f .devcontainer/docker-compose.yml up -d

# Open a shell in the container
docker compose -f .devcontainer/docker-compose.yml exec dev bash

# Inside the container, run your development commands
npm run dev
# or
python your_script.py
# or
make build

# Edit files on your host with VS Code or any editor
# Changes are immediately available in the container

# When done, stop the container
docker compose -f .devcontainer/docker-compose.yml down
