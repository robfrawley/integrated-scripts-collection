#!/bin/bash

##
## This file is part of the `src-run/raspberry-scripts-bash` package.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, view the LICENSE.md
## file distributed with this source code.
##

#
# get the real dirpath of this script
#

function get_self_dirpath() {
  local locator_bin
  local located_scr

  for b in readlink realpath; do
    if locator_bin="$(command -v "${b}")"; then
      break
    fi
  done

  if [[ -n ${locator_bin} ]] && located_scr="$("${locator_bin}" -e "${BASH_SOURCE[0]}")"; then
    printf -- '%s' "$(dirname "${located_scr}")"
    return 0
  fi

  return 255
}

function source_bright_library() {
    local bright_file='../../inc/bright/bright.bash'

    bright_file="$(get_self_dirpath)/${bright_file}"

    if [[ ! -f "${bright_file}" ]]; then
        printf 'Failed to source required dependency: "%s" ...\n' "${bright_file}"
        exit 1
    fi

    source "${bright_file}"
}

function sty() {
    echo -en "$(printf -- "${@}")"
}

function out() {
    _out '@ctl:no-nl' "${@}"
}

function nls() {
    for i in $(seq 1 "${1:-1}"); do printf -- '\n'; done
}

function out_clocks() {
    local styleDefault="$(_get_reset)"
    local styleHeading="$(_get '@style:bold')"
    local styleReverse="$(_get '@fg:black' '@bg:white' '@style:bold')"
    local styleRegular=""

    nls
    sty ' %s - CLOCK MEASURMENTS - %s' "${styleReverse}" "${styleDefault}"
    nls 2

    for src in arm core h264 isp v3d uart pwm emmc pixel vec hdmi dpi; do
        sty ' Device "%s%06s%s" => "%s%s%s"' \
            "${styleHeading}" \
            "${src}" \
            "${styleDefault}" \
            "${styleHeading}" \
            "$(
                vcgencmd measure_clock "${src}" | \
                    grep -oE '[0-9]+$'
            )" \
            "${styleDefault}"

        nls
    done

    nls
}

function main() {
    source_bright_library
    out_clocks
}

main
