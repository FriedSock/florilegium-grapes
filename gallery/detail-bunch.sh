#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
showcase
rasterise showcase.pdf 2 gallery/detail-bunch.png 900 0 140 76 76
