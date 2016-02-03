#!/usr/bin/env python
import requests
import sys

def main():
    print("Hello from package-c!")
    print 'Argument List:', str(sys.argv)
    r = requests.get("http://www.google.com")
    if (r.status_code == requests.codes.ok):
        print("Successful response from http://www.google.com")
    else:
        print("Unsucessful response from http://www.google.com")
    print(r)

if __name__ == "__main__":
    main()

