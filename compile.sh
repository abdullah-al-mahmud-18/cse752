#!/usr/bin/env bash
# Compile a .tex file with pdflatex.
# Usage: ./compile.sh <file.tex> <output-dir>
# Intermediate files go to build/<name>/, the PDF to <output-dir>.
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <file.tex> <output-dir>" >&2
    exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "error: pdflatex not found in PATH" >&2
    exit 1
fi

# Accept the file name with or without the .tex extension
TEX_FILE="$1"
[[ "$TEX_FILE" == *.tex ]] || TEX_FILE="$TEX_FILE.tex"
if [[ ! -f "$TEX_FILE" ]]; then
    echo "error: file not found: $TEX_FILE" >&2
    exit 1
fi

TEX_DIR="$(cd "$(dirname "$TEX_FILE")" && pwd)"
NAME="$(basename "$TEX_FILE" .tex)"

mkdir -p "$2"
OUT_DIR="$(cd "$2" && pwd)"
BUILD_DIR="$ROOT/build/$NAME"

# build/lectures is needed if lectures are ever pulled in with \include (it writes per-file .aux)
mkdir -p "$BUILD_DIR/lectures"

# Run from the .tex file's directory so relative \input paths resolve
cd "$TEX_DIR"

# Two passes so the table of contents and cross-references resolve
for pass in 1 2; do
    echo "==> pdflatex pass $pass ($NAME.tex)"
    pdflatex -interaction=nonstopmode -halt-on-error -file-line-error \
        -output-directory="$BUILD_DIR" "$NAME.tex" >/dev/null || {
        echo "error: pdflatex failed, see $BUILD_DIR/$NAME.log" >&2
        grep -E '^.+:[0-9]+:|^!' "$BUILD_DIR/$NAME.log" | head -n 20 >&2 || true
        exit 1
    }
done

if [[ ! -f "$BUILD_DIR/$NAME.pdf" ]]; then
    echo "error: expected PDF was not generated at $BUILD_DIR/$NAME.pdf" >&2
    exit 1
fi

mv -f "$BUILD_DIR/$NAME.pdf" "$OUT_DIR/$NAME.pdf"
echo "==> built $OUT_DIR/$NAME.pdf"
