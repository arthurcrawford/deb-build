#!/bin/sh

cd /root/src 
dpkg --build package-a build
aptly repo create -component=main a4pizza/legacy
aptly repo add a4pizza/legacy build/package-a_1.0.0_all.deb
aptly -architectures=all,amd64 publish repo --skip-signing=true -distribution=unstable a4pizza/legacy
aptly snapshot create test-snap1 from repo a4pizza/legacy
aptly -architectures=all,amd64 -distribution=testing --skip-signing publish snapshot test-snap1
aptly snapshot filter test-snap1 stable-snap1 'Name (% *)'
aptly -architectures=all,amd64 -distribution=stable --skip-signing publish snapshot stable-snap1
aptly publish list
aptly serve &

