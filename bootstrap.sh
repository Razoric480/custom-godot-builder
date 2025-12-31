#!/bin/bash

mv /inject/start.sh /start.sh
git clone -b ${GODOT_BRANCH} --depth=1 --single-branch https://github.com/${GODOT_REPO}.git
mv /inject/custom.py /godot/custom.py
./start.sh
