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

#
# launch shellcheck executable (and optionally install if not found)
#

function runner_defaults() {
    local    name_bin='bpytop'
    local    main_bin="$(get_self_dirpath)/${name_bin}.bash"
    local -a main_opt=('--defaults')

    if [[ ! -e "${main_bin}" ]]; then
        printf -- 'Unable to execute the "%s" executable at "%s".\n' "${name_bin}" "${inst_bin}"
        printf -- 'This is a fatal error...\n'

        exit 255
    fi

    "${main_bin}" "${main_opt[@]}"
}

#
# invoke main sub routine
#

runner_defaults "${@}"
