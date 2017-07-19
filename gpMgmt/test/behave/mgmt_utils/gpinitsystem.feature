@gpinitsystem
Feature: gpinitsystem tests
    Scenario: gpinitsystem creates a cluster with default data_checksums on
        Given the database is running
        When the user runs "gpconfig -s data_checksums"
        Then gpconfig should return a return code of 0
        Then gpconfig should print "Values on all segments are consistent" to stdout
        Then gpconfig should print "Master  value: on" to stdout
        Then gpconfig should print "Segment value: on" to stdout


#    Scenario: gpinitsystem creates a cluster with data_checksums off
#        # shutdown, rebuild with other setting
#        When the user runs command "gpstop -a"
#        Then gpstop should return a return code of 0
#
#        # todo change clusterConfigFile to turn off checksums
#        # run gpinitsystem with data_checksums off
##        When the user runs command "cd $MASTER_DATA_DIRECTORY/../../.. && /usr/local/gpdb/bin/gpinitsystem -a -c clusterConfigFile -l /Users/pivotal/workspace/gpdb/gpAux/gpdemo/datadirs/gpAdminLogs"
#
#        Given the database is running
#        When the user runs "gpconfig -s data_checksums"
#        Then gpconfig should return a return code of 0
#        Then gpconfig should print "Values on all segments are consistent" to stdout
#        Then gpconfig should print "Master  value: on" to stdout
#        Then gpconfig should print "Segment value: on" to stdout


