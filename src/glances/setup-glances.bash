#!/bin/bash

function main() {
  local realpath
  local selfpath
  local logspath

  if ! realpath="$(command -v realpath)" 2>/dev/null; then
    if ! realpath="$(command -v readlink)" 2>/dev/null; then
      printf -- 'Failure locating either the "realpath" or the "readlink" executable path... Exiting prematurely!\n'
      return 255
    fi
  fi

  if ! selfpath="$(
    dirname "$(
      "${realpath}" -m "${BASH_SOURCE[0]}" 2>/dev/null
    )" 2>/dev/null
  )"; then
    printf -- 'Failure resolving real path of this script... Exiting prematurely!\n'
    return 255
  fi

  if [[ ${#selfpath} -lt 2 ]]; then
    printf -- 'Failure resolving real path of this script... Rufusing to continue with possible root resolution of "%s"... Exiting prematurely.!\n' "${selfpath}"
  fi

  if cd "${selfpath}" 2>/dev/null; then
    printf -- 'Success entering path "%s"...\n' "${selfpath}"
  else
    printf -- 'Failure entering path "%s"... Exiting prematurely!\n' "${selfpath}"
    return 255
  fi

  logspath="${selfpath}/.setup-glances.log"

  for p in bin include lib share; do
    if rm -fr "${selfpath:?}/${p}" 2>/dev/null; then
      printf -- 'Success removing path "%s"...\n' "${selfpath:?}/${p}"
    else
      printf -- 'Failure removing path "%s"...\n' "${selfpath:?}/${p}"
    fi
  done

  printf -- 'Working to creat "python3" virtualenv for "glances" in "%s"... ' "${selfpath}"

  if python -m virtualenv -p python3 "${selfpath}" &>"${logspath}"; then
    printf -- 'Completed!\n'
  else
    printf -- 'Encountered an unexpected error!\nLogging file located at "%s"... Exiting prematurely!\n' "${logspath}"
    return 255
  fi

  printf -- 'Working to activate "virtualenv" created for "glances" in "%s"... ' "${selfpath}"

  if . ./bin/activate &>"${logspath}"; then
    printf -- 'Completed!\n'
  else
    printf -- 'Encountered an unexpected error!\nLogging file located at "%s"... Exiting prematurely!\n' "${logspath}"
    return 255
  fi

  printf -- 'Working to install "glances[all]" using "pip" in "%s"... ' "${selfpath}"

  if pip install 'glances[all]' &>"${logspath}"; then
    printf -- 'Completed!\n'
  else
    printf -- 'Encountered an unexpected error!\nLogging file located at "%s"... Exiting prematurely!\n' "${logspath}"
    return 255
  fi

  printf -- 'Success installing "glances[all]"... Check "%s" for related executables!\n' "${selfpath}/bin"

  rm "${logspath}" 2>/dev/null
}

main
