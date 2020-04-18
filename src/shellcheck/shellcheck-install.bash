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
# get available package version from cache
#

function get_cache_pkg_ver() {
  local name="${1}"

  apt show "${name}" 2> /dev/null \
    | grep -oE '^Version: .+$' 2> /dev/null \
    | cut -d' ' -f2 2> /dev/null
}

#
# get installed package version
#

function get_local_pkg_ver() {
  local name="${1}"

  dpkg -s "${name}" 2> /dev/null \
    | grep -E '^Version: .+$' 2> /dev/null \
    | cut -d' ' -f2 2> /dev/null
}

#
# install passed packages (if not already)
#

function apt_install_packages() {
    local -a package_names=("${@}")

    printf -- '# Working to install %d system dependencies using apt package manager ...\n' "${#package_names[@]}"

    for p in "${package_names[@]}"; do
      printf -- '  - Working to install package "%s" (targeting version "%s") ... ' "${p}" "$(get_cache_pkg_ver "${p}")"

      if dpkg -s "${p}" 2> /dev/null | grep installed &> /dev/null; then
        printf -- '[SKIPPED] (found version "%s")\n' "$(get_local_pkg_ver "${p}")"
      else
        export DEBIAN_FRONTEND=noninteractive

        if sudo apt install "${p}" --assume-yes --quiet &> "${logger_path}"; then
          printf -- '[SUCCESS] (found version "%s")\n' "$(get_local_pkg_ver "${p}")"
        else
          printf -- '[FAILURE] (exiting prematurely)\n'
          exit 255
        fi

        unset DEBIAN_FRONTEND
      fi
    done
}

#
# perform glances install operation
#

function install() {
  local remote_path='https://github.com/koalaman/shellcheck.git'
  local bld_org_bin='.cabal-sandbox/bin/shellcheck'
  local source_path
  local script_path
  local logger_path
  local bld_beg_sec
  local bld_end_sec

  printf '# Working to initialize installer script ...\n'

  printf '  - Finding the absolute directory path of "%s" file (this script) ... ' "$(basename "${BASH_SOURCE[0]}")"

  if script_path="$(get_self_dirpath)"; then
    printf -- '[SUCCESS] (resolved to "%s")\n' "${script_path}/$(basename "${BASH_SOURCE[0]}")"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  source_path="${script_path}/src"

  printf '  - Seeking to enter appropriate working directory for this installation ... '

  if cd "${script_path}" 2> /dev/null; then
    printf -- '[SUCCESS] (changed directory to "%s")\n' "${script_path}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  "${script_path}/shellcheck-remove.bash"

  logger_path="${script_path}/.shellcheck-install.log"

  printf '  - Testing that verbose logging can be written to file ... '

  if rm -fr "${logger_path:?}" &> /dev/null && touch "${logger_path:?}"; then
    printf -- '[SUCCESS] (using "%s" file)\n' "${logger_path:?}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  apt_install_packages libgmp-dev haskell-platform

  printf -- '# Working to ready source for building ...\n'

  printf '  - Seeking to make empty directory path for "shellcheck" source files ... '

  if mkdir -p "${source_path}" &> /dev/null; then
    printf -- '[SUCCESS] (created "%s" directory)\n' "${source_path}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '  - Copying git repository files (using remote URI "%s") ... ' "${remote_path}"

  if git clone "${remote_path}" "${script_path}/src/" &> /dev/null; then
    printf -- '[SUCCESS]\n'
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '# Working to build source using sand-boxed cabal environment ...\n'

  printf '  - Seeking to enter build directory ... '

  if cd "${source_path}" 2> /dev/null; then
    printf -- '[SUCCESS] (changed directory to "%s")\n' "${source_path}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '  - Working to update cabal package database ... '

  if cabal update &> "${logger_path}"; then
    printf -- '[SUCCESS]\n'
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '  - Working to initialize cabal sandbox ... '

  if cabal sandbox init &> "${logger_path}"; then
    printf -- '[SUCCESS] (created in "%s")\n' "${source_path}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '  - Working to add source to cabal sandbox ... '

  if cabal sandbox add-source "${source_path}" &> "${logger_path}"; then
    printf -- '[SUCCESS] (registered "%s")\n' "${source_path}"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  bld_beg_sec="$(date +%s)"

  printf -- '  - Working to build source using cabal (this may take a while) ... '

  if cabal install &> "${logger_path}"; then
    bld_end_sec="$(date +%s)"
    printf -- '[SUCCESS] (took %d minutes and %d seconds)\n' \
      "$(( (${bld_end_sec} - ${bld_beg_sec}) / 60 ))" \
      "$(( (${bld_end_sec} - ${bld_beg_sec}) % 60 ))"
  else
    printf -- '[FAILURE] (exiting prematurely)\n'
    exit 255
  fi

  printf -- '# Working to clean up environment following successful build ...\n'

  printf '  - Seeking to delete log file "%s" ... ' "${logger_path}"

  if rm "${logger_path}" 2>/dev/null; then
    printf -- '[SUCCESS]\n'
  else
    printf -- '[FAILURE]\n'
  fi

  printf '  - Seeking to locate built executable for "shellcheck" ... '

  if [[ -e "${source_path}/${bld_org_bin}" ]]; then
    printf -- '[SUCCESS] (found as "%s")\n' "${source_path}/${bld_org_bin}"
  else
    printf -- '[FAILURE]\n'
  fi
}

#
# invoke main sub routine
#

install
