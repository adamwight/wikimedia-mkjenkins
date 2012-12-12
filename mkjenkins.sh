#!/bin/bash
set -m
echo --- Initializing Jenkins install 
echo

cd $HOME 

if [ -e .jenkins ]
then
	echo Please remove ~/.jenkins or run java -jar jenkins.war instead
	exit
fi

echo
echo --- Cloning jenkins.git...
git clone https://gerrit.wikimedia.org/r/p/integration/jenkins.git .jenkins
cd .jenkins

echo
echo --- Downloading and starting Jenkins in the background.
(wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war -o jenkinswget.log --progress=dot:mega && java -jar jenkins.war > jenkins.log 2>&1) &

echo
echo --- Downloading Jenkins git plugin
mkdir plugins
wget http://updates.jenkins-ci.org/latest/git.hpi -o plugins/git.hpi

echo
echo --- Cloning and installing Jenkins job builder...
git clone https://gerrit.wikimedia.org/r/p/integration/jenkins-job-builder.git 
cd jenkins-job-builder
virtualenv .
source bin/activate
python setup.py develop

echo
echo --- Cloning and initializing JJB config
git clone https://gerrit.wikimedia.org/r/p/integration/jenkins-job-builder-config config

cat > jenkins_jobs.ini << EOF
[jenkins]
user=nobody
password=none
url=http://localhost:8080
EOF

echo
echo --- Patching Zuul paths
cd config
cat << EOF | patch -p1
diff --git a/defaults.yaml b/defaults.yaml
index c83e460..0bcdb8b 100644
--- a/defaults.yaml
+++ b/defaults.yaml
@@ -23,7 +23,7 @@

     scm:
      - git:
-        url: '/var/lib/zuul/git/{gerrit-name}'
+        url: 'https://gerrit.wikimedia.org/r/p/{gerrit-name}.git'
         branches:
          - '$ZUUL_BRANCH'
         refspec: '$ZUUL_REF'
@@ -47,7 +47,7 @@

     scm:
      - git:
-        url: '/var/lib/zuul/git/mediawiki/extensions/{ext-name}'
+        url: 'https://gerrit.wikimedia.org/r/p/mediawiki/extensions/{ext-name}.git'
         basedir: 'extensions/{ext-name}'
         branches:
          - '$ZUUL_BRANCH'
diff --git a/macro-scm.yaml b/macro-scm.yaml
index c7da6cd..aacb912 100644
--- a/macro-scm.yaml
+++ b/macro-scm.yaml
@@ -8,7 +8,7 @@
     name: git-mwcore-nosubmodules
     scm:
      - git:
-        url: '/var/lib/zuul/git/mediawiki/core'
+        url: 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git'
         branches:
          - '$ZUUL_BRANCH'
         refspec: '$ZUUL_REF'
EOF
cd ..

echo
echo --- Symlinking /var/lib/jenkins
cd ..
mkdir -p var/lib/jenkins
sudo ln -s $HOME/.jenkins /var/lib/jenkins
mkdir var/lib/jenkins/git

echo
echo --- Cloning mediawiki core
echo --- If there is a git checkout in $HOME/src/mediawiki-core,
echo --- that will be used as source.
echo ---
if [ -e $HOME/src/mediawiki-core ]
then
   echo --- Using $HOME/src/mediawiki-core
   echo --- Remember that you need to update the origin for Jenkins to
   echo --- update it\'s checkout!
   git clone --mirror -l -- $HOME/src/mediawiki-core /var/lib/jenkins/git/mw-core-bare
else
   git clone --mirror -- https://gerrit.wikimedia.org/r/p/mediawiki/core.git /var/lib/jenkins/git/mw-core-bare
fi


echo
echo --- Waiting for Jenkins wget...
cat jenkinswget.log
while [ ! -e jenkins.log ]; do tail -n 1 jenkinswget.log; echo; sleep 1; done

echo
echo -n Waiting for Jenkins to finish startup...
while [ `grep jenkins.log -e "INFO: Jenkins is fully up and running" | wc -l` == 0 ]; do echo -n .; sleep 1; done
echo OK

echo
echo --- Install Jenkins jobs
cd jenkins-job-builder
rm -f $HOME/.cache/jenkins_jobs/jenkins_jobs_cache.yml
jenkins-jobs --conf jenkins_jobs.ini update config/
cd ..

echo
echo --- Jenkins is now running
echo --- Visit http://localhost:8080 and enjoy!
echo --- Press ctrl-c twice to kill jenkins - you can re-start using
echo "--- cd $HOME/.jenkins && java -jar jenkins.war"
echo
echo --- tail -f jenkins.log

tail -f jenkins.log
fg
