#!/usr/bin/env bash
set -euo pipefail

# Requirements:
#   - unzip, zip
#   - cjxl (JPEG XL encoder)

out_dir="optimized_epubs"
mkdir -p "$out_dir"

for epub in *.epub; do
  base="${epub%.epub}"
  tmpdir="${base}.tmp"

  echo "→ Processing '$epub' …"
  rm -rf "$tmpdir" && mkdir "$tmpdir"
  unzip -q "$epub" -d "$tmpdir"

  # Re-encode images in-place, skipping any that error
  find "$tmpdir" -type f \( -iname '*.png' -o -iname '*.jpg' \) -print0 \
    | while IFS= read -r -d '' img; do
        echo "   • Trying to re-encode '$img' …"
        # run cjxl, capture failure
        if cjxl -q 75 --lossless_jpeg=0 "$img" "${img}.jxl"; then
          mv -- "${img}.jxl" "$img"
          echo "     ✓ Success"
        else
          echo "     ⚠ Warning: conversion failed, leaving original"
          rm -f "${img}.jxl"
        fi
      done

  out_epub="${out_dir}/${base}_optimized.epub"
  pushd "$tmpdir" > /dev/null

    zip -q -X0 "../$out_epub" mimetype
    zip -q -rDX9 "../$out_epub" . -x mimetype

  popd > /dev/null

  echo "✔ Created '$out_epub'"
  rm -rf "$tmpdir"
done

echo "All done! Optimized EPUBs are in '$out_dir/'"
