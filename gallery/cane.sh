#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cane_showcase
composite cane
rasterise gallery/cane.pdf 1 gallery/cane.png 2560
