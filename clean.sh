#!/bin/bash
echo --- This script removes your local Jenkins install
echo --- For this, we remove $HOME/.jenkins and the /usr/lib/jenkins symlink.
echo $HOME/.jenkins | xargs -p rm -rf &&
echo /var/lib/jenkins | sudo xargs -p rm
