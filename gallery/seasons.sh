#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
showcase
composite seasons
rasterise gallery/seasons.pdf 1 gallery/seasons.png 802
