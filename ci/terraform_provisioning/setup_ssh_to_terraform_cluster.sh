#!/bin/bash
set -exo pipefail

yum install -y openssh openssh-clients
yum install -y wget
yum install -y vim

tar -xvf cluster_env_files/*.targz -C cluster_env_files/ --strip 1

KNOWN_HOSTS_FILE_PATH=/root/.ssh/known_hosts

# VM root user doesn't get created with the .ssh directory
#  so create it for root to ssh to the dynamic cluster
mkdir -p /root/.ssh
touch $KNOWN_HOSTS_FILE_PATH

wait_for_ssh() {
    for node_hostname in "${@}" ; do
        echo "Waiting for ssh to be available on $node_hostname"
        timeout 60s bash -c "until ssh $node_hostname 'exit' 2>/dev/null && echo 'ssh ready' ; do echo -n '.' ; sleep 10 ; done"
        if [ "$?" -ne 0 ]; then
            echo "SSH connection to $node_hostname timed out"
            exit 1
        fi
    done
}

configure_local_ssh() {
    cp cluster_env_files/ssh_config /root/.ssh/config
    cp cluster_env_files/private_key.pem /root/.ssh/
    chmod 600 /root/.ssh/private_key.pem

    cat >> /etc/ssh/ssh_config <<EOF
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
EOF
}

copy_etc_hosts() {
    local node_hostname=$1
    scp cluster_env_files/etc_hostfile $node_hostname:/tmp/etc_hosts
    ssh -t $node_hostname "sudo bash -c 'cat /tmp/etc_hosts >> /etc/hosts'"
}

setup_known_hosts_file_with_keyscan() {
    # Terminoloy:
    #   gpdb_node_alias is a name like 'mdw', 'sdw1', etc
    #   node_hostname is a name like 'gpdb-cluster-node-0', etc
    while read node_ip gpdb_node_alias node_hostname ; do
        ssh-keyscan $node_ip >> $KNOWN_HOSTS_FILE_PATH
        ssh $node_hostname ssh-keyscan $gpdb_node_alias >> $KNOWN_HOSTS_FILE_PATH < /dev/null
        ssh $node_hostname ssh-keyscan '$(hostname)' >> $KNOWN_HOSTS_FILE_PATH < /dev/null
    done < cluster_env_files/etc_hostfile
}

create_gpadmin_user() {
    local node_hostname=$1

    scp $KNOWN_HOSTS_FILE_PATH $node_hostname:/tmp/known_hosts
    scp cluster_env_files/private_key.pem $node_hostname:/tmp/gpadmin_id_rsa
    ssh -t $node_hostname "sudo bash -c \"\
        useradd -m gpadmin; \
        mkdir ~gpadmin/.ssh; \
        cp /tmp/gpadmin_id_rsa ~gpadmin/.ssh/id_rsa; \
        cp /tmp/known_hosts ~gpadmin/.ssh/; \
        cp ~centos/.ssh/authorized_keys ~gpadmin/.ssh/; \
        chown -R gpadmin:gpadmin ~gpadmin/.ssh; \
        chmod 600 ~gpadmin/.ssh/id_rsa; \
    \""
}

configure_local_ssh
wait_for_ssh gpdb-cluster-node-0 gpdb-cluster-node-1

copy_etc_hosts gpdb-cluster-node-0
copy_etc_hosts gpdb-cluster-node-1

setup_known_hosts_file_with_keyscan

create_gpadmin_user gpdb-cluster-node-0
create_gpadmin_user gpdb-cluster-node-1

