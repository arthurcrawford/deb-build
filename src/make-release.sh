#!/bin/bash

make-release ()
{
    export PACKAGE_NAME=$1
    export RELEASE_ID=$2

    # (re)create snapshot (snap-unstable) containing all packages from current unstable
    aptly snapshot drop -force snap-unstable &> /dev/null
    aptly snapshot create snap-unstable from repo a4pizza/legacy
   
    # (re)create filtered snapshot (snap-new) containing just the new release package(s) 
    aptly snapshot drop -force snap-new &> /dev/null
    aptly snapshot filter snap-unstable snap-new "Name ($PACKAGE_NAME)"
   
    # Create a release candidate snapshot (snap-rc) by merging (snap-new && snap-stable) 
    aptly snapshot merge snap-rc-$RELEASE_ID snap-new snap-stable
   
    # Re-publish testing 
    aptly -architectures=all,amd64 --skip-signing publish switch testing snap-rc-$RELEASE_ID

}

if [ "$#" -lt 2 ];then
    echo "Usage: make-release {package-name} {release_id}" 
else
    make-release $1 $2
fi
exit 0

