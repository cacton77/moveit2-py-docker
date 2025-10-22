#!/bin/bash

set -e  # Exit on any error

echo "========================================="
echo "MoveIt2 Docker Installation Script"
echo "========================================="
echo ""

# Check nvidia-container-toolkit version
# NVIDIA_TOOLKIT_VERSION=$(dpkg -l | grep nvidia-container-toolkit | awk '{print $2 " " $3}')
# echo "NVIDIA Container Toolkit version: $NVIDIA_TOOLKIT_VERSION"
# # If the version is not 1.17.x, prompt for installation
# if [[ ! "$NVIDIA_TOOLKIT_VERSION" =~ ^1\.17\. ]]; then
#     # Remove the incorrect repository file
#     sudo rm /etc/apt/sources.list.d/nvidia-container-toolkit.list

#     # Use the generic stable repository (not distro-specific)
#     echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" | \
#         sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

#     # Verify it looks correct
#     cat /etc/apt/sources.list.d/nvidia-container-toolkit.list

#     # Update package lists
#     sudo apt-get update

#     # Check what version is available
#     apt-cache policy nvidia-container-toolkit

#     # Remove all nvidia-container packages
#     sudo apt-get remove --purge nvidia-container-toolkit nvidia-container-toolkit-base libnvidia-container-tools libnvidia-container1

#     # Install all packages from NVIDIA repository at once
#     sudo apt-get install -y \
#         nvidia-container-toolkit=1.17.8-1 \
#         nvidia-container-toolkit-base=1.17.8-1 \
#         libnvidia-container-tools=1.17.8-1 \
#         libnvidia-container1=1.17.8-1

#     # Verify version
#     nvidia-container-toolkit --version
# fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the moveit2-py-docker directory
echo "Changing to directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR" || exit 1

# Build the Docker image
echo ""
echo "Building Docker image with docker compose..."
docker compose build

if [ $? -eq 0 ]; then
    echo "✓ Docker image built successfully"
else
    echo "✗ Docker build failed"
    exit 1
fi

# Create applications directory if it doesn't exist
APPS_DIR="$HOME/.local/share/applications/inspection"
echo ""
echo "Ensuring applications directory exists: $APPS_DIR"
if [ -d "$APPS_DIR" ]; then
    rm -rf "$APPS_DIR"
fi
mkdir -p "$APPS_DIR"

# Copy .env file
ENV_FILE=".env"
if [ -f "$SCRIPT_DIR/$ENV_FILE" ]; then
    echo "Copying .env file to $APPS_DIR..."
    cp "$SCRIPT_DIR/$ENV_FILE" "$APPS_DIR/"
    echo "✓ .env file installed"
else
    echo "✗ .env file not found: $SCRIPT_DIR/$ENV_FILE"
    exit 1
fi

# Copy main script
MAIN_SCRIPT="moveit2_docker.sh"
if [ -f "$SCRIPT_DIR/$MAIN_SCRIPT" ]; then
    echo "Copying main script to $APPS_DIR..."
    cp "$SCRIPT_DIR/$MAIN_SCRIPT" "$APPS_DIR/"
    chmod +x "$APPS_DIR/$MAIN_SCRIPT"
    echo "✓ Main script installed"
else
    echo "✗ Main script not found: $SCRIPT_DIR/$MAIN_SCRIPT"
    exit 1
fi

# Copy assets
ASSETS_DIR="$APPS_DIR/assets"
echo ""
echo "Ensuring assets directory exists: $ASSETS_DIR"
mkdir -p "$ASSETS_DIR"

# Copy asset files
for asset in "$SCRIPT_DIR/assets/"*; do
    if [ -f "$asset" ]; then
        echo "Copying asset file to $ASSETS_DIR..."
        cp "$asset" "$ASSETS_DIR/"
    fi
done

# Copy desktop file
BRINGUP_DESKTOP_FILE="bringup.desktop"
if [ -f "$SCRIPT_DIR/$BRINGUP_DESKTOP_FILE" ]; then
    echo "Copying bringup desktop file to $APPS_DIR..."
    cp "$SCRIPT_DIR/$BRINGUP_DESKTOP_FILE" "$APPS_DIR/"
    chmod +x "$APPS_DIR/$BRINGUP_DESKTOP_FILE"
    echo "✓ Bringup desktop file installed"
    echo "Icon=$ASSETS_DIR/bringup_icon.png" >> "$APPS_DIR/$BRINGUP_DESKTOP_FILE"
    echo "Creating bringup desktop shortcut..."
    # Remove existing shortcut if it exists
    rm -f "$HOME/Desktop/$BRINGUP_DESKTOP_FILE"
    ln -s "$APPS_DIR/$BRINGUP_DESKTOP_FILE" "$HOME/Desktop/"
    echo "✓ Desktop shortcut created"
else
    echo "✗ Bringup desktop file not found: $SCRIPT_DIR/$BRINGUP_DESKTOP_FILE"
    exit 1
fi
# Copy devel desktop file
DEVEL_DESKTOP_FILE="devel.desktop"
if [ -f "$SCRIPT_DIR/$DEVEL_DESKTOP_FILE" ]; then
    echo "Copying devel desktop file to $APPS_DIR..."
    cp "$SCRIPT_DIR/$DEVEL_DESKTOP_FILE" "$APPS_DIR/"
    chmod +x "$APPS_DIR/$DEVEL_DESKTOP_FILE"
    echo "✓ Devel desktop file installed"
    echo "Icon=$ASSETS_DIR/devel_icon.png" >> "$APPS_DIR/$DEVEL_DESKTOP_FILE"
    echo "Creating devel desktop shortcut..."
    # Remove existing shortcut if it exists
    rm -f "$HOME/Desktop/$DEVEL_DESKTOP_FILE"
    ln -s "$APPS_DIR/$DEVEL_DESKTOP_FILE" "$HOME/Desktop/"
    echo "✓ Desktop shortcut created"
else
    echo "✗ Devel desktop file not found: $SCRIPT_DIR/$DEVEL_DESKTOP_FILE"
    exit 1
fi

# Make the main script executable
MAIN_SCRIPT="moveit2_docker.sh"
if [ -f "$SCRIPT_DIR/$MAIN_SCRIPT" ]; then
    echo "Making main script executable..."
    chmod +x "$SCRIPT_DIR/$MAIN_SCRIPT"
    echo "✓ Main script is executable"
else
    echo "✗ Main script not found: $SCRIPT_DIR/$MAIN_SCRIPT"
    exit 1
fi

# Update desktop database (optional, helps with immediate icon visibility)
if command -v update-desktop-database &> /dev/null; then
    echo ""
    echo "Updating desktop database..."
    update-desktop-database "$APPS_DIR"
    echo "✓ Desktop database updated"
    echo ""
fi

# Import dependencies into shared_ws directory
SHARED_WS="$SCRIPT_DIR/shared_ws"
# If src folder doesn't exist
if [ ! -d "$SHARED_WS/src" ]; then
    echo "Creating src directory: $SHARED_WS/src"
    mkdir -p "$SHARED_WS/src"
    cd "$SHARED_WS/src"
    echo "Importing dependencies..."
    vcs import < ../shared.repos
    echo "✓ Dependencies imported"
else
    echo "✓ Src directory already exists: $SHARED_WS/src"
fi

# Import data repos into data directory
DATA_DIR="$SCRIPT_DIR/data"
if [ ! -d "$DATA_DIR/ViewpointGenerationData" ]; then
    cd "$DATA_DIR"
    echo "Importing data repositories..."
    vcs import < ./data.repos
    # git lfs
    cd "$DATA_DIR/ViewpointGenerationData"
    git lfs install
    git lfs pull
    git lfs fetch --all
    echo "✓ Data repositories imported"
else
    echo "✓ Data directory already exists: $DATA_DIR"
fi

echo ""
echo "========================================="
echo "Installation complete!"
echo "========================================="
echo ""
echo "You can now launch MoveIt2 Docker from your application menu"
echo "or by running: gtk-launch moveit2-docker"
echo ""
