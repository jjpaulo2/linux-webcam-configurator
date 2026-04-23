#!/usr/bin/env bash
# 
# Webcam Linux Configurator
# https://github.com/jjpaulo2/linux-webcam-configurator
# 
# This script is responsible for reading the webcam configuration from the JSON
# file and applying it to the webcam using v4l2-ctl. It also checks if the webcam
# is connected and if it supports the configured settings, and sends desktop notifications
# in case of errors or when the webcam is ready to use.
# 
# MIT License
# 
# Copyright (c) 2026 João Paulo Carvalho
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Lock file temporary path
LOCK_FILE="/tmp/webcam-cfg.lock";

# Handling the lock to prevent multiple instances of the script running at the same time
if LOCK_PID=$(cat "$LOCK_FILE"); then
    echo "[$(date)] [INFO] Script is already running with PID $LOCK_PID.";
    exit 1;
else
    echo "$$" > "$LOCK_FILE";
fi;

# Path for the configuration JSON file
CONFIG_FILE="/etc/webcam-cfg.json";

# If configuration file does not exist, tell user
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[$(date)] [ERROR] Couldn't read configurations from \"$CONFIG_FILE\"!";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# Load webcam configuration
WEBCAM_NAME=$(jq -r '.name' "$CONFIG_FILE");
WEBCAM_CONFIG_WIDTH=$(jq -r '.config.width' "$CONFIG_FILE");
WEBCAM_CONFIG_HEIGHT=$(jq -r '.config.height' "$CONFIG_FILE");
WEBCAM_CONFIG_FPS=$(jq -r '.config.fps' "$CONFIG_FILE");
WEBCAM_CONFIG_FORMAT=$(jq -r '.config.format' "$CONFIG_FILE");
WEBCAM_CONFIG_BANDWIDTH=$(jq -r '.config.bandwidth' "$CONFIG_FILE");

# Reading active user to send desktop notifications
ACTIVE_USER=$(who | grep -E '\(:[0-9]+\)' | awk '{print $1}' | head -1);

# Setting webcam icon based on the desktop environment
case "$XDG_CURRENT_DESKTOP" in
  GNOME)
    WEBCAM_ICON="cheese";
    ;;
  KDE)
    WEBCAM_ICON="kamoso";
    ;;
  *)
    WEBCAM_ICON="webcam";
    ;;
esac;

# Function to send desktop notifications
webcam_notify() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "[$(date)] [ERROR] Usage: webcam_notify <title> <message>";
        exit 1;
    else
        systemd-run --user --machine="${ACTIVE_USER}@.host" \
            notify-send --app-name="$WEBCAM_NAME" --icon="$WEBCAM_ICON" "$1" "$2";
    fi;
}

# Reading webcam ID from lsusb output
DEVICE_ID=$(lsusb | grep -i "$WEBCAM_NAME" | grep -oP "\w{4}:\w{4}");

# If no device ID is found, tell user
if [ -z "$DEVICE_ID" ]; then
    echo "[$(date)] [ERROR] Webcam \"$WEBCAM_NAME\" not found!";
    webcam_notify "Webcam not found" "Please try to re-connect the webcam";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# Reading webcam bandwidth from lsusb output
HAS_BANDWIDTH=$(lsusb -v -t | grep -B 1 "$DEVICE_ID" | grep -i "Class=Video.*$WEBCAM_CONFIG_BANDWIDTH");

# If no bandwidth is found (bandwidth not supported), tell user
if [ -z "$HAS_BANDWIDTH" ]; then
    echo "[$(date)] [ERROR] Webcam \"$WEBCAM_NAME\" can't operate at \"$WEBCAM_CONFIG_BANDWIDTH\"!";
    webcam_notify "Webcam can't operate at $WEBCAM_CONFIG_BANDWIDTH" "Please try to re-connect the webcam in a USB 3.0 port";
    rm -f "$LOCK_FILE";    exit 1;
fi;

# Read all video devices associated with the webcam
DEVICES=$(v4l2-ctl --list-devices | grep -A 2 "$WEBCAM_NAME" | tail -n 2);

# Check if any video device has video capture capability
for dev in $DEVICES; do

    # Read device capabilities
    capability=$(v4l2-ctl --device="$dev" --info | grep -A 1 "Device Caps" | tail -n 1);

    # Check if device has video capture capability
    if [[ "$capability" == *"Video Capture"* ]]; then
        VIDEO_DEVICE="$dev";
        break;
    fi;
done;

# If no video device with video capture capability is found, tell user
if [ -z "$VIDEO_DEVICE" ]; then
    echo "[$(date)] [ERROR] Webcam \"$WEBCAM_NAME\" does not have video capture capability!";
    webcam_notify "Webcam does not have video capture capability" "Please try to re-connect the webcam";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

echo "[$(date)] [INFO] Configuring \"$WEBCAM_NAME\"...";

# Function to configure webcam settings
configure_webcam() {
    v4l2-ctl \
        --device="$VIDEO_DEVICE" \
        --set-fmt-video=width="$WEBCAM_CONFIG_WIDTH",height="$WEBCAM_CONFIG_HEIGHT",pixelformat="$WEBCAM_CONFIG_FORMAT" \
        --set-parm="$WEBCAM_CONFIG_FPS" 2>&1;
};

# If webcam configuration fails, tell user
if ! configure_webcam; then
    echo "[$(date)] [ERROR] Failed to configure \"$WEBCAM_NAME\"!";
    webcam_notify "Failed to configure webcam" "Please try to re-connect the webcam or check the configuration file";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# Read applied webcam format
HAS_CONFIGURED_FORMAT=$(v4l2-ctl --device="$VIDEO_DEVICE" --get-fmt-video | grep -i "Pixel Format.*'$WEBCAM_CONFIG_FORMAT'");

# If applied format does not match the configured format, tell user
if [ -z "$HAS_CONFIGURED_FORMAT" ]; then
    echo "[$(date)] [ERROR] Failed to set pixel format \"$WEBCAM_CONFIG_FORMAT\" for \"$WEBCAM_NAME\"!";
    webcam_notify "Failed to configure webcam" "Please try to re-connect the webcam or check the configuration file";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# Read applied webcam resolution
HAS_CONFIGURED_RESOLUTION=$(v4l2-ctl --device="$VIDEO_DEVICE" --get-fmt-video | grep -i "Width/Height.*$WEBCAM_CONFIG_WIDTH/$WEBCAM_CONFIG_HEIGHT");

# If applied resolution does not match the configured resolution, tell user
if [ -z "$HAS_CONFIGURED_RESOLUTION" ]; then
    echo "[$(date)] [ERROR] Failed to set resolution \"$WEBCAM_CONFIG_WIDTH x $WEBCAM_CONFIG_HEIGHT\" for \"$WEBCAM_NAME\"!";
    webcam_notify "Failed to configure webcam" "Please try to re-connect the webcam or check the configuration file";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# Read applied webcam FPS
HAS_CONFIGURED_FPS=$(v4l2-ctl --device="$VIDEO_DEVICE" --get-parm | grep -i "Frames per second.*$WEBCAM_CONFIG_FPS\.000");

# If applied FPS does not match the configured FPS, tell user
if [ -z "$HAS_CONFIGURED_FPS" ]; then
    echo "[$(date)] [ERROR] Failed to set FPS \"$WEBCAM_CONFIG_FPS\" for \"$WEBCAM_NAME\"!";
    webcam_notify "Failed to configure webcam" "Please try to re-connect the webcam or check the configuration file";
    rm -f "$LOCK_FILE";
    exit 1;
fi;

# If everything is configured correctly, log the applied settings
{
    v4l2-ctl --device="$VIDEO_DEVICE" --get-fmt-video;
    v4l2-ctl --device="$VIDEO_DEVICE" --get-parm;
    echo "[$(date)] [INFO] \"$WEBCAM_NAME\" has been configured!";
};

# Final success message and lock cleanup
webcam_notify "Webcam ready to use" "The webcam has been successfully configured";
rm -f "$LOCK_FILE";
