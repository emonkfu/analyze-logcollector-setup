# analyze-logcollector-setup

This script will configure a new VM (RHEL or Fedora) to be used as a RHV LogCollector Analyzer VM.

It is suggested to run this on a system/VM that is dedicated to this purpose, or one that does not use postgresql DB, to make sure no data is lost for other purposes in the DB.

The script will
1) automatically add a repo to RHEL system, or use existing repos in Fedora
2) install any missing pacakges required for analyzer tool
3) clone the git repo for the analyzer tool
4) make sure postgres is initialized and running
5) if a logcollector is in /tmp on the system, run the analyzer tool against it
