#!/bin/bash

set -e

curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v0.9.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v0.9.0.tgz

sudo mkdir -p /opt/cni/bin

sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz