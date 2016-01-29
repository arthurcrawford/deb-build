#!/bin/bash

release-to-acceptance ()
{
    export RELEASE_ID=$1

    # Re-publish testing 
    aptly -architectures=all,amd64 --skip-signing publish switch acceptance snap-rc-$RELEASE_ID
}

if [ "$#" -lt 1 ];then
    echo "Usage: release-to-acceptance {release_id}" 
else
    release-to-acceptance $1 
fi
exit 0

