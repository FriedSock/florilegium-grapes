#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
trenzado_showcase
composite trenzado
rasterise gallery/trenzado.pdf 1 gallery/trenzado.png 2560
