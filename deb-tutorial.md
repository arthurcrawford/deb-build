Building a Debian Package
=========================

This walk-through uses a Dockerfile based on `ubuntu:trusty`.  This is installed with everything you need to build the debian package in the example.

    $ docker build -t deb-build . 
    $ docker run -ti deb-build bash

The following structure corresponds to the "Hello World" build example presented [here](https://wiki.debian.org/BuildingTutorial#Introduction).

First, this example takes you through the typical process of getting hold of the source package and unpacking the source.

    # wget http://wiki.opf-labs.org/download/attachments/12059958/hello.tar.gz
    
    # tar xvzf hello.tar.gz 
    
    # tree hello    
    
```
hello/
`-- hello-world_1.0.0
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

3 directories, 12 files
```
The top directory, by convention is the package name, in this case `hello`.

The stuff in the debian directory is all about building the package.  The `hello-world` shell script is what will actually be installed.
    
    # cd hello/hello-world_1.0.0/
    # dpkg-buildpackage
    
The man page will tell you what `dpkg-buildpackage` does exactly but note that one of the steps is to call `debian/rules`.  The [rules](http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#rules) file is actually a Makefile.  The rules file uses the tool `dh` (part of the `debhelper` tool suite).


Setting up a debian repo
=======================

This section serves as a quick primer on using Aptly and working with debian package repositories.  This Docker image 
is also installed with Aptly so you have everything necessary to create a local repo for general instruction and testing purposes.

We can run a conatiner with port mapping so that we will be able to access Aptly's repo server from outside the Docker container.

    $ docker run -ti -p 8080:8080 deb-build bash

Now we can use Aptly to create a repo.
    
    $ aptly repo create -distribution=test -component=main acme-test

You can now list the repo you created.
    
    $ aptly repo list
    
    List of local repos:
    * [acme-test] (packages: 0)

    To get more information about local repository, run `aptly repo show <name>`.

To see the configuration:
    
    $ cat  ~/.aptly.conf 
    
We have to publish the repo we created (by default aptly publishes to the local file system for testing purposes)
    
    $ aptly -architectures=amd64 publish repo --skip-signing=true acme-test
    
In the example we have used the option `--skip-signing=true` which we wouldn't normally want to do.  Also note that we need to specify the architecture; for example, we could determine our target architecture like this:

    $ dpkg --print-architecture
    amd64    

Aptly can now serve the locally published repo over it's embedded web server.
    
    $ aptly serve
    
The default port is `8080`.  Now you can test that Aptly's local embedded server is available from the Docker host:
    
    $ curl http://192.168.99.100:8080/    
    
    
    
