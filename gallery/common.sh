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

vined() {
  lualatex -interaction=nonstopmode -halt-on-error -output-directory=gallery "gallery/$1.tex" >/dev/null || {
    tail -20 "gallery/$1.log"
    exit 1
  }
}

trenzado_showcase() { vined trenzado-showcase; }

composite() { latex gallery "$1.tex"; }

rasterise() { swift gallery/rasterise.swift "$@"; }
