# Docker Development Environment ("Toolbox")

This repository provides a standardized, containerized development environment (the "Toolbox") for managing both this root project and any child projects or modules contained within it.

The environment is built on **Docker** and **Docker Compose**, with **Docker-in-Docker (DinD)** enabled. This architecture allows the main container to act as a "mothership" or toolbox, capable of spinning up and managing its own nested docker containers for individual sub-projects.

**IMPORTANT: Configuration Synchronization**
All Docker configuration files are co-located in `.devcontainer`. When making changes to the development environment, ensure synchronization across:
- `.devcontainer/Dockerfile` ↔ `.devcontainer/devcontainer.json`
- `.devcontainer/docker-compose.yml` ↔ `.devcontainer/devcontainer.json`
- `.devcontainer/postCreateCommand.sh` (shared by both setups)

## Directory Structure

- **`Makefile`**: Convenience wrapper for Docker Compose commands (e.g., `make up`, `make shell`).
- **`README.md`**: This guide.
- **`.devcontainer/`**:
  - **`Dockerfile`**: Builds the development image with Docker CE, tools, and VNC support.
  - **`docker-compose.yml`**: Orchestrates the container with Docker-in-Docker enabled.
  - **`requirements.txt`**: Standard Python dependencies (formerly `dev-requirements.txt`).
  - **`package.json`**: Shared Node.js/NPM tools (e.g., `esbuild`).
  - **`postCreateCommand.sh`**: Setup script that installs dependencies and configures the environment on startup.
- **`projects/`**: Directory where individual child projects should be located (ignored by git in the root repo).

## Multi-Project Development

This environment is designed to support developing multiple distinct projects simultaneously.

### Project Structure

- Individual projects should be placed as strict children of the `projects` directory.
- Each project should be its own independent Git repository.
- All projects share the running `devenv` container for development tools.

### Workflow

1. **Start the Toolbox**: Run `docker compose up` (or `make up`) in this root directory.
2. **Enter the Container**: Run `make shell` to enter the `devenv` container.
3. **Navigate to Project**: Inside the shell, switch to your project context:
   ```bash
   cd projects/your_specific_project
   ```

### Building and Running Projects

While you rely on the `devenv` container for common development tools (git, python, editors, etc.), you should build and run your applications in their own specific contexts. This ensures isolation and avoids modifying the main toolbox environment.

Common approaches include:

- **JupyterLab**: Open a notebook for data science or interactive coding.
- **Docker**: Build and run a container from the project's `Dockerfile` using the `docker` command available inside the toolbox (via Docker-in-Docker).
- **Docker Compose**: Orchestrate the project's services using its own `docker-compose.yml`.
- **Kubernetes**: Deploy to a local cluster using `minikube` and `helm` (if enabled).

## Quick Start

The easiest way to interact with the environment is via the `make` commands defined in the root directory.

### 1. Start the Environment

```bash
make up
```

This will:
- Build the development image (if needed)
- Start the container with Docker-in-Docker enabled
- Mount your project directory to `/workspace`
- Run the setup scripts to install Python and Node.js dependencies

### 2. Enter the Toolbox

To get a shell inside the running container:

```bash
make shell
```

From here, you can run `python`, `npm`, `docker`, and other tools as if they were installed locally.

### 3. Check Status

Manage and view the container status:

```bash
# Check running containers
make ps

# View logs
make logs
```

### 4. Stop the Environment

```bash
make down
```

### 5. Use VS Code

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
- All Python packages from `.devcontainer/requirements.txt`
- Shared Node.js tools from `.devcontainer/package.json`

**Optional tools** (commented out in Dockerfile, uncomment if needed):
- Kubernetes tools (kubectl, minikube, helm)
- Terraform
- Google Chrome

## Manual Docker Compose (Alternative to Make)

If you prefer not to use `make`, you can run standard Docker Compose commands pointing to the configuration file.

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
make shell
pip install -r ./.devcontainer/requirements.txt
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
