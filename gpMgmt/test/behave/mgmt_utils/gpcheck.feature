@gpcheck
@dca
Feature: Test gpcheck
    Scenario: Run gpcheck --local as root without ssh permission
        Given user does not have ssh permissions
        When user runs "gpcheck --local" with sudo access
        Then gpcheck should return a return code of 0
        And gpcheck should print gpcheck completing to stdout
        And user has ssh permissions

    Scenario: Run gpcheck --local as non-root without ssh permission
        Given user does not have ssh permissions
        When the user runs "gpcheck --local"
        Then gpcheck should return a return code of 0
        And gpcheck should print gpcheck completing to stdout
        And user has ssh permissions

    Scenario: Run gpcheck --host as root with ssh permissions
        When user runs "gpcheck --host localhost" with sudo access
        Then gpcheck should return a return code of 0
        And gpcheck should print gpcheck completing to stdout

    Scenario: Run gpcheck --host as non root with ssh permissions
        Given we have exchanged keys with the cluster 
        When the user runs "gpcheck --host localhost" 
        Then gpcheck should return a return code of 0
        And gpcheck should print gpcheck completing to stdout

    Scenario: Negative tests cases command line options with --local
        When the user runs "gpcheck --local --host foo"
        Then gpcheck should return a return code of 0
        And gpcheck should print Only 1 of --file or --host or --local can be specified to stdout
        When the user runs "gpcheck --local --file foo"
        Then gpcheck should return a return code of 0
        And gpcheck should print Only 1 of --file or --host or --local can be specified to stdout
        When the user runs "gpcheck --file bar --host foo"
        Then gpcheck should return a return code of 0
        And gpcheck should print Only 1 of --file or --host or --local can be specified to stdout
         
