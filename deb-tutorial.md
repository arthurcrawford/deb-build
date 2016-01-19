Debian Packaging Tutorial
=========================

This walk-through borrows from the "Hello World" build example published [here](https://wiki.debian.org/BuildingTutorial#Introduction).

The tutorial walks through the following concepts.

* Simple `.deb` build using `dpkg-deb`
* More complex `.deb` build using `dpkg-buldpackage`
* Hosting Debian packages with Aptly
* Upgrading `.deb` versions
* Promoting packages between distributions using Aptly snapshots

To save you effort, I have supplied a Dockerfile based on `ubuntu:trusty`.  If you have the Docker tools installed - this is the easiest way to go.  The supplied Dockerfile creates an image pre-installed with all the required tools.  Build the Docker image as follows:

    # docker build -t deb-build . 
    
To run a container from the image
    
    # docker run -ti \
        -p 8080:8080 \
        deb-build \
        bash

Adding the port mapping (`-p 8080:8080`) in the above command is optional - it allows us to browse the aptly repo we will set up later.  

##Building the Debian Package

These first first steps take you through building a package from source.  There are two methods explained here; the first one `package-a` using the low-level `dpkg-deb` tool, the second, `package-b` using the more involved Makefile-like approach using the tool `dpkg-buildpackage`.

###package-a: Simple build using `dpkg-deb`

This first packaging example is about as simple as it gets.  The source for `package-a` just includes a simple executable shell script.  The only other thing needed is the `debian/control` file.  

```bash
# cd /root/src/
# tree package-a
package-a
|-- debian
|   `-- control
`-- usr
    `-- bin
        `-- package-a
```
Notice that the executable shell script is in the relative location `package-a/usr/bin/`; this maps to its eventual target location. 

The package archive is created using the low level Debian packagin tool `dpkg-deb`.

```        
# dpkg-deb --build package-a/ build/
dpkg-deb: building package `package-a' in `build//package-a_1.0.0_all.deb'.
```
The first argument is the package we're creating the archive for.  The second argument is the target directory where the `.deb` file will be created.

###package-b: More complex build using `dpkg-buildpackage`

This second example allows for more bells and whistles in the build process but also involves a slightly different file structure and more files.

    # cd /root/src    
    # tree /package-b 
    
```
package-b
|-- debian
|   |-- README
|   |-- changelog
|   |-- compat
|   |-- control
|   |-- copyright
|   |-- dirs
|   |-- files
|   |-- install
|   |-- package-b.manpages
|   |-- package-b.pod
|   |-- rules
|   `-- source
|       `-- format
`-- package-b
```

The stuff in the debian directory is all about building the package.  The `package-b` shell script is what will actually be installed.  In this directory we can now build the Debian package as follows:
    
    # cd /root/src/package-b
    # dpkg-buildpackage
    
The man page will tell you what `dpkg-buildpackage` does exactly but note that one of the steps is to call `debian/rules`.  The [rules](http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#rules) file is actually a Makefile.  The rules file uses the tool `dh` (part of the `debhelper` tool suite).

The `.deb` file should now exist in the directory above the root of the source package.

```
# ls -1 ../package-a_*
../package-a_1.0.0.dsc
../package-a_1.0.0.tar.gz
../package-a_1.0.0_all.deb
../package-a_1.0.0_amd64.changes
```

##Setting up your own Debian Repo

Now we have a package, we would like to deploy it to a repo and then install it from this repo.

The next few steps serve as a quick primer on using Aptly for this purpose.

First we use Aptly to create our repo.  We can validate its existence with `aptly repo list`.
    
```    
# aptly repo create -distribution=testing -component=main a4pizza-testing
# aptly repo list
List of local repos:
 * [a4pizza-testing] (packages: 0)

To get more information about local repository, run `aptly repo show <name>`.
```
    
Note that the *repo*, itself is called "a4pizza-testing".  The *distribution*, importantly, is called "testing".  There may be other distributions such as "unstable" and "stable" - these would set up in the same way with another Aptly repo (note that in APT terms, however, several distributions such as "testing", "unstable" and "stable" would be considered distributions under the *same APT* repo).  

Finally, just note that under the "testing" distribution there is just the single component called "main".  APT uses the term component to mean a subdivisin of a distribution, such as "contrib" or "non-free".
    
We can now add the package we just built into the Aptly repo.

    # aptly repo add a4pizza-testing /root/src/package-a_1.0.0_all.deb        

And then we need to publish the repo we created.

    # aptly -architectures=all,amd64 publish repo --skip-signing=true a4pizza-testing

We can now tell Aptly to act as a server for this published repo; the default port is `8080`.
    
    # aptly serve &    

The new Aptly repo must be added to your list of sources so that `apt` will be able to search it for our new package.

    # echo "deb http://localhost:8080/ testing main" >> /etc/apt/sources.list
    
Importantly, note that we're using the distribution name "testing" here.       

We are now ready to update the `apt` index and then install the package using `apt`.

    # apt-get update && apt-get install package-a    
    # package-a 
    Hello from package-a!
    
###Removing the package from the repo

First make sure package is uninstalled

    # apt remove package-a
    
Then remove from the Aptly repo and re-publish.

    # aptly repo remove a4pizza-testing package-a    
    # aptly -architectures=all,amd64 publish update --skip-signing testing
    
Then we update the `apt` cache.
    
    # apt-get update 

We should now find that the package is gone from the repo.

    # apt-get install package-a
    Reading package lists... Done
    Building dependency tree       
    Reading state information... Done
    E: Unable to locate package package-a
    
    
Releasing a New Version
======================
    
First let's make a change to the `package-a` shell script; for example:

###package-a: Using `dpkg-deb`

```bash
#!/bin/sh
echo "Hello from package-a v2!"
```
Now edit the `debian/control` file directly and change the Version field.

```
    Version: 2.0.0
```

Re-build using `dpkg-deb`.

    # cd /root/src/
    # dpkg-deb --build package-a/ build/
    
###package-b: Using `dpkg-buildpackage`

```bash
#!/bin/sh
echo "Hello from package-b v2!"
```
    
Update the file `debian\changelog`.  There is a tool for doing this `dch`.  For example, to release a version 2.0.0:    

    # dch -v 2.0.0
    
Following the changelog update, we need to rebuild the package:

    # cd /root/src/package-a    
    # dpkg-buildpackage
    
###Adding the new `.deb` to the repo
    
Regardless of the method used we will now have the new version of the `.deb` package which we can add to the Aptly repo as follows:

    # aptly repo add a4pizza-testing package-a_2.0.0_all.deb
    
Aptly now requires us to re-publish or update the repo.

    # aptly -architectures=amd64 publish update --skip-signing=true testing
    
We can now do an `apt-get update` and then check using `apt-get install -s` to just see whether it thinks there is actually a new version of `package-a` to upgrade to.  The `-s` means that only a simulation is done; no action is taken but it prints out what would happen if you removed the `-s`:

```
# apt-get update && apt-get install -s package-a
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be upgraded:
  package-a
1 upgraded, 0 newly installed, 0 to remove and 10 not upgraded.
Inst package-a [1.0.0] (2.0.0 . testing:testing [all])
Conf package-a (2.0.0 . testing:testing [all])
```

We can see from this that there is a version 2.0.0 to upgrade to. Now we can do the version upgrade for real and watch what happens:

```
# apt-get install package-a
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be upgraded:
  package-a
1 upgraded, 0 newly installed, 0 to remove and 10 not upgraded.
Need to get 4048 B of archives.
After this operation, 0 B of additional disk space will be used.
WARNING: The following packages cannot be authenticated!
  package-a
Install these packages without verification? [y/N] y
Get:1 http://localhost:8080/ testing/main package-a all 2.0.0 [4048 B]
Fetched 4048 B in 0s (0 B/s)  
(Reading database ... 24813 files and directories currently installed.)
Preparing to unpack .../package-a_2.0.0_all.deb ...
Unpacking package-a (2.0.0) over (1.0.0) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Setting up package-a (2.0.0) ...
```

Prove to ourselves that the upgrade happened:

    # package-a
    Hello from package-a v2!

Oops!  We made a terrible mistake and want to *downgrade* back to version 1.0.0.  Well first we can validate what versions there are available using `apt-cache`:

```
# apt-cache showpkg package-a
Package: package-a
Versions: 
2.0.0 (/var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz) (/var/lib/dpkg/status)
 Description Language: 
                 File: /var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz
                  MD5: 122e12a8e05a99aa38e324a49f6fd934

1.0.0 (/var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz)
 Description Language: 
                 File: /var/lib/apt/lists/localhost:8080_dists_testing_main_binary-amd64_Packages.gz
                  MD5: 122e12a8e05a99aa38e324a49f6fd934


Reverse Depends: 
  package-b,package-a 1.0.0
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
# sudo apt-get install package-a=1.0.0
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages will be DOWNGRADED:
  package-a
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 10 not upgraded.
Need to get 3952 B of archives.
After this operation, 0 B of additional disk space will be used.
Do you want to continue? [Y/n] 
WARNING: The following packages cannot be authenticated!
  package-a
Install these packages without verification? [y/N] y
Get:1 http://localhost:8080/ testing/main package-a all 1.0.0 [3952 B]
Fetched 3952 B in 0s (0 B/s)  
dpkg: warning: downgrading package-a from 2.0.0 to 1.0.0
(Reading database ... 24813 files and directories currently installed.)
Preparing to unpack .../package-a_1.0.0_all.deb ...
Unpacking package-a (1.0.0) over (2.0.0) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Setting up package-a (1.0.0) ...
```

Finally, we validate that the down-grade worked as expected.

    # package-a 
    Hello from package-a!

#A Simple Release Lifecycle

This section outlines how the tools used above may also be used to implement a simple build/release lifecycle whereby changes merged into an integration repository are promoted to a release when they have been tested.

```
# aptly snapshot create rel1 from repo a4pizza-testing

Snapshot rel1 successfully created.
You can run 'aptly publish snapshot rel1' to publish snapshot as Debian repository.
``` 

The snapshot we created is called `rel1`.  It is an immutable copy of the distribution we took the snapshot from.  We nee to publish the snapshot in order for anything to see it.  We do this as follows.

```
# aptly -architectures=all,amd64 -distribution=stable --skip-signing publish snapshot rel1               
Loading packages...
Generating metadata files and linking package files...
Finalizing metadata files...

Snapshot rel1 has been successfully published.
Please setup your webserver to serve directory '/root/.aptly/public' with autoindexing.
Now you can add following line to apt sources:
  deb http://your-server/ stable main
Don't forget to add your GPG key to apt with apt-key.

You can also use `aptly serve` to publish your repositories over HTTP quickly.
```

If you serve out the Aptly repo now, you will see that there are two distributions; "testing" and "stable".  Note that "stable" will not receive any uploaded updates; it is serving out the immutable snapshot we took of "testing".

```
# aptly publish list
Published repositories:
  * ./stable [all, amd64] publishes {main: [rel1]: Snapshot from local repo [a4pizza-testing]}
  * ./testing [all, amd64] publishes {main: [a4pizza-testing]}
```

Now imagine we want to repeat this process.  We have perhaps releaseed some more packages to the "testing" distribution and wish to promote once more to stable.  Using Aptly we perform the following tasks.

* New packages already deployed to "testing"
* Create new snapshot ("rel2")
* Switch pulication of "stable" to the new snapshot.

So first we create a new snapshot for "rel2".

```
# aptly snapshot create rel2 from repo a4pizza-testing

Snapshot rel2 successfully created.
You can run 'aptly publish snapshot rel2' to publish snapshot as Debian repository.

# aptly snapshot list
List of snapshots:
 * [rel1]: Snapshot from local repo [a4pizza-testing]
 * [rel2]: Snapshot from local repo [a4pizza-testing]

To get more information about snapshot, run `aptly snapshot show <name>`.
```

Now, we want to publish "rel2" as the distribution "stable".  Any environment pointing at the "stable" distribution will then get our updates.  To do this you must use the Aptly command `aptly publish switch`.  We didn't need to do this the first time around because initially there was nothing publishing the "stable" release.  

```
# aptly -architectures=all,amd64 --skip-signing publish switch stable rel2     
Loading packages...
Generating metadata files and linking package files...
Finalizing metadata files...
Cleaning up prefix "." components main...

Publish for snapshot ./stable [all, amd64] publishes {main: [rel2]: Snapshot from local repo [a4pizza-testing]} has been successfully switched to new snapshot.
```
As you can see from the output of this command, the publication of the "stable" release has now been *switched* over from the "rel1" snapshot to the "rel2" snapshot.

Any environment that is configured with the "stable" distribution will now receive the updates when it does an `apt-get update && apt-get install`.

One benefit of doing things this way is that there has been no need to copy any files.


Details 
========

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
    

