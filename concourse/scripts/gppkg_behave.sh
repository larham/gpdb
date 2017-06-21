#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'
# In the future, this script will be provided by the team that owns the test, and they will decide if they should enforce bash strict mode

set -x

./gpdb_src/ci/terraform_provisioning/setup_ssh_to_terraform_cluster.sh

run_behave_gppkg() {
    local gpdb_master_alias=$1
    # Requires the git Concourse resource to make the source available

    ssh $gpdb_master_alias "bash -c \"\
        source /usr/local/greenplum-db-devel/greenplum_path.sh; \
        export PGDATABASE=gptest; \

        createdb ${PGDATABASE}; \
        cd /home/gpadmin/gpdb_src/gpMgmt; \
        export PGPORT=5432; \
        export MASTER_DATA_DIRECTORY=/data/master/gpseg-1; \
        make -f Makefile.behave behave tags=gppkg; \
    \""
}

run_behave_gppkg mdw

