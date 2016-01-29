#!/bin/bash

deploy ()
{
    export package_file=$1
    echo "Name ($package_file)"

    # First add package to repo
    aptly repo add a4pizza/legacy $package_file

    if [ "$?" -eq 0 ];then
        # Re-publish 'unstable'
        aptly -architectures=amd64 publish update --skip-signing=true unstable
    else
        echo "Error deploying package $package_file"
    fi
}

if [ "$#" -eq 0 ];then
    echo "Usage: deploy {package-file}" 
else
    deploy $1
fi
exit 0
