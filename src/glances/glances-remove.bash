#!/bin/bash

##
## This file is part of the `src-run/raspberry-scripts-bash` package.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, view the LICENSE.md
## file distributed with this source code.
##

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

function main() {
  local logger_path

  printf -- 'Working to clean up prior "glances" build files in "%s" ...\n' "${script_path}"

  if ! script_path="$(get_self_dirpath)"; then
    printf -- 'Failure to resolve locater executable to resolve path "%s" ... Exiting prematurely!\n' "${BASH_SOURCE[0]}"
    exit 255
  fi

  for p in bin include lib share; do
    printf -- 'Removal of prior installation path "%s" in progress ... ' "${script_path:?}/${p}"
    if rm -fr "${script_path:?}/${p}" 2> /dev/null; then
      printf -- '[success]\n'
    else
      printf -- '[failure] (continuing regardless)\n' "${logger_path}"
    fi
  done
}

main
