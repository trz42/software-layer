#!/bin/bash
#
# Script to check the result of building the EESSI software layer.
# Intended use is that it is called by a (batch) job running on a compute
# node.
#
# This script is part of the EESSI software layer, see
# https://github.com/EESSI/software-layer.git
#
# author: Thomas Roeblitz (@trz42)
#
# license: GPLv2
#

# result cases

#  - SUCCESS (all of)
#    - working directory contains slurm-JOBID.out file
#    - working directory contains eessi*tar.gz
#    - no message ERROR
#    - no message FAILED
#    - no message ' required modules missing:'
#    - one or more of 'No missing modules!'
#    - message regarding created tarball
#  - FAILED (one of ... implemented as NOT SUCCESS)
#    - no slurm-JOBID.out file
#    - no tarball
#    - message with ERROR
#    - message with FAILED
#    - message with ' required modules missing:'
#    - no message regarding created tarball

# stop as soon as something fails
# set -e

TOPDIR=$(dirname $(realpath $0))

source ${TOPDIR}/../scripts/utils.sh
source ${TOPDIR}/../scripts/cfg_files.sh

display_help() {
  echo "usage: $0 [OPTIONS]"
  echo " OPTIONS:"
  echo "  -h | --help    - display this usage information [default: false]"
  echo "  -v | --verbose - display more information [default: false]"
}

# set defaults for command line arguments
VERBOSE=0

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      display_help
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=1
      shift 1
      ;;
    --)
      shift
      POSITIONAL_ARGS+=("$@") # save positional args
      break
      ;;
    -*|--*)
      fatal_error "Unknown option: $1" "${CMDLINE_ARG_UNKNOWN_EXITCODE}"
      ;;
    *)  # No more options
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

job_dir=${PWD}

[[ ${VERBOSE} -ne 0 ]] && echo ">> analysing job in directory ${job_dir}"

GP_slurm_out="slurm-${SLURM_JOB_ID}.out"
job_out=$(ls ${job_dir} | grep "${GP_slurm_out}")
[[ $? -eq 0 ]] && SLURM=1 || SLURM=0
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for job output file(s) matching '"${GP_slurm_out}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "   found slurm output file '"${job_out}"'"

GP_error='ERROR: '
grep_out=$(grep "${GP_error}" ${job_dir}/${job_out})
[[ $? -eq 0 ]] && ERROR=1 || ERROR=0
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for '"${GP_error}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "${grep_out}"

GP_failed='FAILED: '
grep_out=$(grep "${GP_failed}" ${job_dir}/${job_out})
[[ $? -eq 0 ]] && FAILED=1 || FAILED=0
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for '"${GP_failed}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "${grep_out}"

GP_req_missing=' required modules missing:'
grep_out=$(grep "${GP_req_missing}" ${job_dir}/${job_out})
[[ $? -eq 0 ]] && MISSING=1 || MISSING=0
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for '"${GP_req_missing}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "${grep_out}"

GP_no_missing='No missing modules!'
grep_out=$(grep "${GP_no_missing}" ${job_dir}/${job_out})
[[ $? -eq 0 ]] && NO_MISSING=1 || NO_MISSING=0
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for '"${GP_no_missing}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "${grep_out}"

GP_tgz_created="tar.gz created!"
TARBALL=
grep_out=$(grep "${GP_tgz_created}" ${job_dir}/${job_out})
if [[ $? -eq 0 ]]; then
    TGZ=1
    TARBALL=$(echo ${grep_out} | sed -e 's@^.*\(eessi[^/ ]*\) .*$@\1@')
else
    TGZ=0
fi
# have to be careful to not add searched for pattern into slurm out file
[[ ${VERBOSE} -ne 0 ]] && echo ">> searching for '"${GP_tgz_created}"'"
[[ ${VERBOSE} -ne 0 ]] && echo "${grep_out}"

[[ ${VERBOSE} -ne 0 ]] && echo "SUMMARY: ${job_dir}/${job_out}"
[[ ${VERBOSE} -ne 0 ]] && echo "  test name  : result (expected result)"
[[ ${VERBOSE} -ne 0 ]] && echo "  ERROR......: $([[ $ERROR -eq 1 ]] && echo 'yes' || echo 'no') (no)"
[[ ${VERBOSE} -ne 0 ]] && echo "  FAILED.....: $([[ $FAILED -eq 1 ]] && echo 'yes' || echo 'no') (no)"
[[ ${VERBOSE} -ne 0 ]] && echo "  REQ_MISSING: $([[ $MISSING -eq 1 ]] && echo 'yes' || echo 'no') (no)"
[[ ${VERBOSE} -ne 0 ]] && echo "  NO_MISSING.: $([[ $NO_MISSING -eq 1 ]] && echo 'yes' || echo 'no') (yes)"
[[ ${VERBOSE} -ne 0 ]] && echo "  TGZ_CREATED: $([[ $TGZ -eq 1 ]] && echo 'yes' || echo 'no') (yes)"

job_result_file=_bot_job${SLURM_JOB_ID}.result

if [[ ${SLURM} -eq 1 ]] && \
   [[ ${ERROR} -eq 0 ]] && \
   [[ ${FAILED} -eq 0 ]] && \
   [[ ${MISSING} -eq 0 ]] && \
   [[ ${NO_MISSING} -eq 1 ]] && \
   [[ ${TGZ} -eq 1 ]] && \
   [[ ! -z ${TARBALL} ]]; then
    # SUCCESS
    summary=":grin: SUCCESS"
    status="success"
else
    # FAILURE
    summary=":cry: FAILURE"
    status="failure"
fi

### Example details/descriptions
#
# <details><summary>:cry: FAILURE _(click triangle for detailed information)_</summary>Details:<br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: job output file <code>slurm-470503.out</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_multiplication_x: found message matching <code>ERROR: </code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_multiplication_x: found message matching <code>FAILED: </code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_multiplication_x: found message matching <code> required modules missing:</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message(s) matching <code>No missing modules!</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message matching <code>tar.gz created!</code><br/>Artefacts:<li><code>eessi-2023.04-software-linux-x86_64-amd-zen2-1682384569.tar.gz</code></li></details>
#
# <details><summary>:grin: SUCCESS _(click triangle for detailed information)_</summary>Details:<br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: job output file <code>slurm-470503.out</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message matching <code>ERROR: </code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message matching <code>FAILED: </code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message matching <code> required modules missing:</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message(s) matching <code>No missing modules!</code><br/>&nbsp;&nbsp;&nbsp;&nbsp;:heavy_check_mark: found message matching <code>tar.gz created!</code><br/>Artefacts:<li><code>eessi-2023.04-software-linux-x86_64-amd-zen2-1682384569.tar.gz</code></li></details>
#
###

# construct and write complete PR comment details
comment_template="<details>__SUMMARY_FMT____DETAILS_FMT____ARTEFACTS_FMT__</details>"
comment_summary_fmt="<summary>__SUMMARY__ _(click triangle for detailed information)_</summary>"
comment_details_fmt="Details:<br/>__DETAILS_LIST__"
comment_artefacts_fmt="Artefacts:<br/>__ARTEFACTS_LIST__"
comment_success_item_fmt=":heavy_check_mark: __ITEM__"
comment_failure_item_fmt=":heavy_multiplication_x: __ITEM__"

function print_br_item() {
    format="${1}"
    item="${2}"
    echo -n "&nbsp;&nbsp;&nbsp;&nbsp;${format//__ITEM__/${item}}<br/>"
}

function print_list_item() {
    format="${1}"
    item="${2}"
    echo -n "<li>${format//__ITEM__/${item}}</li>"
}

function success() {
    format="${comment_success_item_fmt}"
    item="$1"
    print_br_item "${format}" "${item}"
}

function failure() {
    format="${comment_failure_item_fmt}"
    item="$1"
    print_br_item "${format}" "${item}"
}

function add_detail() {
    actual=${1}
    expected=${2}
    success_msg="${3}"
    failure_msg="${4}"
    if [[ ${actual} -eq ${expected} ]]; then
        success "${success_msg}"
    else
        failure "${failure_msg}"
    fi
}

echo "[RESULT]" > ${job_result_file}
echo -n "comment_description = " >> ${job_result_file}

# construct values for placeholders in comment_template:
# - __SUMMARY_FMT__ -> variable $comment_summary
# - __DETAILS_FMT__ -> variable $comment_details
# - __ARTEFACTS_FMT__ -> variable $comment_artefacts

comment_summary="${comment_summary_fmt/__SUMMARY__/${summary}}"

# first construct comment_details_list, abbreviated CoDeList
# then use it to set comment_details
CoDeList=""

success_msg="job output file <code>${job_out}</code>"
failure_msg="no job output file matching <code>${GP_slurm_out}</code>"
CoDeList=${CoDeList}$(add_detail ${SLURM} 1 "${success_msg}" "${failure_msg}")

success_msg="no message matching <code>${GP_error}</code>"
failure_msg="found message matching <code>${GP_error}</code>"
CoDeList=${CoDeList}$(add_detail ${ERROR} 0 "${success_msg}" "${failure_msg}")

success_msg="no message matching <code>${GP_failed}</code>"
failure_msg="found message matching <code>${GP_failed}</code>"
CoDeList=${CoDeList}$(add_detail ${FAILED} 0 "${success_msg}" "${failure_msg}")

success_msg="no message matching <code>${GP_req_missing}</code>"
failure_msg="found message matching <code>${GP_req_missing}</code>"
CoDeList=${CoDeList}$(add_detail ${MISSING} 0 "${success_msg}" "${failure_msg}")

success_msg="found message(s) matching <code>${GP_no_missing}</code>"
failure_msg="no message matching <code>${GP_no_missing}</code>"
CoDeList=${CoDeList}$(add_detail ${NO_MISSING} 1 "${success_msg}" "${failure_msg}")

success_msg="found message matching <code>${GP_tgz_created}</code>"
failure_msg="no message matching <code>${GP_tgz_created}</code>"
CoDeList=${CoDeList}$(add_detail ${TGZ} 1 "${success_msg}" "${failure_msg}")

comment_details="${comment_details_fmt/__DETAILS_LIST__/${CoDeList}}"


# first construct comment_artefacts_list, abbreviated CoArList
# then use it to set comment_artefacts
CoArList=""

# TARBALL should only contain a single tarball
if [[ ! -z ${TARBALL} ]]; then
    CoArList=${CoArList}$(print_list_item '<code>__ITEM__</code>' "${TARBALL}")
else
    CoArList=${CoArList}$(print_list_item 'No artefacts were created/found.' '')
fi
comment_artefacts=${comment_artefacts_fmt/__ARTEFACTS_LIST__/${CoArList}}

# now put all pieces together creating comment_details from comment_template
comment_description=${comment_template/__SUMMARY_FMT__/${comment_summary}}
comment_description=${comment_description/__DETAILS_FMT__/${comment_details}}
comment_description=${comment_description/__ARTEFACTS_FMT__/${comment_artefacts}}

echo "${comment_description}" >> ${job_result_file}

# add overall result: SUCCESS, FAILURE, UNKNOWN + artefacts
# - this should make use of subsequent steps such as deploying a tarball more
#   efficient
echo "status = ${status}" >> ${job_result_file}
echo "artefacts = " >> ${job_result_file}
echo "${TARBALL}" | sed -e 's/^/    /g' >> ${job_result_file}

exit 0
