#!/bin/bash
env | grep -i EASYBUILD_OPTARCH | sed -e 's/^/install_software_layer.sh:/'
export EESSI_PILOT_VERSION='2021.12'
./run_in_compat_layer_env.sh ./EESSI-pilot-install-software.sh
