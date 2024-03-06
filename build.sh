#!/bin/bash

set -euo pipefail
shopt -s nullglob

cdir="$(dirname "$(readlink -f "${0}")")"

if [[ ! -v out_dir ]]; then
    out_dir=./dist
fi
out_dir="$(readlink -f "${out_dir}")"

if [[ ! -v latex_variant ]]; then
    latex_variant=lualatex
fi

OPTS=(-latexoption="-shell-escape -interaction=batch" -halt-on-error -${latex_variant} -output-directory="${out_dir}")

function msg {
    echo "${@}" >&2
}

function die {
    msg "${@}"
    exit 1
}

if [[ $# -lt 1 ]]; then
    die "usage: $0 (build|clean|watch) <file1> ..."
fi

if [[ $# -eq 1 ]]; then
    files=("${cdir}"/slides.tex)
else
    files=()
    for f in "${@:2}"; do
        files+=($(readlink -f "${f}"))
    done
fi

function choice {
    case "${1}" in
        build)
            for f in "${files[@]}"; do
                latexmk ${OPTS[@]} "${f}"
            done
            ;;
        clean)
            cd "${out_dir}"
            latexmk -C
            for f in *.bbl *.run.xml *.aux{,lock} *.log *.fls *-figure*.{pdf,log,dpth,md5}; do
                rm -rvf "${f}"
            done
            ;;
        watch)
            latexmk ${OPTS[@]} -pvc "${files[@]}"
            ;;
        *)
            echo "usage: ${0} (build|clean|watch) file1.tex ..."
            ;;
    esac
}

choice "${@}"
