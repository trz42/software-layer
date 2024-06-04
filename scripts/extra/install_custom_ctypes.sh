#!/usr/bin/env bash

# This script can be used to install custom ctypes under
# CVMFS_REPO/host_injections/VERSION/extra/OS_TYPE/SOFTWARE_SUBDIR/software/custom_ctypes
# and then set EESSI_USE_CUSTOM_CTYPES_DIR=CVMFS_REPO/host_injections/VERSION/extra/OS_TYPE/SOFTWARE_SUBDIR/custom_ctypes
# before loading a module that needs the custom ctypes implementation
# The custom ctypes is downloaded from https://github.com/NorESSI/custom_ctypes which is a fork of
# https://github.com/ComputeCanada/custom_ctypes

# The `host_injections` directory is a variant symlink that by default points to
# `/opt/eessi`, unless otherwise defined in the local CVMFS configuration (see
# https://cvmfs.readthedocs.io/en/stable/cpt-repo.html#variant-symlinks). For the
# installation to be successful, this directory needs to be writeable by the user
# executing this script.

# some logging
echo ">>> Running ${BASH_SOURCE}"

# Initialise our bash functions
TOPDIR=$(dirname $(realpath ${BASH_SOURCE}))
source "${TOPDIR}"/../utils.sh

# Function to display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help                           Display this help message"
    echo "  -t, --temp-dir /path/to/tmpdir   Specify a location to use for temporary"
    echo "                                   storage during the installation"
}

# Initialize variables
TEMP_DIR=

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        -t|--temp-dir)
            if [ -n "$2" ]; then
                TEMP_DIR="$2"
                shift 2
            else
                echo "Error: Argument required for $1"
                show_help
                exit 1
            fi
            ;;
        *)
            show_help
            fatal_error "Error: Unknown option: $1"
            ;;
    esac
done

# Make sure NESSI is initialised
check_eessi_initialised

# As an installation location just use $EESSI_SOFTWARE_PATH but replacing `versions` with `host_injections` and
# `software` with `extra`
# also append `/custom_ctypes`
NESSI_SITE_INSTALL=${EESSI_SOFTWARE_PATH/versions/host_injections}
NESSI_SITE_INSTALL=${NESSI_SITE_INSTALL/software/extra}/custom_ctypes

# we need a directory we can use for temporary storage
if [[ -z "${TEMP_DIR}" ]]; then
    tmpdir=$(mktemp -d)
else
    mkdir -p ${TEMP_DIR}
    tmpdir=$(mktemp -d --tmpdir=${TEMP_DIR} custom_ctypes.XXX)
    if [[ ! -d "$tmpdir" ]] ; then
        fatal_error "Could not create directory ${tmpdir}"
    fi
fi
echo "Created temporary directory '${tmpdir}'"

# some logging
echo ">>> Checking contents under '${NESSI_SITE_INSTALL}'"
tree -d ${NESSI_SITE_INSTALL}

# check if custom_ctypes has already been installed
if [[ -d ${NESSI_SITE_INSTALL}/lib ]]; then
    fatal_error "Error: Installation of custom_ctypes already found at '${NESSI_SITE_INSTALL}'"
fi

# download custom_ctypes to temp directory
wget https://github.com/NorESSI/custom_ctypes/archive/refs/heads/main.tar.gz -P ${tmpdir}

# make sure target directory exists
mkdir -p ${NESSI_SITE_INSTALL}

# unpack custom_ctypes to target directory
tar xvfz ${tmpdir}/main.tar.gz --strip-components=1 -C ${NESSI_SITE_INSTALL}

# clean up tmpdir
rm -rf "${tmpdir}"
