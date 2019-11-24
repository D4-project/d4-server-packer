#!/usr/bin/env bash
# Fetching latest MISP LICENSE
/usr/bin/wget -q -O /tmp/LICENSE-D4 ttps://github.com/D4-project/d4-core/blob/master/LICENSE
TMPDIR=./tmp packer build -only=virtualbox-iso d4-server.json
