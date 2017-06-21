# encoding: utf-8
# Pa-Toolsmiths

title 'Segment host node only'


control 'segment-hostname' do

  impact 1.0
  title 'GPDB Segment Hostname Convention'
  desc 'Hostname should match GreenplumDB conventions for Segment host node'

  describe sys_info do
    its('hostname') { should eq 'sdw1' }
  end

  describe file('/etc/sysconfig/network') do
    its('content') { should match /HOSTNAME=sdw1/ }
  end
end

control 'segment-data-directories' do

  impact 1.0
  title 'Data Directories'
  desc 'Directories that exist for a default gpinitsystem'

  describe file('/data') do
   it { should be_directory }
   its('owner') { should eq 'gpadmin' }
   its('group') { should eq 'gpadmin' }
  end

  describe file('/data/primary') do
   it { should be_directory }
   its('owner') { should eq 'gpadmin' }
   its('group') { should eq 'gpadmin' }
  end

  describe file('/data/mirror') do
   it { should be_directory }
   its('owner') { should eq 'gpadmin' }
   its('group') { should eq 'gpadmin' }
  end
end
