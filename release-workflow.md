# Cloud APT repo structure


The repo promotion scheme as it relates to the release management process.

```bash

[Upstream]  
    ↓
    
(checks) 
    ↓
    
 deploy   
    ↓


 unstable  →  testing   →  (acceptance)  →  stable      (APT repos)
 ========     =======       ..........      ======
    ↓            ↓             ↓              ↓
  [ci]         [int]          [pp]           [p]        (Environments)
```


The following definitions apply to the APT distributions named above.

* **unstable** - [Permanent] - constantly changing; moving head of release-ready changes.  Backed by continuous integration testing / nightly builds.
* **testing** - [Permanent] - changes periodically at every release/test cycle.  testing is the next release candidate.
* *(acceptance)* - [Flyweight] used only for validation of the release candidate in prod-like environment. Torn down after use.
* **stable** - [Permanent] - changes at every successful release.  Latest, stable code.

N.B. in the above scheme *acceptance* is a special case distribution as it relates to the release process.

The lifecycle of a package is defined by the following steps.

* **deploy** <package(s)>:
   package(s) now in the unstable pool available to be released   
* **make-release** <release_id> <package(s)>
   package(s) incorporated into release candidate (uniquely identified by release id) and made available for QA
* **release-to-acceptance** <release_id>
   release candidate made available for acceptance 
* **release-to-stable** <release_id>
   release candidate made available for production
   
**N.B.** in a ticket-driven the `release_id` would be the release ticket number.   


#Initial Repo Setup

Run a docker continer like this to create a 'repo' server.  

```bash
docker run -ti \
    --rm \
    -p 8080:8080  \
    -w /root/src \
    --name repo \
    deb-build \
    bash
```

Using the `--name` argument we will be able to create client hosts that can see this server.

For an initial repo setup you can either follow the steps below or run the script `aptly-setup.sh`. 
 
###Create the base repo 
 
 We create a single repo called a4pizza/legacy.
 
    # aptly repo create -component=main a4pizza/legacy

###Add packages

You might have to build them first.
   
    # aptly repo add a4pizza/legacy build/package-a_1.0.0_all.deb
	
###Publish the base repo 

We publish the repo under the distribution name 'unstable'.
 	 
	# aptly -architectures=all,amd64 publish repo --skip-signing=true -distribution=unstable a4pizza/legacy 
	 
### Create an initial 'testing' snapshot

Initially we will just create our 'testing' snapshot from the whole unstable distribution.  Later on we will tear down and re-create 'testing' snapshots with much more fidelity.

    # aptly snapshot create test-snap1 from repo a4pizza/legacy

### Publish this snapshot as the distribution 'testing'
	
	# aptly -architectures=all,amd64 -distribution=testing --skip-signing publish snapshot test-snap1

### Create 'stable' snapshot of 'testing'

    # aptly snapshot filter test-snap1 stable-snap1 'Name (% *)'

### Publish this snapshot as the distribution 'stable'

    # aptly -architectures=all,amd64 -distribution=stable --skip-signing publish snapshot stable-snap1

This all results in the following published repos:
	
```bash	
# aptly publish list
Published repositories:
  * ./stable [all, amd64] publishes {main: [stable-snap1]: Filtered 'test-snap1', query was: 'Name (% *)'}
  * ./testing [all, amd64] publishes {main: [test-snap1]: Snapshot from local repo [a4pizza/legacy]}
  * ./unstable [all, amd64] publishes {main: [a4pizza/legacy]}
```	

### Serve repo

Before anyone can use the Aptly repo as an APT repository we need to host it.  You can do this with the Aptly embedded server.

    # aptly serve &	

This will allow us to examine the published distributions at the following URL.

    $ curl http://localhost:8080/dists/    
    
<pre>
<a href="stable/">stable/</a>
<a href="testing/">testing/</a>
<a href="unstable/">unstable/</a>
</pre>
	
This reveals the expected three distributions; unstable, testing and stable.  Following the initial setup, all distributions serve out the exact same set of packages in the pool.  

#Using the APT repo

Now to act as a client of the APT repo we have created.  

###Create an integration environment

We can set up a linked Docker container to act as our integration environment.  

```bash
docker run -ti --rm \
    -w /root/src \
    --link repo:repo \
    --name int \
    deb-build bash
```

By using the `--link repo:repo` argument, Docker adds a link to the named `repo` container, adding it to the `/etc/hosts`, so that we can access the web port of `repo`.
    	 
    # curl http://repo:8080/dists/
    
<pre>
<a href="stable/">stable/</a>
<a href="testing/">testing/</a>
<a href="unstable/">unstable/</a>
</pre>
    	 
    	 
###Configure APT client to point to the 'unstable' distribution

If we want to build an environment based on the unstable distribution we configure our host's APT config.

    # echo "deb http://repo:8080/ unstable main" >> /etc/apt/sources.list	 
	
### Update APT	

    # apt-get update
	
### Install packages

    # apt-get install package-a
	
#Making A New Release	

We now go through a simple scenario of the release of a new version of a package.

###Deploy New Package Version
The fist step in our imagined lifecycle is to modify the package and deploy a new version to the `unstable` distribution.  

Now that it is available in our `unstable` distribution, it is available to our assumed continuous integration or nightly build processes.  Assuming such an integration / nightly build process is successful, we now want to make the new package available in the next logical environment we will cal this environment `QA/int` and it will be pointed at the `testing` distribution.  

So the next stage is to *release* our new package to testing.  The intention is that QA want to test an environment that is built from a repository that represents the current *production* environment plus the new package.  We need to test that combination to ensure that the release of the new package will not break production.  So we need to create a new testing snapshot which is composed of stable+new package.  We can use Aptly's snapshotting mechanism for this.




		
	