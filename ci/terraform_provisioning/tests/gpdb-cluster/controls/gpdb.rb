# encoding: utf-8
# Pa-Toolsmiths

title 'Master and Segment host nodes'

control 'base_packages' do
  impact 1.0
  title 'Installed Base Packages'
  desc 'Installed the bare minimum of dependencies needed to run GreenplumDB.'

  describe package('perl') do
    it { should be_installed }
    its('version') { should eq '5.10.1-144.el6' }
  end

  describe package('gcc') do
    it { should be_installed }
    its('version') { should eq '4.4.7-18.el6' }
  end

end

control 'kernel_params' do

  impact 1.0
  title 'Set Kernel Parameters'
  desc 'Set the minimum required kernel paramaters for GreenplumDB'

  describe kernel_parameter('kernel.sem') do
    its('value') { should eq "250\t512000\t100\t2048" }
  end

  describe file('/etc/sysctl.conf') do
    its('content') { should match /kernel.sem = 250 512000 100 2048/ }
  end

end

control 'firewall_setting' do

  impact 1.0
  title 'Firewall Configurations'
  desc 'iptable should be turned off'

  describe service('iptables') do
    it { should_not be_enabled }
  end

  describe bash('chkconfig --list iptables') do
    its('stdout') { should_not match /on/ }
  end

end

control 'greenplum_db_installation' do

  impact 1.0
  title 'GreenplumDB installation'
  desc 'greenplum should be installed'

  describe bash('source /usr/local/greenplum-db-devel/greenplum_path.sh && which gpstart') do
    its('stdout') { should eq "/usr/local/greenplum-db-devel/bin/gpstart\n" }
  end

end




