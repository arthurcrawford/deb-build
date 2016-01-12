Debian Packaging Tutorial
=========================

This very quick walk-through borrows from the "Hello World" build example published [here](https://wiki.debian.org/BuildingTutorial#Introduction).

We employ a Dockerfile based on `ubuntu:trusty`.  This is pre-installed with everything you need to; build the sample Debian package, create an [Aptly](http://www.aptly.info/) repo, deploy the package to the repo, and install it from the repo.

    # docker build -t deb-build . 
    # docker run -ti -p 8080:8080 deb-build bash

Adding the port mapping (`-p 8080:8080`) in the above command allows us to browse the aptly repo we will set up later.

##Building the Package

The first few steps take you through building a package from source.  First let's examine the sample source package in the directory `/root/src`.

    # cd /root/src/hello-world    
    # tree 
    
```
.
|-- debian
|   |-- README
|   |-- changelog
|   |-- compat
|   |-- control
|   |-- copyright
|   |-- dirs
|   |-- hello-world.manpages
|   |-- hello-world.pod
|   |-- install
|   |-- rules
|   `-- source
|       `-- format
`-- hello-world
```

The stuff in the debian directory is all about building the package.  The `hello-world` shell script is what will actually be installed.  In this directory we can now build the Debian package as follows:
    
    # dpkg-buildpackage
    
The man page will tell you what `dpkg-buildpackage` does exactly but note that one of the steps is to call `debian/rules`.  The [rules](http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#rules) file is actually a Makefile.  The rules file uses the tool `dh` (part of the `debhelper` tool suite).

The `.deb` file should now exist in the directory above the root of the source package.

```
# ls -1 ../hello-world_*
../hello-world_1.0.0.dsc
../hello-world_1.0.0.tar.gz
../hello-world_1.0.0_all.deb
../hello-world_1.0.0_amd64.changes
```

##Setting up your own Debian Repo

Now we have a package, we would like to deploy it to a repo and then install it from this repo.

The next few steps serve as a quick primer on using Aptly for this purpose.

First we use Aptly to create our repo.
    
    # aptly repo create -distribution=testing -component=main acme
    
We can now add the package we just built into the local repo.

    # aptly repo add acme /root/src/hello-world_1.0.0_all.deb        

We need tp publish the repo we created.

    # aptly -architectures=amd64 publish repo --skip-signing=true acme

We can now tell Aptly to act as a server for this repo; the default port is `8080`.
    
    # aptly serve &    

The new Aptly repo must be added to your list of sources so that `apt-get` will be able to search it for our new package.

    # echo "deb http://localhost:8080/ testing main" >> /etc/apt/sources.list  

We are now ready to update the apt-get index and then install the package from our aptly repo.

    # apt-get update && apt-get install hello-world    
    # hello-world 
    Hello there!
    
Releasing a New Version
======================
    
First let's make a change to the hello-world shell script; for example:

```bash
#!/bin/sh

echo "Hello there 2!"
```

    
Update the file `debian\changelog`.  There is a tool for doing this `dch`.  For example, to release a version 2.0.0:    

    # dch -v 2.0.0
    
Following the changelog update, we need to rebuild the package:

    # cd /root/src/hello-world    
    # dpkg-buildpackage
    
This will build the new version of the `.deb` package which we will now add to the repo as follows:

    # aptly repo add acme /root/src/hello-world_2.0.0_all.deb
    
Aptly now requires us to re-publish or update the repo.

    # aptly -architectures=amd64 publish update --skip-signing=true testing
    
We can now do an `apt-get update` and then check using `apt-get install -s` to just see whether it thinks there is actually a new version of `hello-world` to upgrade to.  The `-s` means that only a simulation is done; no action is taken but it prints out what would happen if you removed the `-s`:

```
# apt-get update && apt-get install -s hello-world
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be upgraded:
  hello-world
1 upgraded, 0 newly installed, 0 to remove and 5 not upgraded.
Inst hello-world [1.0.0] (2.0.0 . testing:testing [all])
Conf hello-world (2.0.0 . testing:testing [all])
```

We can see from this that there is a version 2.0.0 to upgrade to. Now we can do the version upgrade for real and watch what happens:

```
# apt-get install hello-world
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be upgraded:
  hello-world
1 upgraded, 0 newly installed, 0 to remove and 5 not upgraded.
Need to get 3844 B of archives.
After this operation, 0 B of additional disk space will be used.
WARNING: The following packages cannot be authenticated!
  hello-world
Install these packages without verification? [y/N] y
Get:1 http://localhost:8080/ testing/main hello-world all 2.0.0 [3844 B]
Fetched 3844 B in 0s (0 B/s)    
(Reading database ... 24813 files and directories currently installed.)
Preparing to unpack .../hello-world_2.0.0_all.deb ...
Unpacking hello-world (2.0.0) over (1.0.0) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Setting up hello-world (2.0.0) ...
```

Prove to ourselves that the upgrade happened:

    # hello-world 
    Hello there 2!

Oops!  We made a terrible mistake and want to *downgrade* back to version 1.0.0.  Well first we can validate what versions there are available using `apt-cache`:

```
# apt-cache showpkg hello-world
Package: hello-world
Versions: 
2.0.0 (/var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz) (/var/lib/dpkg/status)
 Description Language: 
                 File: /var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz
                  MD5: 9b7c7112ac3c351a6af7df35a47c3514

1.0.0 (/var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz)
 Description Language: 
                 File: /var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz
                  MD5: 9b7c7112ac3c351a6af7df35a47c3514


Reverse Depends: 
Dependencies: 
2.0.0 - 
1.0.0 - 
Provides: 
2.0.0 - 
1.0.0 - 
Reverse Provides: 
```    

We are now sure we want to revert back to version 1.0.0.  We do this using `apt-get install <pkg>=version` as follows:
     
    
```
# sudo apt-get install hello-world=1.0.0
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be DOWNGRADED:
  hello-world
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 5 not upgraded.
Need to get 3780 B of archives.
After this operation, 0 B of additional disk space will be used.
Do you want to continue? [Y/n] 
WARNING: The following packages cannot be authenticated!
  hello-world
Install these packages without verification? [y/N] y
Get:1 http://localhost:8080/ testing/main hello-world all 1.0.0 [3780 B]
Fetched 3780 B in 0s (0 B/s)    
dpkg: warning: downgrading hello-world from 2.0.0 to 1.0.0
(Reading database ... 24813 files and directories currently installed.)
Preparing to unpack .../hello-world_1.0.0_all.deb ...
Unpacking hello-world (1.0.0) over (2.0.0) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Setting up hello-world (1.0.0) ...
```

Finally, we validate that the down-grade worked as expected.

    # hello-world 
    Hello there!


    
Details of what we did
======================

Inspect the repo you created.

```    
# aptly repo list
List of local repos:
 * [acme] (packages: 1)

To get more information about local repository, run `aptly repo show <name>`.
```

See how aptly stores the local repo configuration:
    
    $ cat  ~/.aptly.conf 
    
When we published,  we used the option `--skip-signing=true` which we wouldn't normally want to do.  Also note that we need to specify the architecture; for example, we could determine our target architecture like this:

    # dpkg --print-architecture
    amd64        
    
By default aptly publishes to the local file system for testing purposes.
        
```
# tree ~/.aptly
/root/.aptly
|-- db
|   |-- 000002.ldb
|   |-- 000005.ldb
|   |-- 000010.ldb
|   |-- 000011.log
|   |-- CURRENT
|   |-- LOCK
|   |-- LOG
|   |-- LOG.old
|   `-- MANIFEST-000012
|-- pool
|   `-- be
|       `-- 7c
|           `-- hello-world_1.0.0_all.deb
`-- public
    |-- dists
    |   `-- test
    |       |-- Release
    |       `-- main
    |           `-- binary-amd64
    |               |-- Packages
    |               |-- Packages.bz2
    |               |-- Packages.gz
    |               `-- Release
    `-- pool
        `-- main
            `-- h
                `-- hello-world
                    `-- hello-world_1.0.0_all.deb
```
    
Test that Aptly's local embedded server is available from the Docker host:
    
    # curl http://localhost:8080/    
    <pre>
    <a href="pool/">pool/</a>
    <a href="dists/">dists/</a>
    </pre>    

For outside the Docker container, you may use the mapped port to access your repo server.

    # curl http://192.168.99.100:8080/
    
The IP address will depend on the IP of your Docker host.    
    

