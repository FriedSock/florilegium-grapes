set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

latex() {
  local dir=$1 tex=$2
  (cd "$dir" && lualatex -interaction=nonstopmode -halt-on-error "$tex" >/dev/null) || {
    tail -20 "$dir/${tex%.tex}.log"
    exit 1
  }
}

showcase() { latex . showcase.tex; }

trenzado_showcase() {
  lualatex -interaction=nonstopmode -halt-on-error -output-directory=gallery gallery/trenzado-showcase.tex >/dev/null || {
    tail -20 gallery/trenzado-showcase.log
    exit 1
  }
}

composite() { latex gallery "$1.tex"; }

rasterise() { swift gallery/rasterise.swift "$@"; }
