#!/bin/bash
# The below line is commented because we are currently ignoring gpinitsystem warnings
# set -euo pipefail
# IFS=$'\n\t'


./gpdb_src/ci/terraform_provisioning/setup_ssh_to_terraform_cluster.sh

install_required_packages() {
    local node_hostname=$1

    ssh -t $node_hostname "sudo bash -c \"\
        yum install -y perl gcc
    \""
}

set_kernel_sem() {
    local node_hostname=$1
    ssh -t $node_hostname "sudo bash -c \"\
        echo "kernel.sem =  250 512000 100 2048" >> /etc/sysctl.conf ; \
        /sbin/sysctl -p; \
    \""
}

setup_master() {
    local node_hostname=$1
    ssh -t $node_hostname "sudo bash -c \"\
        mkdir -p /data/master; \
        chown -R gpadmin:gpadmin /data; \
        sed -i -e 's/\(HOSTNAME=\).*$/\1mdw/' /etc/sysconfig/network; \
        /etc/init.d/network restart ;\
        hostname mdw; \
        hostname ; \
    \""
}

setup_sdw1() {
    local node_hostname=$1
    ssh -t $node_hostname "sudo bash -c \"\
        mkdir -p /data/primary; \
        mkdir -p /data/mirror; \
        chown -R gpadmin:gpadmin /data; \
        sed -i -e 's/\(HOSTNAME=\).*$/\1sdw1/' /etc/sysconfig/network; \
        /etc/init.d/network restart ;\
        hostname sdw1; \
        hostname ; \
    \""
}

extract_gpdb_tarball() {
    local node_hostname=$1

    # Commonly the incoming binary will be called bin_gpdb.tar.gz. Because many other teams/pipelines tend to use
    # that naming convention we are not, deliberately. Once the file crosses into our domain, we will not use
    # the conventional name.  This should make clear that we will install any valid binary, not just those that follow
    # the naming convention.
#    scp gpdb_binary/*.tar.gz $node_hostname:/tmp/gpdb_binary.tar.gz

#    todo LAH: integrating into main source, I'm reverting to bin_gpdb
    scp bin_gpdb/*.tar.gz $node_hostname:/tmp/gpdb_binary.tar.gz
    ssh -t $node_hostname "sudo bash -c \"\
      mkdir -p /usr/local/greenplum-db-devel; \
    tar -xf /tmp/gpdb_binary.tar.gz -C /usr/local/greenplum-db-devel; \
    chown -R gpadmin:gpadmin /usr/local/greenplum-db-devel; \
    \""
}

start_gpdb() {
    local gpdb_master_alias=$1
    scp cluster_env_files/hostfile_init $gpdb_master_alias:~gpadmin/segment_host_list
    scp gpdb_src/terraform_provisioning/gpinitsystem_config $gpdb_master_alias:~gpadmin/gpinitsystem_config
    # TODO: Decide to catch the warning in gpinitsysem and then be strict (set -eou ...) at the top of this script
    ssh $gpdb_master_alias "bash -c \"\
      source /usr/local/greenplum-db-devel/greenplum_path.sh; \
        gpinitsystem -a -c ~gpadmin/gpinitsystem_config -h ~gpadmin/segment_host_list; \
    \""
}

verify_greenplum() {
    local gpdb_master_alias=$1
    # Perform query within transaction to verify all nodes are alive
    ssh $gpdb_master_alias "source /usr/local/greenplum-db-devel/greenplum_path.sh; timeout 10s psql -d template1 -c 'begin ; select 1; end;'"
}

disable_firewall() {
    local node_hostname=$1
    ssh -t $node_hostname "sudo bash -c \"\
        service iptables stop; \
        /sbin/chkconfig iptables off; \
    \""
}

copy_gpdb_src() {
    local gpdb_master_alias=$1
    # Requires the git Concourse resource to make the source available
    scp -r gpdb_src $gpdb_master_alias:/home/gpadmin/
}

install_required_packages gpdb-cluster-node-0
install_required_packages gpdb-cluster-node-1

set_kernel_sem gpdb-cluster-node-0
set_kernel_sem gpdb-cluster-node-1

disable_firewall gpdb-cluster-node-0
disable_firewall gpdb-cluster-node-1

setup_master gpdb-cluster-node-0
setup_sdw1 gpdb-cluster-node-1

extract_gpdb_tarball gpdb-cluster-node-0
extract_gpdb_tarball gpdb-cluster-node-1

copy_gpdb_src mdw

start_gpdb mdw
verify_greenplum mdw

