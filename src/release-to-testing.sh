#!/bin/bash

release-to-testing ()
{
    # TODO
    # First add package to repo
    # re-publish

    # (re)create snapshot (snap-unstable) containing all packages from current unstable
    aptly snapshot drop -force snap-unstable &> /dev/null
    aptly snapshot create snap-unstable from repo a4pizza/legacy
   
    # (re)create filtered snapshot (snap-new) containing just the new release package(s) 
    aptly snapshot drop -force snap-new &> /dev/null
    aptly snapshot filter snap-unstable snap-new 'Name (package-a)'
   
    # Create a release candidate snapshot (snap-rc) by merging (snap-new && snap-stable) 
    aptly snapshot drop -force snap-rc &> /dev/null
    aptly snapshot merge snap-rc snap-new snap-stable
   
    # Re-publish testing 
    aptly -architectures=all,amd64 --skip-signing publish switch testing snap-rc

}

release-to-testing package-a
