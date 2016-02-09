#!/bin/sh

# Create the repo
aptly repo create -component=main zonza-zonza4

# Add package(s) to repo pool
aptly repo add zonza-zonza4 build/package-a_1.0.0_all.deb

# Publish repo pool as 'unstable'
aptly -architectures=all,amd64 publish repo -distribution=unstable zonza-zonza4 zonza-zonza4

# 'testing' distribution - publish an initial release candidate snapshot from everything in 'unstable'
aptly snapshot create snap-rc from repo zonza-zonza4
aptly -architectures=all,amd64 -distribution=testing publish snapshot snap-rc zonza-zonza4

# 'acceptance' distribution - publish an initial stable snapshot containing everything in the release candidate snapshot
aptly snapshot filter snap-rc snap-acceptance 'Name (% *)'
aptly -architectures=all,amd64 -distribution=acceptance publish snapshot snap-acceptance zonza-zonza4

# 'stable' distribution - publish an initial stable snapshot containing everything in the release candidate snapshot
aptly snapshot filter snap-rc snap-stable 'Name (% *)'
aptly -architectures=all,amd64 -distribution=stable publish snapshot snap-stable zonza-zonza4

aptly api serve -listen :8080 &
aptly serve -listen :8181 &

