#!/usr/bin/env bash
set -euo pipefail
# Regenerate simSOMA_tutorial.html from simSOMA_tutorial.md (requires pandoc).
#   bash render_tutorial.sh
cd "$(dirname "$0")"
pandoc simSOMA_tutorial.md --from markdown --to html5 --standalone --toc --toc-depth=2 \
  --css tutorial_style.css --embed-resources --output simSOMA_tutorial.html
echo "Wrote simSOMA_tutorial.html"
