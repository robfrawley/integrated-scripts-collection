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

function runner_main() {
    local    name_bin='bpytop'
    local    inst_bin="$(get_self_dirpath)/${name_bin}-install.bash"
    local    main_bin="$(get_self_dirpath)/bin/${name_bin}"
    local -a defs_opt=('-hide-stderr')
    local -a main_opt=("${@}")
    local -a parm_opt=()
    local -a used_opt=()
    local -a parm_def=('defaults' 'default' 'defs' 'def' 'D')
    local -a parm_rdr=('hide-stderr' 'no-stderr' 'hide-errors' 'no-errors' 'hide-err' 'no-err' 'H' 'N')
    local    hide_err=0

    for o in "${main_opt[@]}"; do
      for p in "${parm_def[@]}"; do
        if [[ "${o}" == "-${p}" ]] || [[ "${o}" == "--${p}" ]]; then
          parm_opt+=("${defs_opt[@]}"); continue 2
        fi
      done

      parm_opt+=("${o}")
    done

    for o in "${parm_opt[@]}"; do

      for p in "${parm_rdr[@]}"; do
        if [[ "${o}" == "-${p}" ]] || [[ "${o}" == "--${p}" ]]; then
          hide_err=1; continue 2
        fi
      done

      used_opt+=("${o}")
    done


## DEBUG:START

local -a scalar_varset=(name_bin inst_bin main_bin hide_err)
local -a arrays_varset=(parm_def parm_rdr defs_opt main_opt parm_opt used_opt)


printf -- '\n\n\n## variables[scalar]: %d defined\n\n\n' "${#scalar_varset[@]}"

for i_scalar_var in "${scalar_varset[@]}"; do
    printf -- '-- "var:%s" => [ "%s" ]\n' "${i_scalar_var}" "${!i_scalar_var}"
done


printf -- '\n\n\n## variables[arrays]: %d defined\n' "${#arrays_varset[@]}"

for i_arrays_var in "${arrays_varset[@]}"; do
  local      a_arrays_var="${i_arrays_var}[@]"
  declare -n c_arrays_var="${i_arrays_var}"

  printf -- '\n\n>> variables[arrays](%14s:%02d):\n\n' "${i_arrays_var}" "${#c_arrays_var[@]}"

  for rvval in "${!a_arrays_var}"; do
    printf -- '-- "arr:%s" => [ "%s" ]\n' "${i_arrays_var}" "${rvval}"
  done
done

## DEBUG:END

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

    if [[ ${hide_err} -eq 1 ]]; then
      "${main_bin}" "${used_opt[@]}" 2> /dev/null
    else
      "${main_bin}" "${used_opt[@]}"
    fi
}

#
# invoke main sub routine
#

runner_main "${@}"
