Debian Packaging Tutorial
=========================

This very quick walk-through borrows from the "Hello World" build example published [here](https://wiki.debian.org/BuildingTutorial#Introduction).

We employ a Dockerfile based on `ubuntu:trusty`.  This is pre-installed with everything you need to; build the sample Debian package, create an [Aptly](http://www.aptly.info/) repo, deploy the package to the repo, and install it from the repo.

    # docker build -t deb-build . 
    # docker run -ti -p 8080:8080 deb-build bash

Adding the port mapping (`-p 8080:8080`) in the above command allows us to browse the aptly repo we will set up later.

##Building the Package

The first few steps take you through building a package from source.  First let's examine the sample source package in the directory `/root/src`.

    # cd /root/src     
    # tree hello-world_1.0.0/  
    
```
hello-world_1.0.0/
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

The stuff in the debian directory is all about building the package.  The `hello-world` shell script is what will actually be installed.
    
    # cd hello-world_1.0.0/
    # dpkg-buildpackage
    
The man page will tell you what `dpkg-buildpackage` does exactly but note that one of the steps is to call `debian/rules`.  The [rules](http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#rules) file is actually a Makefile.  The rules file uses the tool `dh` (part of the `debhelper` tool suite).


##Setting up your own Debian Repo

The next few steps serve as a quick primer on using Aptly and working with Debian package repositories.  

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
    Hello world!
    

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
    

