#!/bin/bash
# Basic entrypoint for ROS / Colcon Docker containers

# Source ROS 2
source /opt/ros/${ROS_DISTRO}/setup.bash

# Source the base workspace, if built
if [ -f /workspaces/moveit2_ws/install/setup.bash ]
then
    source /workspaces/moveit2_ws/install/setup.bash
fi

# Source the overlay workspace, if built
if [ -f /workspaces/shared_ws/install/setup.bash ]
then
    source /workspaces/shared_ws/install/setup.bash
    export INSPECTION_WS=/workspaces/shared_ws
fi

# Set Middleware to CycloneDDS
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

exec "$@"
