#!/bin/bash

set -e


# Fix google cloud console


set +e
apt-get remove google-cloud-sdk
set -e

wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-206.0.0-linux-x86_64.tar.gz
tar xvzf google-cloud-sdk-206.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh -q
source ./google-cloud-sdk/path.bash.inc

# Set Vars
json_file_path="ert-concourse/json_templates/${pcf_iaas}/${terraform_template}"
json_file_template="${json_file_path}/ert-template.json"
json_file="json_file/ert.json"

cp ${json_file_template} ${json_file}

if [[ ! -f ${json_file} ]]; then
  echo "Error: cant find file=[${json_file}]"
  exit 1
fi


# Iaas Specific ERT  JSON Edits

if [[ -e ert-concourse/scripts/iaas-specific-config/${pcf_iaas}/run.sh ]]; then
  echo "Executing ${pcf_iaas} IaaS specific config ..."
  ./ert-concourse/scripts/iaas-specific-config/${pcf_iaas}/run.sh
fi
