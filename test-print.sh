#!/usr/bin/env bash
set -euo pipefail

cv_test_dir=$(mktemp -d)
trap 'rm -rf "$cv_test_dir"' EXIT

for language in pt en; do
  sed "s/setLanguage(getInitialLanguage());/setLanguage(\"$language\");/" index.html > "$cv_test_dir/$language.html"

  google-chrome \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --print-to-pdf="$cv_test_dir/$language.pdf" \
    "file://$cv_test_dir/$language.html" >/dev/null 2>&1

  pages=$(pdfinfo "$cv_test_dir/$language.pdf" | awk '/^Pages:/ { print $2 }')
  if [[ "$pages" != 1 ]]; then
    echo "$language: esperado PDF com 1 página; recebido: $pages" >&2
    exit 1
  fi

  pdftotext "$cv_test_dir/$language.pdf" "$cv_test_dir/$language.txt"

  if grep -Eq 'file://|Lucas Christian • Software Developer|[[:space:]][0-9]+/[0-9]+[[:space:]]*$' "$cv_test_dir/$language.txt"; then
    echo "$language: cabeçalho ou rodapé do navegador encontrado no PDF" >&2
    exit 1
  fi
done

grep -Fq "Set/2025 – Atual" "$cv_test_dir/pt.txt"
grep -Fq "Sep 2025 – Present" "$cv_test_dir/en.txt"

echo "PDF PT/EN: 1 página, datas corretas e sem cabeçalhos ou rodapés"
