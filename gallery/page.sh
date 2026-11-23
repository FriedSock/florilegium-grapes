#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
showcase
rasterise showcase.pdf 2 gallery/page.png 662
