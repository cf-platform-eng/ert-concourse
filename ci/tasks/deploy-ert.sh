#!/bin/bash
set -e

# Setup OM Tool
sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

# Apply Changes in Opsman
echo "=============================================================================================="
echo "Applying OpsMan Changes to Deploy: ${guid_cf}"
echo "=============================================================================================="

set -e
echo "=============================================================================================="
echo " Applying OpsMan Changes to Deploy: ${guid_cf}"
echo "=============================================================================================="
tries=1
until [ $tries -ge 4 ]
do
  om_status=0
  echo "=============================================================================================="
  echo "Attempt Number ${tries}: Apply-Changes ..."
  echo "=============================================================================================="
  om-linux --target https://opsman.$pcf_ert_domain -k \
       --request-timeout 3600 \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
  apply-changes && break
  om_status=$?
  tries=$[$tries+1]
  sleep 60
done
exit $om_status