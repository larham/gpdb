import os
import socket
import tempfile
from StringIO import StringIO

from mock import *

from gp_unittest import *
from gppylib.commands.base import Command

from shutil import copyfile, copy


class GpInitSystem(GpTestCase):
    """
    Using the python test system to test a bash script.
    We fool the subject, gpinitsystem, to have mock dependencies by copying that file into a test directory
    and providing a mock for one of its sourced files.
    """

    def setUp(self):
        self.temp_bin_dir = tempfile.mkdtemp()
        self.subject = os.path.join(self.temp_bin_dir, "gpinitsystem")
        self.temp_lib_dir = os.path.join(self.temp_bin_dir, "lib")
        os.mkdir(self.temp_lib_dir)

        self.gp_bash_version = os.path.join(self.temp_lib_dir, 'gp_bash_version.sh')
        self.mock_initdb = os.path.join(self.temp_bin_dir, 'mock_initdb')
        self.mock_cluster_config = os.path.join(self.temp_bin_dir, 'mock_cluster_config')
        self.mock_hostfile = os.path.join(self.temp_bin_dir, 'mock_hostfile')
        self.mock_qdir = os.path.join(self.temp_bin_dir, 'qdir')
        os.mkdir(self.mock_qdir)
        this_dir = os.path.dirname(__file__)
        bin_dir = os.path.join(this_dir, "../../..")
        copyfile(os.path.join(bin_dir, "gpinitsystem"), self.subject)
        os.chmod(self.subject, 0755)
        copy(os.path.join(bin_dir, "lib/", "gp_bash_functions.sh"), self.temp_lib_dir)
        copy(os.path.join(bin_dir, "lib/", "gp_bash_version.sh.in"), self.temp_lib_dir)
        copy(os.path.join(bin_dir, "lib/", "gpcreateseg.sh"), self.temp_lib_dir)
        copy(os.path.join(bin_dir, "lib/", "gphostcachelookup.py"), self.temp_lib_dir)

    def tearDown(self):
        # todo remove after test development finished
        # shutil.rmtree(self.temp_dir)
        pass

    #@patch('sys.stdout', new_callable=StringIO)
    def test_gpinitsystem_initdb_args(self): #mock_stdout):
        # Edit gp_bash_version.sh to set INITDB to mock_initdb
        # The mock_initdb should print all the args passed to it
        # The mock_initdb should return an error so that gpinitsystem does not continue after calling mock_initdb
        # Compare the output of the mock_initdb that it is consistent with the input for the checksum setting passed
        # to the gpinitsystem.

        with open(self.gp_bash_version, 'w') as mock_gp_bash_version_file:
            mock_gp_bash_version_file.write('INITDB=%s\n' % self.mock_initdb)
        with open(self.gp_bash_version, 'a') as mock_gp_bash_version_file:
            with open(self.gp_bash_version+'.in', 'r') as original_gp_bash_version_file:
                mock_gp_bash_version_file.write(original_gp_bash_version_file.read())

        with open(self.mock_initdb, 'w') as f:
            f.write("""
#!/bin/bash
echo $@
exit 1
            """)
        os.chmod(self.mock_initdb, 0755)

        # create hostfile
        with open(self.mock_hostfile, 'w') as f:
            f.write(socket.gethostname())

        # create cluster config
        with open(self.mock_cluster_config, 'w') as cluster_config:
            cluster_config.write("""
# Set this to anything you like
ARRAY_NAME="Demo hostname Cluster"
CLUSTER_NAME="Demo hostname Cluster"

# This file must exist in the same directory that you execute gpinitsystem in
MACHINE_LIST_FILE=%s

# This names the data directories for the Segment Instances and the Entry Postmaster
SEG_PREFIX=seg-prefix

# This is the port at which to contact the resulting Greenplum database, e.g.
#   psql -p 15432 -d template1
PORT_BASE=15432

# Prefix for script created database
DATABASE_PREFIX=demoDatabase

# Array of data locations for each hosts Segment Instances, the number of directories in this array will
# set the number of segment instances per host
declare -a DATA_DIRECTORY=(/tmp/data1 /tmp/data2)

# Name of host on which to setup the QD
MASTER_HOSTNAME=%s

# Name of directory on that host in which to setup the QD
MASTER_DIRECTORY=%s

MASTER_PORT=5432

# Hosts to allow to connect to the QD (and Segment Instances)
# By default, allow everyone to connect (0.0.0.0/0)
IP_ALLOW=0.0.0.0/0

# Shell to use to execute commands on all hosts
TRUSTED_SHELL="ssh"

CHECK_POINT_SEGMENTS=8

ENCODING=UNICODE            
        """ % (self.mock_hostfile, socket.gethostname(), self.mock_qdir))

        cmd_str = "%s -c %s" % (self.subject, self.mock_cluster_config)
        cmd = Command('run gpinitsystem', cmd_str)
        cmd.run()
        res = cmd.get_results()
        print "mock initdb path %s" % self.mock_initdb
        print res
        print "command string: %s" % cmd.cmdStr

        # validate behavior
        self.assertIn("something happened",
                      "fail")


if __name__ == '__main__':
    run_tests()
