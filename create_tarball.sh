#!/bin/bash

set -e

if [ $# -ne 3 ]; then
        echo "ERROR: Usage: $0 <EESSI tmp dir (example: /tmp/$USER/EESSI)> <component (software or compat)> <dir to tarball>" >&2
    exit 1
fi
eessi_tmpdir=$1
component=$2
basedir=$3

source init/minimal_eessi_env
# if EESSI_SOFTWARE_SUBDIR not set get it (note can be overridden by EESSI_SOFTWARE_SUBDIR_OVERRIDE)
if [ -z $EESSI_SOFTWARE_SUBDIR ]; then
    source init/eessi_environment_variables
fi

cpu_arch_subdir=${EESSI_SOFTWARE_SUBDIR}
cpu_arch_subdir_converted=$(echo ${EESSI_SOFTWARE_SUBDIR} | tr '/' '-')
pilot_version=$EESSI_PILOT_VERSION

timestamp=$(date +%s)
export target_tgz=$(printf "%s/eessi-%s-%s-%s-%s-%d.tar.gz" ${basedir} ${EESSI_PILOT_VERSION} ${component} ${EESSI_OS_TYPE} ${cpu_arch_subdir_converted} ${timestamp})

tmpdir=`mktemp -d`
echo ">> tmpdir: $tmpdir"

os="linux"
cvmfs_repo="/cvmfs/pilot.nessi.uiocloud.no"

software_dir="${cvmfs_repo}/versions/${pilot_version}/software/${os}/${cpu_arch_subdir}"
if [ ! -d ${software_dir} ]; then
    echo "Software directory ${software_dir} does not exist?!" >&2
    exit 2
fi

overlay_upper_dir="${eessi_tmpdir}/overlay-upper"

software_dir_overlay="${overlay_upper_dir}/versions/${pilot_version}/software/${os}/${cpu_arch_subdir}"
if [ ! -d ${software_dir_overlay} ]; then
    echo "Software directory overlay ${software_dir_overlay} does not exist?!" >&2
    exit 3
fi

cd ${overlay_upper_dir}/versions/
echo ">> Collecting list of files/directories to include in tarball via ${PWD}..."

files_list=${tmpdir}/files.list.txt

if [ -d ${pilot_version}/software/${os}/${cpu_arch_subdir}/.lmod ]; then
    # include Lmod cache and configuration file (lmodrc.lua),
    # skip whiteout files and backup copies of Lmod cache (spiderT.old.*)
    find ${pilot_version}/software/${os}/${cpu_arch_subdir}/.lmod -type f | egrep -v '/\.wh\.|spiderT.old' > ${files_list}
fi
if [ -d ${pilot_version}/software/${os}/${cpu_arch_subdir}/modules ]; then
    # module files
    find ${pilot_version}/software/${os}/${cpu_arch_subdir}/modules -type f >> ${files_list}
    # module symlinks
    find ${pilot_version}/software/${os}/${cpu_arch_subdir}/modules -type l >> ${files_list}
fi
if [ -d ${pilot_version}/software/${os}/${cpu_arch_subdir}/software ]; then
    # installation directories
    ls -d ${pilot_version}/software/${os}/${cpu_arch_subdir}/software/*/* >> ${files_list}
fi

topdir=${cvmfs_repo}/versions/

echo ">> Creating tarball ${target_tgz} from ${topdir}..."
tar cfvz ${target_tgz} -C ${topdir} --files-from=${files_list}

echo ${target_tgz} created!

echo ">> Cleaning up tmpdir ${tmpdir}..."
rm -r ${tmpdir}
