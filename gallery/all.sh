#!/usr/bin/env bash
set -euo pipefail
dir=$(dirname "${BASH_SOURCE[0]}")
for image in page detail-bunch detail-leaves varieties seasons trenzado cane widths; do
  echo "$image"
  "$dir/$image.sh"
done
