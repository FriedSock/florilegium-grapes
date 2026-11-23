#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
showcase
rasterise showcase.pdf 4 gallery/detail-leaves.png 900 0 20 76 76
