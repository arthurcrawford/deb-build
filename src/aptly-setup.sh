#!/bin/sh

cd /root/src 
dpkg --build package-a build

# Create the repo
aptly repo create -component=main a4pizza/legacy
# Add package(s) to repo pool
aptly repo add a4pizza/legacy build/package-a_1.0.0_all.deb
# Publish repo pool as 'unstable'
aptly -architectures=all,amd64 publish repo --skip-signing=true -distribution=unstable a4pizza/legacy
# Create an initial release candidate snapshot from everything in 'unstable'
aptly snapshot create snap-rc from repo a4pizza/legacy
# Publish the release candidate as the 'testing' distribution
aptly -architectures=all,amd64 -distribution=testing --skip-signing publish snapshot snap-rc
# Initially create a stable snapshot that contains everything in the release candidate snapshot
aptly snapshot filter snap-rc snap-stable 'Name (% *)'
# Publish the stable snapshot as distribution 'stable' 
aptly -architectures=all,amd64 -distribution=stable --skip-signing publish snapshot snap-stable

