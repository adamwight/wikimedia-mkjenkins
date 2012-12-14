Introduction
------------
mkjenkins is a script to quickly get a Wikimedia Foundation Jenkins mirror
running. It downloads Jenkins, Jenkins job builder and relevant configuration,
builds JJB jobs and pushes them to Jenkins.

In addition, it prepares the directory structure for some assumptions the
current jobs make - such as /var/lib/jenkins being available and writable.
It is symlinked to $HOME/.jenkins/var/lib/jenkins, but this means you need
local root (or you can't make the symlink, and not all jobs will function).


How to run a test from a changeset in Gerrit
--------------------------------------------
Example: https://gerrit.wikimedia.org/r/#/c/38114/

1. go to http://localhost:8080/
2. go to job 'mwext-LabeledSectionTransclusion-extensiontests'
3. click 'Build now'
4. at ZUUL_BRANCH, enter the SHA1 hash ( 750fd5d72e4671bd9e2151300cefaf738b322990 )
5. at ZUUL_REF, enter the remote ref ( refs/changes/14/38114/1 )
6. click 'Build'

Alternatively:
```
curl -F json='{"parameter": [
{"name": "ZUUL_BRANCH", "value": "750fd5d72e4671bd9e2151300cefaf738b322990"},
{"name": "ZUUL_REF", "value": "refs/changes/14/38114/1"}]}' \
http://localhost:8080/job/mwext-LabeledSectionTransclusion-testextensions/build    
```
