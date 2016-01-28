apt/common

apt/zonza

# Legacy structure
apt/zonza/legacy
apt/zonza/legacy/unstable
apt/zonza/legacy/testing
apt/zonza/legacy/stable


[Upstream]  (checks ==>) unstable (nightly ==>) testing (QA ==>) acceptance  (OAT/UAT  ==>) stable
                         ========               =======          ..........                 ======
                            |                      |                 |                        |
						  [ci]                   [int]              [pp]                     [p]
						  

# Cloud structure
apt/zonza/zonza4
apt/zonza/zonza4/dev
apt/zonza/zonza4/ci
apt/zonza/zonza4/test

apt/zonza/zonza5




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

# Using the APT repo

Now to act as a client of the APT repo we have created.  Before we can use the Aptly repo as an APT repository we need to host it.  You can do this with the Aptly embedded server.

### Serve repo

    # aptly serve &	

This will allow us to examine the published distributions at the following URL.

    $ curl http://localhost:8080/dists/    
    
<pre>
<a href="stable/">stable/</a>
<a href="testing/">testing/</a>
<a href="unstable/">unstable/</a>
</pre>
	
This reveals the expected three distributions; unstable, testing and stable.  Following the initial setup, all distributions serve out the exact same set of packages in the pool.  
    	 
### Configure APT client to point to the 'stable' distribution

If we want to build an environment based on the stable distribution we configure our host's APT config.

    # echo "deb http://localhost:8080/ stable main" >> /etc/apt/sources.list	 
	
### Update APT	

    # apt-get update
	
### Install packages

    # apt-get install package-a
	


		
	