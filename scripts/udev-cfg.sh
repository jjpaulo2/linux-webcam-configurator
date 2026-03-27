#!/usr/bin/env bash
# 
# Webcam Linux Configurator
# https://github.com/jjpaulo2/linux-webcam-configurator
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

# Path for the udev rules file
RULES_FILE="/etc/udev/rules.d/99-webcam.rules";

# Path for the webcam configuration script
CONFIG_SCRIPT="/usr/local/bin/webcam-cfg";

# Path for the logs file for the webcam configuration script
LOGS_FILE="/var/log/webcam-cfg.log";

# Path for the configuration JSON file
CONFIG_FILE="/etc/webcam-cfg.json";

# If configuration file does not exist, tell user
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[$(date)] [ERROR] Couldn't read configurations from \"$CONFIG_FILE\"!";
    exit 1;
fi;

# Load webcam configuration
WEBCAM_NAME=$(jq -r '.name' "$CONFIG_FILE");

# Reading webcam ID from lsusb output
DEVICE_ID=$(lsusb | grep -i "$WEBCAM_NAME" | grep -oP "\w{4}:\w{4}");

# If no device ID is found, tell user
if [ -z "$DEVICE_ID" ]; then
    echo "[$(date)] [ERROR] Webcam \"$WEBCAM_NAME\" not found!";
    exit 1;
fi;

# Reading webcam vendor and product ID
ID_VENDOR=${DEVICE_ID%:*}
ID_PRODUCT=${DEVICE_ID#*:}

echo "\
SUBSYSTEM==\"video4linux\", \
KERNEL==\"video[0-9]*\", \
ATTRS{idVendor}==\"$ID_VENDOR\", \
ATTRS{idProduct}==\"$ID_PRODUCT\", \
RUN+=\"/bin/bash -c '$CONFIG_SCRIPT >> $LOGS_FILE 2>&1'\"" > "$RULES_FILE";

echo "[$(date)] [INFO] Udev rule for webcam \"$WEBCAM_NAME\" has been created at \"$RULES_FILE\".";