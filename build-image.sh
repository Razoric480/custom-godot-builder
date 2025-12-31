#!/bin/bash

USERNAME="razoric480"
VERSION="1.0.0"

podman build -t godot-builder -f image-specs.DockerFile .
podman tag localhost/godot-builder docker.io/${USERNAME}/godot-learn-builder:${VERSION}
podman push docker.io/${USERNAME}/godot-learn-builder:${VERSION}
