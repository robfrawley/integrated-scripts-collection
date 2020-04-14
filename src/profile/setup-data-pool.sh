#!/bin/sh

##
## This file is part of the `src-run/bash-bright-library` package.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, view the LICENSE.md
## file distributed with this source code.
##


##
## define script variables
##

#
# the root path to our custom data directory
#
DATA_POOL_INIT__VERBOSITY="${VERBOSITY:-${DEBUG:-0}}"

#
# the root path to our custom data directory
#
DATA_POOL_INIT__ROOT_PATH='/data'


##
## define script functions
##

#
# attempt to resolve the real, absolute path of a binary
#
data_pool_init__locate_binary_absolute_path()
{
  command_name="$1"
  final_return=0

  if ! command_path="$(command -v "${command_name}" 2>/dev/null)"; then
    final_return=255
  fi

  printf -- '%s' "${command_path:-${command_name}}"

  return "${final_return}"
}

#
#
# write passed strings as independent lines and pass each through gettext
#
data_pool_init__write_each_through_gettext()
{
  if [ "${DATA_POOL_INIT__VERBOSITY:-0}" -le 0 ]; then
    return
  fi

  if ! printer_path="$(data_pool_init__locate_binary_absolute_path printf)"; then
    printer_path='printf'
  fi

  if ! gettext_path="$(data_pool_init__locate_binary_absolute_path gettext)"; then
    gettext_path='gettext'
  fi

  for line in "${@}"; do
    "${gettext_path}" "${line}" 2>/dev/null || "${printer_path}" -- "${line}" 2>/dev/null || echo "${line}" 2>/dev/null
    printf -- '\n'
  done
}

#
# write string line using printf arguments to create final text using format string and any passed replacements
#
data_pool_init__write_printf()
{
  data_pool_init__write_each_through_gettext "$(
    # shellcheck disable=SC2059
    printf -- "${@}"
  )"
}

#
# provide custom binary paths to add to PATH environment variable
#
data_pool_init__provide_bin_paths()
{
  printf -- '%s/scripts/bin\n' "${DATA_POOL_INIT__ROOT_PATH}"
}

#
# provide custom environment variable definitions
#
data_pool_init__provide_env_variables()
{
  printf -- 'DATA_ROOT_PATH=%s\n' "${DATA_POOL_INIT__ROOT_PATH}"
  printf -- 'DATA_BINS_PATH=%s\n' "$(data_pool_init__provide_bin_paths | tr '\n' ':' | sed 's/.$//')"
}


#
# provide script variables that are only used internally and should therefore be cleaned up
#

data_pool_init__provide_scr_variables()
{
  for v in 'DATA_POOL_INIT__BASH_VERS_FILE_NAME' 'DATA_POOL_INIT__ROOT_PATH' 'DATA_POOL_INIT__VERBOSITY'; do
    printf -- '%s\n' "${v}"
  done
}


#
# register custom binary paths in PATH environment variable
#

data_pool_init__register_bin_paths()
{
  out_subs_act_format='[STEP]       -> %s adding bin dir "%s" to env path variable'
  data_pool_init__write_printf \
    '[SECT]    -- Registering bin directories with priority to the environment path variable:'

  IFS_PRIOR="$IFS"
  IFS='
'
  for p in $(data_pool_init__provide_bin_paths); do
    if test "${PATH#*$p}" != "${PATH}"; then
      data_pool_init__write_printf "${out_subs_act_format} (location already exists in PATH variable) ..." 'Skipped' "${p}"
    elif [ -e "${p}" ] && [ -r "${p}" ]; then
      if export PATH="${p}:${PATH}" 2>/dev/null; then
        data_pool_init__write_printf "${out_subs_act_format} ..." 'Success' "${p}"
      else
        data_pool_init__write_printf "${out_subs_act_format} (encountered an unexpected error) ..." 'Failure' "${p}"
      fi
    else
      data_pool_init__write_printf "${out_subs_act_format} (it does not exist or is not readable within this permissions context) ..." 'Skipped' "${p}"
    fi
  done
  IFS="${IFS_PRIOR}"
}

#
# register custom environment variables
#
data_pool_init__register_env_variables()
{
  out_subs_act_format='[STEP]       -> %s adding env var "%s" with assignment "%s"'
  data_pool_init__write_printf \
    '[SECT]    -- Registering env variables used to interact with the data directory:'

  IFS_PRIOR="$IFS"
  IFS='
'
  for v in $(data_pool_init__provide_env_variables); do
    var_i="${v%%=*}"
    var_v="${v#*=}"

    if [ "$(eval printf -- "\$$var_i" 2>/dev/null)" = "" ]; then
      if export "${var_i}"="${var_v}" 2>/dev/null; then
        data_pool_init__write_printf "${out_subs_act_format} ..." 'Success' "${var_i}" "${var_v}"
      else
        data_pool_init__write_printf "${out_subs_act_format} (encountered an unexpected error) ..." 'Failure' "${var_i}" "${var_v}"
      fi
    else
      data_pool_init__write_printf \
        "${out_subs_act_format} (an env var of the same name already exists with assignment \"%s\") ..." 'Skipped' "${var_i}" \
        "${var_v}" "$(eval printf -- "\$$var_i" 2>/dev/null)"
    fi
  done
  IFS="${IFS_PRIOR}"
}


#
# cleanup all extraneous environment variables used for the purpose of this script
#

data_pool_init__clean_up_scr_variables()
{
  out_subs_act_format='[STEP]       -> %s unsetting script runtime variable "%s"'

  data_pool_init__write_printf \
    '[SECT]    -- Cleaning up scr variables used during script runtime but extraneous outside this context:'

  IFS_PRIOR="$IFS"
  IFS='
'
  for v in $(data_pool_init__provide_scr_variables); do
    if [ -n "${v}" ]; then
      if unset "${v}" 2>/dev/null; then
        data_pool_init__write_printf "${out_subs_act_format} ..." 'Success' "${v}"
      else
        data_pool_init__write_printf "${out_subs_act_format} (encountered an unknown error attempting to unset it) ..." 'Failure' "${v}"
      fi
    else
      data_pool_init__write_printf "${out_subs_act_format} (must not have been used during runtime or was otherwise unser prior) ..." 'Skipped' "${v}"
    fi
  done
  IFS="${IFS_PRIOR}"
}

#
# entry script function
#
data_pool_init__main()
{
  out_main_act_format="$(
    printf -- '[%%s] ## Configuring env for resources provided by "%s" (a dir containing user-generated assets).' "${DATA_POOL_INIT__ROOT_PATH}"
  )"
  data_pool_init__write_printf "${out_main_act_format}" 'INIT'

  data_pool_init__register_bin_paths
  data_pool_init__register_env_variables

  data_pool_init__write_printf "${out_main_act_format}" 'DONE'

  data_pool_init__clean_up_scr_variables
}


##
## setup gettext
##

#
# configure environment variables for gettext
#

export TEXTDOMAIN=Linux-PAM


#
# source any additional gettext configurations
#

# shellcheck source=/usr/bin/gettext.sh
. gettext.sh


##
## invoke entry script function to kick everything off
##

data_pool_init__main
