# encoding: utf-8
# Pa-Toolsmiths

title 'Master node only'


control 'master-hostname' do

  impact 1.0
  title 'GPDB Master Hostname Convention'
  desc 'Hostname should match GreenplumDB conventions for Master node'

  describe sys_info do
    its('hostname') { should eq 'mdw' }
  end

  describe file('/etc/sysconfig/network') do
    its('content') { should match /HOSTNAME=mdw/ }
  end
end

control 'master-data-directories' do

  impact 1.0
  title 'Data Directories'
  desc 'Directories that exist for a default gpinitsystem'

  describe file('/data') do
   it { should be_directory }
   its('owner') { should eq 'gpadmin' }
   its('group') { should eq 'gpadmin' }
  end

  describe file('/data/master') do
   it { should be_directory }
   its('owner') { should eq 'gpadmin' }
   its('group') { should eq 'gpadmin' }
  end

end

control 'greenplum_db_initsystem' do

  impact 1.0
  title 'Greenplum DB ini:tialization'
  desc 'greenplum should be initialized with 1 master, 2 primaries and 2 mirrors'

  psql_get_segment_configuration = command("sudo su -c \
    \"source /usr/local/greenplum-db-devel/greenplum_path.sh && \
    psql template1 -c 'select status, port, hostname from gp_segment_configuration'
    \" gpadmin")

  describe psql_get_segment_configuration do
    its('stdout') { should match /u      |  5432 | mdw/ }
    its('stdout') { should match /u      | 40000 | sdw1/ }
    its('stdout') { should match /u      | 40001 | sdw1/ }
    its('stdout') { should match /u      | 50000 | sdw1/ }
    its('stdout') { should match /u      | 50001 | sdw1/ }
  end
end