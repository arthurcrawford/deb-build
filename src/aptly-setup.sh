#!/bin/sh

#cd /root/src 
#dpkg --build package-a build

# Create the repo
aptly repo create -component=main a4pizza/legacy

# Add package(s) to repo pool
aptly repo add a4pizza/legacy build/package-a_1.0.0_all.deb

# Publish repo pool as 'unstable'
aptly -architectures=all,amd64 publish repo --skip-signing=true -distribution=unstable a4pizza/legacy

# 'testing' distribution - publish an initial release candidate snapshot from everything in 'unstable'
aptly snapshot create snap-rc from repo a4pizza/legacy
aptly -architectures=all,amd64 -distribution=testing --skip-signing publish snapshot snap-rc

# 'accpeptance' distribution - publish an initial stable snapshot containing everything in the release candidate snapshot
aptly snapshot filter snap-rc snap-acceptance 'Name (% *)'
aptly -architectures=all,amd64 -distribution=acceptance --skip-signing publish snapshot snap-acceptance

# 'stable' distribution - publish an initial stable snapshot containing everything in the release candidate snapshot
aptly snapshot filter snap-rc snap-stable 'Name (% *)'
aptly -architectures=all,amd64 -distribution=stable --skip-signing publish snapshot snap-stable

