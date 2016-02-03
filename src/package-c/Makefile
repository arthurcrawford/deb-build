all: package 

# Move files into build area
prepare:
	mkdir -p build/package-c/opt/package-c
	cp -R DEBIAN build/package-c
	cp -R usr build/package-c

# Create a python virtual env 
venv: prepare
	cd build/package-c/opt/package-c; \
	virtualenv env

# Install python dependencies from PyPi using pip
deps: venv
	./make-deps.sh

# "build" our software into the virtual env (i.e. copy python script into place)
build: deps
	cp package-c.py build/package-c/opt/package-c/env/lib/python2.7/site-packages

# Create the Debian package
package: build
	dpkg --build build/package-c build

clean:
	rm -rf build
