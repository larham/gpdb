#!/bin/bash
set -exo pipefail

echo "-------------- Testing cluster -----------"

./gpdb_src/ci/terraform_provisioning/setup_ssh_to_terraform_cluster.sh

# Install inspec
curl https://omnitruck.chef.io/install.sh | bash -s -- -P inspec

inspec exec ./gpdb_src/ci/terraform_provisioning/tests/gpdb-cluster/ \
  --host=gpdb-cluster-node-0 \
  --backend=ssh \
  --key-files ./cluster_env_files/private_key.pem \
  --user=centos


inspec exec ./gpdb_src/ci/terraform_provisioning/tests/gpdb-cluster/ \
  --host=gpdb-cluster-node-1 \
  --backend=ssh \
  --key-files ./cluster_env_files/private_key.pem \
  --user=centos


inspec exec ./gpdb_src/ci/terraform_provisioning/tests/mdw/ \
  --host=gpdb-cluster-node-0 \
  --backend=ssh \
  --key-files ./cluster_env_files/private_key.pem \
  --user=centos

inspec exec ./gpdb_src/ci/terraform_provisioning/tests/sdw1/ \
  --host=gpdb-cluster-node-1 \
  --backend=ssh \
  --key-files ./cluster_env_files/private_key.pem \
  --user=centos