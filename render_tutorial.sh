#!/usr/bin/env bash
set -euo pipefail

# Regenerate the polished HTML tutorial from the Markdown source.
# Run this script from the simSOMA-tutorial repository root:
#
#   bash render_tutorial.sh
#
# Requirements:
#   pandoc

pandoc simSOMA_tutorial.md \
  --from markdown \
  --to html5 \
  --standalone \
  --metadata pagetitle="simSOMA tutorial" \
  --css tutorial_style.css \
  --embed-resources \
  --output simSOMA_tutorial.html

echo "Wrote simSOMA_tutorial.html"
