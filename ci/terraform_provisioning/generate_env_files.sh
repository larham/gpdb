#! /bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

yum install -y epel-release
yum install -y jq

CLUSTER_NAME=$(cat terraform/name)

ENV_FILES_DIR=${CLUSTER_NAME}_env_files

mkdir -p  $ENV_FILES_DIR

jq -r .cluster_private_key_pem terraform/metadata > ${ENV_FILES_DIR}/private_key.pem
chmod 600 ${ENV_FILES_DIR}/private_key.pem

jq -r .cluster_public_key_pem terraform/metadata > ${ENV_FILES_DIR}/public_key.pem
chmod 600 ${ENV_FILES_DIR}/public_key.pem

jq -r .cluster_public_key_openssh terraform/metadata > ${ENV_FILES_DIR}/public_key.openssh

jq -r .etc_host[] terraform/metadata > ${ENV_FILES_DIR}/etc_hostfile

jq -r .cluster_host_list[] terraform/metadata > ${ENV_FILES_DIR}/hostfile_all

jq -r .cluster_host_list[] terraform/metadata | grep -E -v [s]?mdw > ${ENV_FILES_DIR}/hostfile_init


echo "# gpadmin logins doesn't work until after we add ${ENV_FILES_DIR}/public_key.pem to known_hosts" > ${ENV_FILES_DIR}/ssh_config

IFS=$'\n';

for LINE in $(jq -r .etc_host[] terraform/metadata); do
 IP=$(echo ${LINE} | cut -d' ' -f1)
 HOSTNAME=$(echo ${LINE} | cut -d' ' -f2)
 NODENAME=$(echo ${LINE} | cut -d' ' -f3)

cat <<EOF >> ${ENV_FILES_DIR}/ssh_config
Host ${HOSTNAME}
  HostName ${IP}
  User gpadmin
  IdentityFile ~/.ssh/private_key.pem

Host ${NODENAME}
  HostName ${IP}
  User centos
  IdentityFile ~/.ssh/private_key.pem

EOF

done

# Reset IFS to our strict settings
IFS=$'\n\t'

cp -r terraform ${ENV_FILES_DIR}

mkdir -p cluster_env_files

tar -cvzf cluster_env_files/${ENV_FILES_DIR}.targz ${ENV_FILES_DIR}
