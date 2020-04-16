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

function install_and_launch() {
    local name_bin='glances'
    local inst_bin="$(get_self_dirpath)/${name_bin}-install.bash"
    local main_bin="$(get_self_dirpath)/bin/${name_bin}"

    if [[ ! -e "${main_bin}" ]]; then
        printf -- 'Unable to execute the "%s" executable at "%s".\n' "${name_bin}" "${inst_bin}"
        printf -- 'Do you want to run the installer executable for "%s" at "%s"?\n' "${name_bin}" "${inst_bin}"
        printf -- 'Press [ENTER] key to continue installation or use [CNTL-C] keys to cancel...\n'
        read && clear

        "${inst_bin}"

        if [[ ! -e "${main_bin}" ]]; then
          printf -- 'Failures encountered during "%s" installation operations!\n' "${name_bin}"
          printf -- 'The newly built "%s" executable was not found at "%s" as expected... Exiting.\n' "${name_bin}" "${main_bin}"
          exit 255
        else
          printf -- 'Successfully completed the "%s" installation operations!\n' "${name_bin}"
          printf -- 'The newly built "%s" executable was found at "%s" and will be directly called by this wrapper in the future.\n' "${name_bin}" "${main_bin}"
          printf -- 'Press [ENTER] key to continue invocation or use [CNTL-C] keys to cancel...\n'
          read && clear
        fi
    fi

    "${main_bin}" "${@}"
}

#
# invoke main sub routine
#

install_and_launch "${@}"
