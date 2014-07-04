railsh
======

USAGE: `./railsh.sh myproject`

Bash script that makes a rails 3 project with:

- two models related through a join table
- use of rails generator
- standalone migration for a compound index
- necessary manual changes to the models and specs
- git branching
- rspec with simplecov.

Change the hardcoded GEMFILE_BAK to point to a nice rails 3 Gemfile.
For a couple commands you may have to sudo interactively.
Use chmod a+x railsh.sh to allow execution.

