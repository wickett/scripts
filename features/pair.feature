Feature: Pairing with others

  Scenario: Run pair.sh without any parameters
    When I run `../../pair.sh`
    Then the output should contain "Usage"

