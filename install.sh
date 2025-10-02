#!/bin/bash

set -e  # Exit on any error

echo "========================================="
echo "MoveIt2 Docker Installation Script"
echo "========================================="
echo ""

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
APPS_DIR="$HOME/.local/share/applications"
echo ""
echo "Ensuring applications directory exists: $APPS_DIR"
mkdir -p "$APPS_DIR"

# Copy desktop file
DESKTOP_FILE="moveit2-docker.desktop"
if [ -f "$SCRIPT_DIR/$DESKTOP_FILE" ]; then
    echo "Copying desktop file to $APPS_DIR..."
    cp "$SCRIPT_DIR/$DESKTOP_FILE" "$APPS_DIR/"
    chmod +x "$APPS_DIR/$DESKTOP_FILE"
    echo "✓ Desktop file installed"
else
    echo "✗ Desktop file not found: $SCRIPT_DIR/$DESKTOP_FILE"
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
fi

echo ""
echo "========================================="
echo "Installation complete!"
echo "========================================="
echo ""
echo "You can now launch MoveIt2 Docker from your application menu"
echo "or by running: gtk-launch moveit2-docker"
echo ""
